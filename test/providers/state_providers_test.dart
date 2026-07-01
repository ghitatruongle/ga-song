import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/providers/state_providers.dart';

import '../mocks/mock_audio_effect_service.dart';
import '../mocks/mock_audio_engine_service.dart';
import '../mocks/mock_database_service.dart';

void main() {
  group('state_providers', () {
    late ProviderContainer container;
    late MockAudioEngineService engine;
    late PlaylistService playlist;

    setUp(() {
      engine = MockAudioEngineService();
      final effect = MockAudioEffectService();
      final db = MockDatabaseService();
      playlist = PlaylistService(engine, effect, db);
      container = ProviderContainer(
        overrides: [
          audioEngineServiceProvider.overrideWithValue(engine),
          playlistServiceProvider.overrideWithValue(playlist),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      playlist.dispose();
      engine.dispose();
    });

    test('engineStateProvider mirrors engine.engineState.value', () {
      expect(container.read(engineStateProvider), AudioEngineState.idle);
      engine.engineState.value = AudioEngineState.playing;
      expect(container.read(engineStateProvider), AudioEngineState.playing);
    });

    test('positionProvider follows positionNotifier', () {
      expect(container.read(positionProvider), Duration.zero);
      engine.positionNotifier.value = const Duration(seconds: 5);
      expect(container.read(positionProvider), const Duration(seconds: 5));
    });

    test('volumeProvider follows volumeNotifier', () {
      expect(container.read(volumeProvider), 1.0);
      engine.volumeNotifier.value = 0.42;
      expect(container.read(volumeProvider), closeTo(0.42, 1e-9));
    });

    test('currentPlayingIndexProvider follows playlist.currentIndexNotifier',
        () {
      expect(container.read(currentPlayingIndexProvider), -1);
      playlist.currentIndexNotifier.value = 3;
      expect(container.read(currentPlayingIndexProvider), 3);
    });

    test('playModeProvider follows playlist.playModeNotifier', () {
      expect(container.read(playModeProvider), PlayMode.sequential);
      playlist.playModeNotifier.value = PlayMode.shuffle;
      expect(container.read(playModeProvider), PlayMode.shuffle);
    });

    test('sleepTimerProvider follows playlist.sleepTimerRemainingNotifier',
        () {
      expect(container.read(sleepTimerProvider), isNull);
      playlist.sleepTimerRemainingNotifier.value =
          const Duration(minutes: 5);
      expect(container.read(sleepTimerProvider), const Duration(minutes: 5));
    });
  });
}
