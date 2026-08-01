/// Mock implementation of [HotkeyService] for testing.
/// Provides controlled hotkey behavior without platform dependencies.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ga_song/core/services/hotkey_service.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';

class MockHotkeyService implements HotkeyService {
  @override
  final SettingsManager settingsManager;
  @override
  final AudioEngineService? audioEngineService;
  @override
  final PlaylistService? playlistService;

  bool _initialized = false;
  bool _disposed = false;

  // Track calls for verification
  int initCallCount = 0;
  int registerGlobalHotkeysCallCount = 0;
  int handleActionCallCount = 0;
  int disposeCallCount = 0;

  // State
  Map<String, String> _registeredHotkeys = {};
  Map<String, int> _actionCallCounts = {};

  MockHotkeyService({
    required this.settingsManager,
    this.audioEngineService,
    this.playlistService,
  });

  @override
  Future<void> init() async {
    initCallCount++;
    _initialized = true;
    await _registerGlobalHotkeys();
  }

  @override
  void _onHotkeysSettingsChanged() {
    if (!_disposed) {
      _registerGlobalHotkeys();
    }
  }

  @override
  Future<void> _registerGlobalHotkeys() async {
    registerGlobalHotkeysCallCount++;
    _registeredHotkeys = Map.from(settingsManager.customHotkeysNotifier.value);
  }

  @override
  void _handleAction(String action) {
    handleActionCallCount++;
    _actionCallCounts[action] = (_actionCallCounts[action] ?? 0) + 1;
  }

  @override
  void dispose() {
    disposeCallCount++;
    _disposed = true;
    _initialized = false;
    _registeredHotkeys.clear();
  }

  // Helper for tests
  int getActionCallCount(String action) => _actionCallCounts[action] ?? 0;
  bool isHotkeyRegistered(String action) => _registeredHotkeys.containsKey(action);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}