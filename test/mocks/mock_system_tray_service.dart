/// Mock implementation of [SystemTrayService] for testing.
/// Provides controlled system tray behavior without platform dependencies.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ga_song/core/services/system_tray_service.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';

class MockSystemTrayService implements SystemTrayService {
  @override
  final AudioEngineService? audioEngineService;
  @override
  final PlaylistService? playlistService;

  bool initialized = false;
  bool disposed = false;

  // Track calls for verification
  int initCallCount = 0;
  int buildMenuCallCount = 0;
  int updateMenuCallCount = 0;
  int disposeCallCount = 0;

  // State
  bool menuVisible = false;
  Map<String, dynamic>? lastMenuData;

  MockSystemTrayService({
    this.audioEngineService,
    this.playlistService,
  });

  @override
  Future<void> init() async {
    initCallCount++;
    initialized = true;
  }

  Future<void> buildMenu() async {
    buildMenuCallCount++;
    menuVisible = true;
    lastMenuData = {
      'isPlaying': audioEngineService?.engineState.value == AudioEngineState.playing,
      'position': audioEngineService?.positionNotifier.value,
      'duration': audioEngineService?.durationNotifier.value,
    };
  }

  void updateMenu() {
    updateMenuCallCount++;
    if (initialized) {
      lastMenuData = {
        'isPlaying': audioEngineService?.engineState.value == AudioEngineState.playing,
        'position': audioEngineService?.positionNotifier.value,
        'duration': audioEngineService?.durationNotifier.value,
      };
    }
  }

  @override
  void dispose() {
    disposeCallCount++;
    disposed = true;
    initialized = false;
    menuVisible = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}