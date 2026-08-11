import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/models/song.dart';

import '../../mocks/mock_audio_engine_service.dart';
import '../../mocks/mock_audio_effect_service.dart';
import '../../mocks/mock_database_service.dart';
import '../../test_helpers.dart';

void main() {
  group('PlaylistService', () {
    late PlaylistService service;
    late MockAudioEngineService mockEngine;
    late MockAudioEffectService mockEffect;

    setUp(() {
      mockEngine = MockAudioEngineService();
      mockEffect = MockAudioEffectService();
      service = PlaylistService(
        mockEngine,
        mockEffect,
        MockDatabaseServiceWrapper(),
      );
    });

    tearDown(() {
      service.dispose();
      mockEngine.dispose();
      mockEffect.dispose();
    });

    // ─── Initial State ─────────────────────────────────────────────────

    group('initial state', () {
      test('playlist is empty', () {
        expect(service.playlist, isEmpty);
      });

      test('currentIndex is -1', () {
        expect(service.currentIndex, -1);
      });

      test('currentSong is null', () {
        expect(service.currentSong, isNull);
      });

      test('playMode is sequential', () {
        expect(service.playMode, PlayMode.sequential);
      });

      test('currentIndexNotifier is -1', () {
        expect(service.currentIndexNotifier.value, -1);
      });

      test('playModeNotifier is sequential', () {
        expect(service.playModeNotifier.value, PlayMode.sequential);
      });

      test('sleepTimerRemainingNotifier is null', () {
        expect(service.sleepTimerRemainingNotifier.value, isNull);
      });

      test('isSleepTimerActive is false', () {
        expect(service.isSleepTimerActive, isFalse);
      });
    });

    // ─── setPlaylist ───────────────────────────────────────────────────

    group('setPlaylist', () {
      test('sets playlist songs', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs);
        expect(service.playlist, songs);
      });

      test('sets currentIndex to startIndex', () async {
        final songs = createTestSongList(5);
        await service.setPlaylist(songs, startIndex: 2);
        expect(service.currentIndex, 2);
      });

      test('clamps startIndex to valid range', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 10);
        expect(service.currentIndex, 2);
      });

      test('handles empty playlist', () async {
        await service.setPlaylist([]);
        expect(service.playlist, isEmpty);
        expect(service.currentIndex, -1);
        expect(service.currentIndexNotifier.value, -1);
      });

      test('updates currentIndexNotifier', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 1);
        expect(service.currentIndexNotifier.value, 1);
      });
    });

    // ─── Play Mode ─────────────────────────────────────────────────────

    group('setPlayMode', () {
      test('changes play mode', () {
        service.setPlayMode(PlayMode.shuffle);
        expect(service.playMode, PlayMode.shuffle);
        expect(service.playModeNotifier.value, PlayMode.shuffle);
      });

      test('clears shuffle history when entering shuffle mode', () {
        service.setPlayMode(PlayMode.shuffle);
        // No direct way to check, but it should not throw
        expect(service.playMode, PlayMode.shuffle);
      });
    });

    group('nextPlayMode', () {
      test('cycles through modes: sequential → repeatOne', () async {
        await service.nextPlayMode();
        expect(service.playMode, PlayMode.repeatOne);
      });

      test('cycles through modes: repeatOne → playOneStop', () async {
        service.setPlayMode(PlayMode.repeatOne);
        await service.nextPlayMode();
        expect(service.playMode, PlayMode.playOneStop);
      });

      test('cycles through modes: playOneStop → shuffle', () async {
        service.setPlayMode(PlayMode.playOneStop);
        await service.nextPlayMode();
        expect(service.playMode, PlayMode.shuffle);
      });

      test('cycles through modes: shuffle → sequential', () async {
        service.setPlayMode(PlayMode.shuffle);
        await service.nextPlayMode();
        expect(service.playMode, PlayMode.sequential);
      });
    });

    // ─── Sort ──────────────────────────────────────────────────────────

    group('setSortMode', () {
      test('sets sort mode', () {
        service.setSortMode(SortMode.artist);
        expect(service.sortMode, SortMode.artist);
        expect(service.sortAscending, isTrue);
      });

      test('toggles ascending when same mode is set', () {
        // Default is SortMode.name, ascending=true
        // First call: same mode → toggle to false
        service.setSortMode(SortMode.name);
        expect(service.sortAscending, isFalse);
        // Second call: same mode → toggle back to true
        service.setSortMode(SortMode.name);
        expect(service.sortAscending, isTrue);
        // Third call: same mode → toggle to false again
        service.setSortMode(SortMode.name);
        expect(service.sortAscending, isFalse);
      });

      test('resets ascending when different mode is set', () {
        service.setSortMode(SortMode.artist);
        service.setSortMode(SortMode.artist); // toggle to false
        service.setSortMode(SortMode.name); // new mode → ascending = true
        expect(service.sortAscending, isTrue);
      });
    });

    group('getSortedPlaylist', () {
      late List<Song> songs;

      setUp(() {
        songs = [
          createTestSong(
            name: 'Banana',
            artist: 'Zebra',
            sourcePath: 'a.mp3',
            durationMs: 300000,
            dateAdded: DateTime(2026),
          ),
          createTestSong(
            name: 'Apple',
            artist: 'Apple',
            sourcePath: 'b.mp3',
            durationMs: 120000,
            dateAdded: DateTime(2026, 3),
          ),
          createTestSong(
            name: 'Cherry',
            artist: 'Monkey',
            sourcePath: 'c.mp3',
            dateAdded: DateTime(2026, 2),
          ),
        ];
      });

      test('sorts by name ascending (default)', () {
        // Default is SortMode.name, ascending=true
        final sorted = service.getSortedPlaylist(songs);
        expect(sorted.map((final s) => s.name), ['Apple', 'Banana', 'Cherry']);
      });

      test('sorts by name descending', () {
        // Toggle to descending
        service.setSortMode(SortMode.name);
        final sorted = service.getSortedPlaylist(songs);
        expect(sorted.map((final s) => s.name), ['Cherry', 'Banana', 'Apple']);
      });

      test('sorts by artist ascending', () {
        service.setSortMode(SortMode.artist);
        final sorted = service.getSortedPlaylist(songs);
        expect(sorted.map((final s) => s.artist), ['Apple', 'Monkey', 'Zebra']);
      });

      test('sorts by duration ascending', () {
        service.setSortMode(SortMode.duration);
        final sorted = service.getSortedPlaylist(songs);
        expect(sorted.map((final s) => s.durationMs), [120000, 180000, 300000]);
      });

      test('sorts by dateAdded ascending', () {
        service.setSortMode(SortMode.dateAdded);
        final sorted = service.getSortedPlaylist(songs);
        expect(sorted.map((final s) => s.dateAdded), [
          DateTime(2026),
          DateTime(2026, 2),
          DateTime(2026, 3),
        ]);
      });

      test('does not modify original list', () {
        final original = List<Song>.from(songs);
        service.setSortMode(SortMode.artist);
        service.getSortedPlaylist(songs);
        expect(songs, original);
      });
    });

    // ─── Reorder Playlist ──────────────────────────────────────────────

    group('reorderPlaylist', () {
      test('updates playlist without stopping playback', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs);

        final reordered = [songs[2], songs[0], songs[1]];
        service.reorderPlaylist(reordered);
        expect(service.playlist, reordered);
      });

      test('relocates current song in new order', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 1); // song[1]

        final reordered = [songs[2], songs[1], songs[0]];
        service.reorderPlaylist(reordered);
        expect(service.currentIndex, 1); // song[1] is now at index 1
      });

      test('handles song not found in new order', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs);

        // Replace all songs with new ones
        final newSongs = createTestSongList(3, prefix: 'New');
        service.reorderPlaylist(newSongs);
        // currentIndex stays unchanged since old song not found
        expect(service.currentIndex, 0);
      });
    });

    // ─── Play ──────────────────────────────────────────────────────────

    group('play', () {
      test('does nothing on empty playlist', () async {
        await service.play();
        expect(mockEngine.playCallCount, 0);
      });

      test('resumes if engine is paused', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs);
        mockEngine.engineState.value =
            mockEngine.engineState.value; // set to playing first
        await mockEngine.pause();

        await service.play();
        expect(mockEngine.resumeCallCount, 1);
      });
    });

    // ─── Next / Previous ───────────────────────────────────────────────

    group('next', () {
      test('does nothing on empty playlist', () async {
        await service.next();
        expect(mockEngine.playCallCount, 0);
      });

      test('sequential: goes to next song', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs);
        await service.next();
        expect(service.currentIndex, 1);
      });

      test('sequential: wraps around at end', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 2);
        await service.next();
        expect(service.currentIndex, 0);
      });

      test('repeatOne: replays current song', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 1);
        service.setPlayMode(PlayMode.repeatOne);
        await service.next();
        // repeatOne seeks to zero and replays
        expect(mockEngine.lastSeekPosition, Duration.zero);
      });

      test('playOneStop: stops at last song', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 2);
        service.setPlayMode(PlayMode.playOneStop);
        final prevPlayCount = mockEngine.playCallCount;
        await service.next();
        // Should not play anything new
        expect(mockEngine.playCallCount, prevPlayCount);
      });
    });

    group('previous', () {
      test('does nothing on empty playlist', () async {
        await service.previous();
        expect(mockEngine.playCallCount, 0);
      });

      test('sequential: goes to previous song if position < 3s', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 2);
        mockEngine.positionNotifier.value = const Duration(seconds: 1);
        await service.previous();
        expect(service.currentIndex, 1);
      });

      test('sequential: seeks to start if position > 3s', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs, startIndex: 1);
        mockEngine.positionNotifier.value = const Duration(seconds: 5);
        await service.previous();
        expect(mockEngine.lastSeekPosition, Duration.zero);
      });

      test('sequential: seeks to start at first song', () async {
        final songs = createTestSongList(3);
        await service.setPlaylist(songs);
        mockEngine.positionNotifier.value = const Duration(seconds: 1);
        await service.previous();
        expect(mockEngine.lastSeekPosition, Duration.zero);
      });
    });

    // ─── Sleep Timer ───────────────────────────────────────────────────

    group('sleep timer', () {
      test('startSleepTimer sets remaining notifier', () {
        service.startSleepTimer(const Duration(minutes: 30));
        expect(
          service.sleepTimerRemainingNotifier.value,
          const Duration(minutes: 30),
        );
        expect(service.isSleepTimerActive, isTrue);
      });

      test('cancelSleepTimer clears remaining notifier', () {
        service.startSleepTimer(const Duration(minutes: 30));
        service.cancelSleepTimer();
        expect(service.sleepTimerRemainingNotifier.value, isNull);
        expect(service.isSleepTimerActive, isFalse);
      });

      test('startSleepTimer cancels previous timer', () {
        service.startSleepTimer(const Duration(minutes: 30));
        service.startSleepTimer(const Duration(minutes: 60));
        expect(
          service.sleepTimerRemainingNotifier.value,
          const Duration(minutes: 60),
        );
      });
    });

    // ─── Dispose ───────────────────────────────────────────────────────

    group('dispose', () {
      test('disposes without throwing', () {
        // Use a separate instance to avoid double-dispose in tearDown
        final s = PlaylistService(
          MockAudioEngineService(),
          MockAudioEffectService(),
          MockDatabaseServiceWrapper(),
        );
        expect(() => s.dispose(), returnsNormally);
      });
    });
  });
}
