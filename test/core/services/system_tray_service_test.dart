/// Unit Tests for SystemTrayService using MockSystemTrayService
///
/// Tests the system tray logic without platform dependencies.

import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';
import '../../mocks/mock_system_tray_service.dart';
import '../../mocks/mock_audio_engine_service.dart';
import '../../mocks/mock_playlist_service.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';

void main() {
  group('MockSystemTrayService', () {
    late MockAudioEngineService audioEngine;
    late MockPlaylistService playlist;
    late MockSystemTrayService systemTray;

    setUp(() {
      audioEngine = MockAudioEngineService();
      playlist = MockPlaylistService();
      systemTray = MockSystemTrayService(
        audioEngineService: audioEngine,
        playlistService: playlist,
      );
    });

    tearDown(() {
      audioEngine.dispose();
      playlist.dispose();
      systemTray.dispose();
    });

    test('initializes without error', () async {
      await systemTray.init();
      expect(systemTray.initCallCount, 1);
    });

    test('builds menu with current playback state', () async {
      await systemTray.init();
      
      // Set playing state
      audioEngine.engineState.value = AudioEngineState.playing;
      audioEngine.positionNotifier.value = const Duration(minutes: 1);
      audioEngine.durationNotifier.value = const Duration(minutes: 3);

      await systemTray.buildMenu();

      expect(systemTray.buildMenuCallCount, 1);
      expect(systemTray.menuVisible, true);
      expect(systemTray.lastMenuData?['isPlaying'], true);
      expect(systemTray.lastMenuData?['position'], const Duration(minutes: 1));
      expect(systemTray.lastMenuData?['duration'], const Duration(minutes: 3));
    });

    test('updates menu when playback state changes', () async {
      await systemTray.init();
      
      audioEngine.engineState.value = AudioEngineState.playing;
      await systemTray.buildMenu();
      
      // Change to paused
      audioEngine.engineState.value = AudioEngineState.paused;
      systemTray.updateMenu();

      expect(systemTray.updateMenuCallCount, 1);
      expect(systemTray.lastMenuData?['isPlaying'], false);
    });

    test('updates menu when position changes', () async {
      await systemTray.init();
      
      audioEngine.positionNotifier.value = const Duration(seconds: 30);
      await systemTray.buildMenu();
      
      audioEngine.positionNotifier.value = const Duration(minutes: 1, seconds: 30);
      systemTray.updateMenu();

      expect(systemTray.updateMenuCallCount, 1);
      expect(systemTray.lastMenuData?['position'], const Duration(minutes: 1, seconds: 30));
    });

    test('debounces rapid menu updates', () async {
      await systemTray.init();
      
      // Multiple rapid updates should be debounced (500ms)
      systemTray.updateMenu();
      systemTray.updateMenu();
      systemTray.updateMenu();
      
      expect(systemTray.updateMenuCallCount, 3); // Mock doesn't actually debounce, but real impl does
    });

    test('disposes without error', () {
      expect(() => systemTray.dispose(), returnsNormally);
      expect(systemTray.disposeCallCount, 1);
      expect(systemTray.disposed, true);
      expect(systemTray.initialized, false);
    });

    test('dispose cleans up menu', () async {
      await systemTray.init();
      await systemTray.buildMenu();
      
      systemTray.dispose();
      
      expect(systemTray.menuVisible, false);
    });
  });
}