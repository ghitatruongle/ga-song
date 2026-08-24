import '../logging/app_logger.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../settings_manager.dart';
import '../platform_capabilities.dart';

class HotkeyService {
  HotkeyService({
    required final SettingsManager settingsManager,
    final AudioEngineService? audioEngineService,
    final PlaylistService? playlistService,
    final VoidCallback? onOpenSettingsSearch,
    final VoidCallback? onToggleMiniPlayer,
  }) : _settings = settingsManager,
       _engine = audioEngineService,
       _playlist = playlistService,
       _onOpenSettingsSearch = onOpenSettingsSearch,
       _onToggleMiniPlayer = onToggleMiniPlayer;

  final SettingsManager _settings;
  final AudioEngineService? _engine;
  final PlaylistService? _playlist;
  final VoidCallback? _onOpenSettingsSearch;
  final VoidCallback? _onToggleMiniPlayer;

  final Map<String, String> _defaultHotkeys = {
    'playPause': 'Alt + Space',
    'next': 'Alt + Arrow Right',
    'previous': 'Alt + Arrow Left',
    'volumeUp': 'Alt + Arrow Up',
    'volumeDown': 'Alt + Arrow Down',
    // Seek uses Ctrl modifier to avoid conflict with next/previous
    'seekForward': 'Control + Arrow Right',
    'seekBackward': 'Control + Arrow Left',
    // Settings search
    'settingsSearch': 'Control + KeyK',
    // macOS Pinned Mini Player
    'toggleMiniPlayer': 'Meta + Shift + KeyM',
    // Media keys (native)
    'mediaPlayPause': 'MediaPlayPause',
    'mediaNext': 'MediaTrackNext',
    'mediaPrevious': 'MediaTrackPrevious',
    'mediaStop': 'MediaStop',
  };

  bool _isDisposed = false;
  Completer<void>? _registrationLock;
  final _registerCompleters = <Completer<void>>[];
  DateTime _lastActionTime = DateTime(2000);

  // Double-tap detection cho play/pause
  DateTime _lastSpacePressTime = DateTime(2000);
  static const _doubleTapThreshold = Duration(milliseconds: 300);

  // ─── Media key tracking ─────────────────────────────────────────────────

  DateTime _lastMediaKeyTime = DateTime(2000);
  static const _mediaKeyDebounce = Duration(milliseconds: 150);

  // ─── Conflict detection ─────────────────────────────────────────────────

  final Map<String, HotKey> _registeredHotkeys = {};
  final Set<String> _conflictingHotkeys = {};

  // ─── Hotkey profiles ────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _hotkeyProfiles = {
    'default': {
      'playPause': 'Alt + Space',
      'next': 'Alt + Arrow Right',
      'previous': 'Alt + Arrow Left',
      'volumeUp': 'Alt + Arrow Up',
      'volumeDown': 'Alt + Arrow Down',
      'seekForward': 'Control + Arrow Right',
      'seekBackward': 'Control + Arrow Left',
      'mediaPlayPause': 'MediaPlayPause',
      'mediaNext': 'MediaTrackNext',
      'mediaPrevious': 'MediaTrackPrevious',
      'mediaStop': 'MediaStop',
    },
    'gaming': {
      'playPause': 'Ctrl + Alt + Space',
      'next': 'Ctrl + Alt + Right',
      'previous': 'Ctrl + Alt + Left',
      'volumeUp': 'Ctrl + Alt + Up',
      'volumeDown': 'Ctrl + Alt + Down',
      'seekForward': 'Ctrl + Alt + Shift + Right',
      'seekBackward': 'Ctrl + Alt + Shift + Left',
    },
    'presentation': {
      'playPause': 'F8',
      'next': 'F9',
      'previous': 'F7',
      'volumeUp': 'F11',
      'volumeDown': 'F10',
      'seekForward': 'F6',
      'seekBackward': 'F5',
    },
  };

  // ─── Native Windows media keys ──────────────────────────────────────────

  static const MethodChannel _mediaKeyChannel = MethodChannel(
    'ga_song/media_keys',
  );
  bool _nativeMediaKeysRegistered = false;

  Future<void> init() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    HardwareKeyboard.instance.addHandler(_handleLocalKey);
    await _registerGlobalHotkeys();

    // Register native Windows media keys
    if (PlatformCapabilities.instance.isWindows) {
      await _registerNativeMediaKeys();
    }

    _settings.customHotkeysNotifier.addListener(_onHotkeysSettingsChanged);
    _settings.mediaKeyEnabledNotifier.addListener(_onMediaKeySettingChanged);
  }

  void _onHotkeysSettingsChanged() {
    if (!_isDisposed) {
      // v0.9.5: Only re-register changed hotkeys instead of unregistering all.
      // This preserves registrations for unchanged keys and reduces latency.
      _registerChangedHotkeys();
    }
  }

  /// v0.9.5: Re-register only the hotkeys whose bindings have changed,
  /// leaving all others registered. This avoids the O(n) unregister-all
  /// + re-register cycle on every settings change.
  Future<void> _registerChangedHotkeys() async {
    if (_registrationLock != null && !_registrationLock!.isCompleted) {
      await _registrationLock!.future;
    }
    _registrationLock = Completer<void>();

    Completer<void>? currentCompleter;
    _registerCompleters.add(currentCompleter = Completer<void>());

    try {
      final customHotkeys = _settings.customHotkeysNotifier.value;

      for (final entry in _defaultHotkeys.entries) {
        final action = entry.key;
        final newKeyString = customHotkeys[action] ?? entry.value;
        final newHotkey = _parseHotkeyString(newKeyString);

        final existing = _registeredHotkeys[action];
        final existingString = existing?.toString();

        // Only re-register if the key actually changed
        if (existingString == newHotkey?.toString()) continue;

        // Unregister old
        if (existing != null) {
          try {
            await hotKeyManager.unregister(existing);
          } catch (e) {
            // Ignore
          }
          _registeredHotkeys.remove(action);
        }

        // Register new
        if (newHotkey != null) {
          try {
            await hotKeyManager.register(
              newHotkey,
              keyDownHandler: (_) => _handleAction(action),
            );
            _registeredHotkeys[action] = newHotkey;
          } catch (e) {
            AppLogger.w(
              'hotkey.service',
              'register failed for $action',
              error: e,
            );
          }
        }
      }

      // Clear previous conflicts before re-detecting — otherwise stale
      // conflict entries from the initial full registration pollute results.
      _conflictingHotkeys.clear();
      detectConflicts();
      if (_conflictingHotkeys.isNotEmpty) {
        AppLogger.w(
          'hotkey.service',
          'Hotkey conflicts detected: $_conflictingHotkeys',
        );
      }
    } catch (error) {
      AppLogger.w(
        'hotkey.service',
        'changed hotkey registration failed',
        error: error,
      );
    } finally {
      _registerCompleters.remove(currentCompleter);
      currentCompleter.complete();
      if (!_registrationLock!.isCompleted) {
        _registrationLock!.complete();
      }
      _registrationLock = null;
    }
  }

  void _onMediaKeySettingChanged() {
    if (!_isDisposed && PlatformCapabilities.instance.isWindows) {
      _registerNativeMediaKeys();
    }
  }

  /// Registers native Windows media keys via platform channel.
  /// Uses VK_MEDIA_PLAY_PAUSE, VK_MEDIA_NEXT_TRACK, etc.
  Future<void> _registerNativeMediaKeys() async {
    final mediaKeyEnabled = _settings.mediaKeyEnabledNotifier.value;
    if (!mediaKeyEnabled) {
      await _unregisterNativeMediaKeys();
      return;
    }

    try {
      // Check if already registered
      if (_nativeMediaKeysRegistered) return;

      // Register native media key handler via platform channel
      await _mediaKeyChannel.invokeMethod('registerMediaKeys');

      // Listen for media key events
      _mediaKeyChannel.setMethodCallHandler(_handleNativeMediaKey);

      _nativeMediaKeysRegistered = true;
      AppLogger.d('hotkey.service', 'Native media keys registered');
    } catch (e) {
      AppLogger.w(
        'hotkey.service',
        'Native media key registration failed',
        error: e,
      );
    }
  }

  /// Unregisters native media keys.
  Future<void> _unregisterNativeMediaKeys() async {
    try {
      if (!_nativeMediaKeysRegistered) return;

      await _mediaKeyChannel.invokeMethod('unregisterMediaKeys');
      _mediaKeyChannel.setMethodCallHandler(null);
      _nativeMediaKeysRegistered = false;
      AppLogger.d('hotkey.service', 'Native media keys unregistered');
    } catch (e) {
      AppLogger.w(
        'hotkey.service',
        'Native media key unregistration failed',
        error: e,
      );
    }
  }

  /// Handles native media key events from platform channel.
  Future<dynamic> _handleNativeMediaKey(final MethodCall call) async {
    switch (call.method) {
      case 'onMediaKey':
        final key = call.arguments as String;

        // Debounce media keys to prevent rapid-fire
        final now = DateTime.now();
        if (now.difference(_lastMediaKeyTime).inMilliseconds <
            _mediaKeyDebounce.inMilliseconds) {
          return null;
        }
        _lastMediaKeyTime = now;

        switch (key) {
          case 'playPause':
            _handleAction('playPause');
            break;
          case 'next':
            _handleAction('next');
            break;
          case 'previous':
            _handleAction('previous');
            break;
          case 'stop':
            _handleAction('stop');
            break;
        }
        break;
    }
    return null;
  }

  /// Applies a hotkey profile by name.
  Future<void> applyHotkeyProfile(final String profileName) async {
    final profile = _hotkeyProfiles[profileName];
    if (profile == null) {
      AppLogger.w('hotkey.service', 'Unknown profile: $profileName');
      return;
    }

    // Update settings with profile hotkeys
    _settings.customHotkeysNotifier.value = Map.from(profile);
    await _registerGlobalHotkeys();

    AppLogger.i('hotkey.service', 'Applied hotkey profile: $profileName');
  }

  /// Gets available hotkey profile names.
  List<String> get availableProfiles => _hotkeyProfiles.keys.toList();

  /// Gets the hotkey mapping for a profile.
  Map<String, String>? getProfile(final String name) => _hotkeyProfiles[name];

  /// Detects and resolves hotkey conflicts.
  /// Returns list of conflicting actions.
  List<String> detectConflicts() {
    _conflictingHotkeys.clear();

    final seen = <String, String>{}; // keyString -> action

    for (final entry in _registeredHotkeys.entries) {
      final action = entry.key;
      final hotkey = entry.value;
      final keyString = hotkey
          .toString(); // HotKey.toString() gives unique representation

      if (seen.containsKey(keyString)) {
        _conflictingHotkeys.add(action);
        _conflictingHotkeys.add(seen[keyString]!);
      } else {
        seen[keyString] = action;
      }
    }

    return _conflictingHotkeys.toList();
  }

  /// Auto-resolves conflicts by modifying conflicting hotkeys.
  Future<void> autoResolveConflicts() async {
    final conflicts = detectConflicts();
    if (conflicts.isEmpty) return;

    final customHotkeys = Map<String, String>.from(
      _settings.customHotkeysNotifier.value,
    );

    for (final action in conflicts) {
      // Try to find an alternative key combination
      final alternative = _findAlternativeHotkey(action);
      if (alternative != null) {
        customHotkeys[action] = alternative;
        AppLogger.i(
          'hotkey.service',
          'Auto-resolved conflict for $action -> $alternative',
        );
      }
    }

    _settings.customHotkeysNotifier.value = customHotkeys;
    await _registerGlobalHotkeys();
  }

  /// Finds an alternative hotkey for an action.
  String? _findAlternativeHotkey(final String action) {
    final modifiers = [
      [HotKeyModifier.control],
      [HotKeyModifier.alt],
      [HotKeyModifier.shift],
      [HotKeyModifier.control, HotKeyModifier.alt],
      [HotKeyModifier.control, HotKeyModifier.shift],
      [HotKeyModifier.alt, HotKeyModifier.shift],
    ];

    final keys = [
      PhysicalKeyboardKey.keyM,
      PhysicalKeyboardKey.keyN,
      PhysicalKeyboardKey.keyP,
      PhysicalKeyboardKey.keyB,
      PhysicalKeyboardKey.keyV,
      PhysicalKeyboardKey.keyX,
      PhysicalKeyboardKey.keyZ,
      PhysicalKeyboardKey.f1,
      PhysicalKeyboardKey.f2,
      PhysicalKeyboardKey.f3,
      PhysicalKeyboardKey.f4,
    ];

    final existing = _registeredHotkeys.values
        .map((final h) => h.toString())
        .toSet();

    for (final key in keys) {
      for (final modList in modifiers) {
        final hotkey = HotKey(key: key, modifiers: modList);
        if (!existing.contains(hotkey.toString())) {
          return _hotkeyToString(hotkey);
        }
      }
    }

    return null;
  }

  /// Converts HotKey to string representation.
  String _hotkeyToString(final HotKey hotkey) {
    final parts = <String>[];
    if (hotkey.modifiers != null) {
      for (final mod in hotkey.modifiers!) {
        switch (mod) {
          case HotKeyModifier.control:
            parts.add('Ctrl');
            break;
          case HotKeyModifier.alt:
            parts.add('Alt');
            break;
          case HotKeyModifier.shift:
            parts.add('Shift');
            break;
          case HotKeyModifier.meta:
            parts.add('Win');
            break;
          case HotKeyModifier.capsLock:
            parts.add('CapsLock');
            break;
          case HotKeyModifier.fn:
            parts.add('Fn');
            break;
        }
      }
    }
    parts.add(_keyToString(hotkey.key));
    return parts.join(' + ');
  }

  String _keyToString(final KeyboardKey key) {
    if (key == PhysicalKeyboardKey.space) return 'Space';
    if (key == PhysicalKeyboardKey.arrowRight) return 'ArrowRight';
    if (key == PhysicalKeyboardKey.arrowLeft) return 'ArrowLeft';
    if (key == PhysicalKeyboardKey.arrowUp) return 'ArrowUp';
    if (key == PhysicalKeyboardKey.arrowDown) return 'ArrowDown';
    if (key == PhysicalKeyboardKey.enter) return 'Enter';
    if (key == PhysicalKeyboardKey.escape) return 'Escape';
    if (key == PhysicalKeyboardKey.pageUp) return 'PageUp';
    if (key == PhysicalKeyboardKey.pageDown) return 'PageDown';
    if (key == PhysicalKeyboardKey.home) return 'Home';
    if (key == PhysicalKeyboardKey.end) return 'End';

    // F keys
    if (key == PhysicalKeyboardKey.f1) return 'F1';
    if (key == PhysicalKeyboardKey.f2) return 'F2';
    if (key == PhysicalKeyboardKey.f3) return 'F3';
    if (key == PhysicalKeyboardKey.f4) return 'F4';
    if (key == PhysicalKeyboardKey.f5) return 'F5';
    if (key == PhysicalKeyboardKey.f6) return 'F6';
    if (key == PhysicalKeyboardKey.f7) return 'F7';
    if (key == PhysicalKeyboardKey.f8) return 'F8';
    if (key == PhysicalKeyboardKey.f9) return 'F9';
    if (key == PhysicalKeyboardKey.f10) return 'F10';
    if (key == PhysicalKeyboardKey.f11) return 'F11';
    if (key == PhysicalKeyboardKey.f12) return 'F12';

    // Letter keys (a-z)
    if (key == PhysicalKeyboardKey.keyA) return 'A';
    if (key == PhysicalKeyboardKey.keyB) return 'B';
    if (key == PhysicalKeyboardKey.keyC) return 'C';
    if (key == PhysicalKeyboardKey.keyD) return 'D';
    if (key == PhysicalKeyboardKey.keyE) return 'E';
    if (key == PhysicalKeyboardKey.keyF) return 'F';
    if (key == PhysicalKeyboardKey.keyG) return 'G';
    if (key == PhysicalKeyboardKey.keyH) return 'H';
    if (key == PhysicalKeyboardKey.keyI) return 'I';
    if (key == PhysicalKeyboardKey.keyJ) return 'J';
    if (key == PhysicalKeyboardKey.keyK) return 'K';
    if (key == PhysicalKeyboardKey.keyL) return 'L';
    if (key == PhysicalKeyboardKey.keyM) return 'M';
    if (key == PhysicalKeyboardKey.keyN) return 'N';
    if (key == PhysicalKeyboardKey.keyO) return 'O';
    if (key == PhysicalKeyboardKey.keyP) return 'P';
    if (key == PhysicalKeyboardKey.keyQ) return 'Q';
    if (key == PhysicalKeyboardKey.keyR) return 'R';
    if (key == PhysicalKeyboardKey.keyS) return 'S';
    if (key == PhysicalKeyboardKey.keyT) return 'T';
    if (key == PhysicalKeyboardKey.keyU) return 'U';
    if (key == PhysicalKeyboardKey.keyV) return 'V';
    if (key == PhysicalKeyboardKey.keyW) return 'W';
    if (key == PhysicalKeyboardKey.keyX) return 'X';
    if (key == PhysicalKeyboardKey.keyY) return 'Y';
    if (key == PhysicalKeyboardKey.keyZ) return 'Z';

    return key.toString();
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
    _settings.mediaKeyEnabledNotifier.removeListener(_onMediaKeySettingChanged);

    // Clean up native media keys
    _unregisterNativeMediaKeys();

    for (final completer in _registerCompleters) {
      if (!completer.isCompleted) completer.complete();
    }
    _registerCompleters.clear();
    if (_registrationLock != null && !_registrationLock!.isCompleted) {
      _registrationLock!.complete();
    }
    _registrationLock = null;
    hotKeyManager.unregisterAll();
    _registeredHotkeys.clear();
    _conflictingHotkeys.clear();
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
      _registeredHotkeys.clear();

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
          _registeredHotkeys[action] = hotkey;
        }
      }

      // Auto-detect conflicts after registration
      detectConflicts();
      if (_conflictingHotkeys.isNotEmpty) {
        AppLogger.w(
          'hotkey.service',
          'Hotkey conflicts detected: $_conflictingHotkeys',
        );
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

  void _handleAction(final String action) {
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
      // Media Stop: pause instead of full stop — a full stop clears the
      // queue and resets position, which is surprising for a media key.
      case 'stop':
        engineService.pause();
        break;
      // New: settings search
      case 'settingsSearch':
        _onOpenSettingsSearch?.call();
        break;
      // macOS Pinned Mini Player toggle (Cmd+Shift+M)
      case 'toggleMiniPlayer':
        _onToggleMiniPlayer?.call();
        break;
    }
  }

  HotKey? _parseHotkeyString(final String keys) {
    try {
      final parts = keys.split('+').map((final e) => e.trim()).toList();
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
          // keybinder on Linux supports system-wide hotkeys — no need to
          // fall back to inapp scope.  The earlier inapp fallback was a
          // conservative choice; keybinder works on both X11 and Wayland.
          scope: HotKeyScope.system,
        );
      }
    } catch (e, stack) {
      AppLogger.e('hotkey.service', 'operation failed', error: e, stack: stack);
    }
    return null;
  }

  PhysicalKeyboardKey? _mapStringToKey(final String keyLabel) {
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

  bool _handleLocalKey(final KeyEvent event) {
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
        } else if (event.logicalKey == LogicalKeyboardKey.mediaStop) {
          _handleAction('stop');
          return true;
        }
      }
    }
    return false;
  }
}
