import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/ui/widgets/bottom_player_bar.dart';
import 'package:ga_song/ui/widgets/player_bar/center_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_audio_effect_service.dart';
import '../../mocks/mock_audio_engine_service.dart';
import '../../mocks/mock_database_service.dart';
import '../../test_helpers.dart';

void main() {
  late MockAudioEngineService mockEngine;
  late MockAudioEffectService mockEffect;
  late PlaylistService playlistService;
  late SettingsManager settings;
  late CoverArtRepository coverRepo;

  setUp(() async {
    mockEngine = MockAudioEngineService();
    mockEffect = MockAudioEffectService();
    playlistService = PlaylistService(
      mockEngine,
      mockEffect,
      MockDatabaseServiceWrapper(),
    );
    SharedPreferences.setMockInitialValues({});
    settings = SettingsManager();
    await settings.init();
    coverRepo = CoverArtRepository();
  });

  tearDown(() {
    playlistService.dispose();
    coverRepo.dispose();
    settings.dispose();
  });

  /// Pumps the player bar at a narrow width so the compact layout is used
  /// (RightControls is desktop-only and pulls in platform services).
  Future<void> pumpPlayerBar(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineServiceProvider.overrideWithValue(mockEngine),
          audioEffectServiceProvider.overrideWithValue(mockEffect),
          playlistServiceProvider.overrideWithValue(playlistService),
          settingsManagerProvider.overrideWithValue(settings),
          coverArtRepositoryProvider.overrideWithValue(coverRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: BottomPlayerBarWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('BottomPlayerBarWidget', () {
    testWidgets('shows empty state when no song is selected', (tester) async {
      await pumpPlayerBar(tester);
      expect(find.text('Chưa chọn bài hát'), findsOneWidget);
      expect(find.byType(CenterControls), findsNothing);
    });

    testWidgets('shows song info and controls when a song is loaded', (
      tester,
    ) async {
      await playlistService.setPlaylist(createTestSongList(3));
      await pumpPlayerBar(tester);
      await tester.pump();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.byType(CenterControls), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('tapping play starts playback via the engine', (tester) async {
      await playlistService.setPlaylist(createTestSongList(3));
      await pumpPlayerBar(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();

      expect(mockEngine.playCallCount, 1);
      expect(mockEngine.engineState.value, AudioEngineState.playing);
      // Icon flips to pause once the engine reports playing.
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('tapping next advances the playlist', (tester) async {
      await playlistService.setPlaylist(createTestSongList(3));
      await pumpPlayerBar(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();

      expect(playlistService.currentIndex, 1);
      expect(find.text('Song 2'), findsOneWidget);
    });

    testWidgets('tapping previous goes back to the prior song', (
      tester,
    ) async {
      await playlistService.setPlaylist(createTestSongList(3));
      await playlistService.next();
      await pumpPlayerBar(tester);
      await tester.pump();
      expect(find.text('Song 2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.pump();

      expect(playlistService.currentIndex, 0);
      expect(find.text('Song 1'), findsOneWidget);
    });
  });
}
