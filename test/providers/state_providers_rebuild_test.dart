import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/providers/service_providers.dart';


import '../mocks/mock_audio_effect_service.dart';
import '../mocks/mock_audio_engine_service.dart';
import '../mocks/mock_database_service.dart';

void main() {
  group('state_providers — re-build safety (Bug 1 verification)', () {
    test('engineStateProvider survives engine service replacement (re-build)',
        () {
      // Initial engine + container
      final engine1 = MockAudioEngineService();
      final container = ProviderContainer(
        overrides: [
          audioEngineServiceProvider.overrideWithValue(engine1),
          playlistServiceProvider.overrideWithValue(PlaylistService(
            engine1,
            MockAudioEffectService(),
            MockDatabaseServiceWrapper(),
          )),
        ],
      );
      expect(container.read(engineStateProvider), AudioEngineState.idle);

      // Read to force build
      container.listen(engineStateProvider, (_, __) {}, fireImmediately: true);

      // Bug verification: replace the engine and invalidate the provider.
      // If `late final` was used, this would throw LateInitializationError.
      // After fix to `late`, the new instance is captured cleanly.
      final engine2 = MockAudioEngineService();
      engine2.engineState.value = AudioEngineState.playing;
      container.updateOverrides([
        audioEngineServiceProvider.overrideWithValue(engine2),
        playlistServiceProvider.overrideWithValue(PlaylistService(
          engine2,
          MockAudioEffectService(),
          MockDatabaseServiceWrapper(),
        )),
      ]);
      container.invalidate(audioEngineServiceProvider);
      container.invalidate(playlistServiceProvider);

      // Force rebuild and read the new state
      final state = container.read(engineStateProvider);
      expect(state, AudioEngineState.playing,
          reason: 'New engine state should propagate after invalidate');

      container.dispose();
    });

    test('positionProvider preserves listener behavior across re-builds',
        () {
      final engine = MockAudioEngineService();
      final container = ProviderContainer(
        overrides: [
          audioEngineServiceProvider.overrideWithValue(engine),
          playlistServiceProvider.overrideWithValue(PlaylistService(
            engine,
            MockAudioEffectService(),
            MockDatabaseServiceWrapper(),
          )),
        ],
      );

      // Read to force build
      container.read(positionProvider);

      // Force re-build
      container.invalidate(audioEngineServiceProvider);
      container.invalidate(playlistServiceProvider);

      // Subsequent reads should work without throwing
      final pos = container.read(positionProvider);
      expect(pos, Duration.zero);
      // Underlying notifier changes should still propagate
      engine.positionNotifier.value = const Duration(seconds: 3);
      expect(container.read(positionProvider), const Duration(seconds: 3));

      container.dispose();
    });
  });
}
