import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/ui/widgets/main_content.dart';
import 'package:ga_song/ui/widgets/main_content_states.dart';
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

  Future<void> pumpMainContent(
    WidgetTester tester, {
    bool isLoading = false,
    String? loadingError,
    List<Song> songs = const [],
    VoidCallback? onRefresh,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioEngineServiceProvider.overrideWithValue(mockEngine),
          audioEffectServiceProvider.overrideWithValue(mockEffect),
          playlistServiceProvider.overrideWithValue(playlistService),
          settingsManagerProvider.overrideWithValue(settings),
          coverArtRepositoryProvider.overrideWithValue(coverRepo),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: Scaffold(
            body: MainContentWidget(
              isLoading: isLoading,
              loadingError: loadingError,
              songs: songs,
              filteredSongs: songs,
              songIndexByFileName: const {},
              searchQuery: '',
              onSearchChanged: (_) {},
              onRefresh: onRefresh ?? () {},
              showTitleBar: false,
            ),
          ),
        ),
      ),
    );
  }

  group('MainContentWidget', () {
    testWidgets('shows a progress indicator while loading', (tester) async {
      await pumpMainContent(tester, isLoading: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry that calls onRefresh', (
      tester,
    ) async {
      var refreshCount = 0;
      await pumpMainContent(
        tester,
        loadingError: 'Không thể nạp danh sách bài hát từ Database.',
        onRefresh: () => refreshCount++,
      );

      expect(find.byType(ErrorLoadingState), findsOneWidget);
      expect(
        find.text('Không thể nạp danh sách bài hát từ Database.'),
        findsOneWidget,
      );

      // The retry label comes from l10n (vi fallback in tests).
      await tester.tap(find.text('Thử tải lại'));
      await tester.pump();
      expect(refreshCount, 1);
    });

    testWidgets('shows empty state when there are no songs', (tester) async {
      await pumpMainContent(tester);
      expect(find.byType(EmptyLibraryState), findsOneWidget);
    });

    testWidgets('renders song list when songs are provided', (tester) async {
      await pumpMainContent(tester, songs: createTestSongList(2));
      await tester.pump();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
    });
  });
}
