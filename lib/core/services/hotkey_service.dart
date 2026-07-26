import '../logging/app_logger.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../settings_manager.dart';

class HotkeyService {
  HotkeyService({
    required SettingsManager settingsManager,
    AudioEngineService? audioEngineService,
    PlaylistService? playlistService,
  }) : _settings = settingsManager,
       _engine = audioEngineService,
       _playlist = playlistService;

  final SettingsManager _settings;
  final AudioEngineService? _engine;
  final PlaylistService? _playlist;
  final Map<String, String> _defaultHotkeys = {
    'playPause': 'Alt + Space',
    'next': 'Alt + Arrow Right',
    'previous': 'Alt + Arrow Left',
    'volumeUp': 'Alt + Arrow Up',
    'volumeDown': 'Alt + Arrow Down',
    // Thêm media keys chuẩn cho seek forward/backward (10s)
    'seekForward': 'Alt + Arrow Right',
    'seekBackward': 'Alt + Arrow Left',
  };

  bool _isDisposed = false;
  Completer<void>? _registrationLock;
  final _registerCompleters = <Completer<void>>[];
  DateTime _lastActionTime = DateTime(2000);

  // Double-tap detection cho play/pause
  DateTime _lastSpacePressTime = DateTime(2000);
  static const _doubleTapThreshold = Duration(milliseconds: 300);

  Future<void> init() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    HardwareKeyboard.instance.addHandler(_handleLocalKey);
    await _registerGlobalHotkeys();
    _settings.customHotkeysNotifier.addListener(_onHotkeysSettingsChanged);
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
    _settings.customHotkeysNotifier.removeListener(_onHotkeysSettingsChanged);
    for (final completer in _registerCompleters) {
      if (!completer.isCompleted) completer.complete();
    }
    _registerCompleters.clear();
    if (_registrationLock != null && !_registrationLock!.isCompleted) {
      _registrationLock!.complete();
    }
    _registrationLock = null;
    hotKeyManager.unregisterAll();
  }

  Future<void> _registerGlobalHotkeys() async {
    // Wait for any in-flight registration to complete
    if (_registrationLock != null && !_registrationLock!.isCompleted) {
      await _registrationLock!.future;
    }
    _registrationLock = Completer<void>();

    Completer<void>? currentCompleter;
    _registerCompleters.add(currentCompleter = Completer<void>());

    try {
      await hotKeyManager.unregisterAll();

      final customHotkeys = _settings.customHotkeysNotifier.value;

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
      AppLogger.w('hotkey.service', 'global hotkey failed', error: error);
    } finally {
      _registerCompleters.remove(currentCompleter);
      currentCompleter.complete();
      if (!_registrationLock!.isCompleted) {
        _registrationLock!.complete();
      }
      _registrationLock = null;
    }
  }

  void _handleAction(String action) {
    if (_isDisposed) return;

    // Debounce: tránh trigger liên tục khi giữ phím (tối thiểu 100ms giữa mỗi lần)
    final now = DateTime.now();
    if (now.difference(_lastActionTime).inMilliseconds < 100) return;
    _lastActionTime = now;

    final AudioEngineService? engineService = _engine;
    final PlaylistService? playlistService = _playlist;
    if (engineService == null || playlistService == null) return;

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
      // Seek forward/backward (10 seconds)
      case 'seekForward':
        final currentPosition = engineService.positionNotifier.value;
        final newPosition = currentPosition + const Duration(seconds: 10);
        engineService.seek(newPosition);
        break;
      case 'seekBackward':
        final currentPosition = engineService.positionNotifier.value;
        final newPosition = currentPosition - const Duration(seconds: 10);
        engineService.seek(
          newPosition < Duration.zero ? Duration.zero : newPosition,
        );
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
    } catch (e, stack) {
      AppLogger.e('hotkey.service', 'operation failed', error: e, stack: stack);
    }
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
      'Page Up': PhysicalKeyboardKey.pageUp,
      'PageUp': PhysicalKeyboardKey.pageUp,
      'Page Down': PhysicalKeyboardKey.pageDown,
      'PageDown': PhysicalKeyboardKey.pageDown,
      'Home': PhysicalKeyboardKey.home,
      'End': PhysicalKeyboardKey.end,
    };

    if (keyMap.containsKey(keyLabel)) return keyMap[keyLabel];

    final label = keyLabel.toLowerCase();
    if (label.length == 1) {
      final charCode = label.codeUnitAt(0);
      if (charCode >= 97 && charCode <= 122) {
        // a-z
        switch (label) {
          case 'a':
            return PhysicalKeyboardKey.keyA;
          case 'b':
            return PhysicalKeyboardKey.keyB;
          case 'c':
            return PhysicalKeyboardKey.keyC;
          case 'd':
            return PhysicalKeyboardKey.keyD;
          case 'e':
            return PhysicalKeyboardKey.keyE;
          case 'f':
            return PhysicalKeyboardKey.keyF;
          case 'g':
            return PhysicalKeyboardKey.keyG;
          case 'h':
            return PhysicalKeyboardKey.keyH;
          case 'i':
            return PhysicalKeyboardKey.keyI;
          case 'j':
            return PhysicalKeyboardKey.keyJ;
          case 'k':
            return PhysicalKeyboardKey.keyK;
          case 'l':
            return PhysicalKeyboardKey.keyL;
          case 'm':
            return PhysicalKeyboardKey.keyM;
          case 'n':
            return PhysicalKeyboardKey.keyN;
          case 'o':
            return PhysicalKeyboardKey.keyO;
          case 'p':
            return PhysicalKeyboardKey.keyP;
          case 'q':
            return PhysicalKeyboardKey.keyQ;
          case 'r':
            return PhysicalKeyboardKey.keyR;
          case 's':
            return PhysicalKeyboardKey.keyS;
          case 't':
            return PhysicalKeyboardKey.keyT;
          case 'u':
            return PhysicalKeyboardKey.keyU;
          case 'v':
            return PhysicalKeyboardKey.keyV;
          case 'w':
            return PhysicalKeyboardKey.keyW;
          case 'x':
            return PhysicalKeyboardKey.keyX;
          case 'y':
            return PhysicalKeyboardKey.keyY;
          case 'z':
            return PhysicalKeyboardKey.keyZ;
        }
      }
      if (charCode >= 48 && charCode <= 57) {
        // 0-9
        switch (label) {
          case '0':
            return PhysicalKeyboardKey.digit0;
          case '1':
            return PhysicalKeyboardKey.digit1;
          case '2':
            return PhysicalKeyboardKey.digit2;
          case '3':
            return PhysicalKeyboardKey.digit3;
          case '4':
            return PhysicalKeyboardKey.digit4;
          case '5':
            return PhysicalKeyboardKey.digit5;
          case '6':
            return PhysicalKeyboardKey.digit6;
          case '7':
            return PhysicalKeyboardKey.digit7;
          case '8':
            return PhysicalKeyboardKey.digit8;
          case '9':
            return PhysicalKeyboardKey.digit9;
        }
      }
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
        // Double-tap detection: double-tap space để play/pause nhanh
        final now = DateTime.now();
        if (now.difference(_lastSpacePressTime) < _doubleTapThreshold) {
          _lastSpacePressTime = DateTime(2000); // Reset
          _handleAction('playPause');
          return true;
        }
        _lastSpacePressTime = now;
        return false; // Single tap — không xử lý để tránh conflict với typing
      }
      // Media keys: chỉ xử lý khi setting mediaKeyEnabled bật
      final mediaKeyEnabled = _settings.mediaKeyEnabledNotifier.value;
      if (mediaKeyEnabled) {
        if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
          _handleAction('playPause');
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
          _handleAction('next');
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
          _handleAction('previous');
          return true;
        }
      }
    }
    return false;
  }
}
