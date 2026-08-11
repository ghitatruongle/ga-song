/// Mock implementation of [HotkeyService] for testing.
/// Provides controlled hotkey behavior without platform dependencies.
library;

import 'dart:async';
import 'package:ga_song/core/services/hotkey_service.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';

class MockHotkeyService implements HotkeyService {
  final SettingsManager settingsManager;
  final AudioEngineService? audioEngineService;
  final PlaylistService? playlistService;

  // Track calls for verification
  int initCallCount = 0;
  int registerGlobalHotkeysCallCount = 0;
  int handleActionCallCount = 0;
  int disposeCallCount = 0;

  // State
  Map<String, String> _registeredHotkeys = {};
  final Map<String, int> _actionCallCounts = {};

  MockHotkeyService({
    required this.settingsManager,
    this.audioEngineService,
    this.playlistService,
  });

  @override
  Future<void> init() async {
    initCallCount++;
    await _registerGlobalHotkeys();
  }

  Future<void> _registerGlobalHotkeys() async {
    registerGlobalHotkeysCallCount++;
    _registeredHotkeys = Map.from(settingsManager.customHotkeysNotifier.value);
  }

  @override
  void dispose() {
    disposeCallCount++;
    _registeredHotkeys.clear();
  }

  // Helper for tests
  int getActionCallCount(final String action) => _actionCallCounts[action] ?? 0;
  bool isHotkeyRegistered(final String action) =>
      _registeredHotkeys.containsKey(action);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
