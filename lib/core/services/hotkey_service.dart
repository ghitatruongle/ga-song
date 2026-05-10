import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../service_locator.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../settings_manager.dart';

class HotkeyService {
  final Map<String, String> _defaultHotkeys = {
    'playPause': 'Alt + Space',
    'next': 'Alt + Arrow Right',
    'previous': 'Alt + Arrow Left',
    'volumeUp': 'Alt + Arrow Up',
    'volumeDown': 'Alt + Arrow Down',
  };

  bool _isDisposed = false;
  bool _isRegistering = false;
  final _registerCompleters = <Completer<void>>[];

  Future<void> init() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    HardwareKeyboard.instance.addHandler(_handleLocalKey);
    await _registerGlobalHotkeys();
    sl<SettingsManager>().customHotkeysNotifier.addListener(
      _onHotkeysSettingsChanged,
    );
  }

  void _onHotkeysSettingsChanged() {
    if (!_isDisposed) {
      _registerGlobalHotkeys();
    }
  }

  void dispose() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    _isDisposed = true;
    HardwareKeyboard.instance.removeHandler(_handleLocalKey);
    sl<SettingsManager>().customHotkeysNotifier.removeListener(
      _onHotkeysSettingsChanged,
    );
    for (final completer in _registerCompleters) {
      completer.complete();
    }
    _registerCompleters.clear();
    hotKeyManager.unregisterAll();
  }

  Future<void> _registerGlobalHotkeys() async {
    if (_isRegistering) return;
    _isRegistering = true;

    Completer<void>? currentCompleter;
    _registerCompleters.add(currentCompleter = Completer<void>());

    try {
      await hotKeyManager.unregisterAll();

      final customHotkeys = sl<SettingsManager>().customHotkeysNotifier.value;

      for (final entry in _defaultHotkeys.entries) {
        final action = entry.key;
        final keyString = customHotkeys[action] ?? entry.value;
        final hotkey = _parseHotkeyString(keyString);

        if (hotkey != null) {
          await hotKeyManager.register(
            hotkey,
            keyDownHandler: (_) => _handleAction(action),
          );
        }
      }
    } catch (error) {
      debugPrint('Global HotKey error: $error');
    } finally {
      _isRegistering = false;
      _registerCompleters.remove(currentCompleter);
      currentCompleter.complete();
    }
  }

  void _handleAction(String action) {
    if (_isDisposed) return;

    AudioEngineService engineService;
    PlaylistService playlistService;
    try {
      engineService = sl<AudioEngineService>();
      playlistService = sl<PlaylistService>();
    } catch (_) {
      return;
    }

    switch (action) {
      case 'playPause':
        if (engineService.engineState.value == AudioEngineState.playing) {
          engineService.pause();
        } else {
          playlistService.play();
        }
        break;
      case 'next':
        playlistService.next();
        break;
      case 'previous':
        playlistService.previous();
        break;
      case 'volumeUp':
        final currentVol = engineService.volumeNotifier.value;
        engineService.setVolume((currentVol + 0.1).clamp(0.0, 1.0).toDouble());
        break;
      case 'volumeDown':
        final currentVol = engineService.volumeNotifier.value;
        engineService.setVolume((currentVol - 0.1).clamp(0.0, 1.0).toDouble());
        break;
    }
  }

  HotKey? _parseHotkeyString(String keys) {
    try {
      final parts = keys.split('+').map((e) => e.trim()).toList();
      if (parts.isEmpty) return null;

      final modifiers = <HotKeyModifier>[];
      PhysicalKeyboardKey? mainKey;

      for (final part in parts) {
        final lowerPart = part.toLowerCase();
        if (lowerPart == 'alt') {
          modifiers.add(HotKeyModifier.alt);
        } else if (lowerPart == 'ctrl' || lowerPart == 'control') {
          modifiers.add(HotKeyModifier.control);
        } else if (lowerPart == 'shift') {
          modifiers.add(HotKeyModifier.shift);
        } else if (lowerPart == 'meta' ||
            lowerPart == 'win' ||
            lowerPart == 'cmd') {
          modifiers.add(HotKeyModifier.meta);
        } else {
          // Attempt to map logical string back to physical key
          mainKey = _mapStringToKey(part);
        }
      }

      if (mainKey != null) {
        return HotKey(
          key: mainKey,
          modifiers: modifiers.isEmpty ? null : modifiers,
          scope: defaultTargetPlatform == TargetPlatform.linux
              ? HotKeyScope.inapp
              : HotKeyScope.system,
        );
      }
    } catch (_) {}
    return null;
  }

  PhysicalKeyboardKey? _mapStringToKey(String keyLabel) {
    final Map<String, PhysicalKeyboardKey> keyMap = {
      'Space': PhysicalKeyboardKey.space,
      'Arrow Right': PhysicalKeyboardKey.arrowRight,
      'ArrowRight': PhysicalKeyboardKey.arrowRight,
      'Arrow Left': PhysicalKeyboardKey.arrowLeft,
      'ArrowLeft': PhysicalKeyboardKey.arrowLeft,
      'Arrow Up': PhysicalKeyboardKey.arrowUp,
      'ArrowUp': PhysicalKeyboardKey.arrowUp,
      'Arrow Down': PhysicalKeyboardKey.arrowDown,
      'ArrowDown': PhysicalKeyboardKey.arrowDown,
      'Enter': PhysicalKeyboardKey.enter,
      'Escape': PhysicalKeyboardKey.escape,
    };

    if (keyMap.containsKey(keyLabel)) return keyMap[keyLabel];

    // For single letters (A-Z) and numbers (0-9)
    if (keyLabel.length == 1) {
      // Simplification: We only support the explicitly mapped keys above for now.
      return null;
    }
    return null;
  }

  bool _handleLocalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (FocusManager.instance.primaryFocus?.context?.widget
            is EditableText) {
          return false;
        }
        _handleAction('playPause');
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
        _handleAction('playPause');
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
        sl<PlaylistService>().next();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
        sl<PlaylistService>().previous();
        return true;
      }
    }
    return false;
  }
}
