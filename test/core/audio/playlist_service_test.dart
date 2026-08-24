import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/audio_effect_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/services/db_service_wrapper.dart';
import 'package:ga_song/models/song.dart';

class MockAudioEngineService
    with WidgetsBindingObserver
    implements AudioEngineService {
  @override
  ValueNotifier<AudioEngineState> engineState = ValueNotifier(
    AudioEngineState.idle,
  );
  @override
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  @override
  ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  @override
  ValueNotifier<double> volumeNotifier = ValueNotifier(1);

  final StreamController<void> _songCompletedController =
      StreamController<void>.broadcast();
  @override
  Stream<void> get onSongCompleted => _songCompletedController.stream;

  void triggerSongCompleted() {
    _songCompletedController.add(null);
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> playAsset(
    final String assetPath, {
    final double? normalizationGain,
  }) async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(final Duration position) async {}
  @override
  void setVolume(final double volume) {}
  @override
  void setNormalizationGain(final double gain) {}
  @override
  Future<void> crossfadeTo(
    final String nextAssetPath,
    final double crossfadeDuration, {
    final double? nextNormalizationGain,
    final CrossfadeCurve curve = CrossfadeCurve.linear,
  }) async {}
  @override
  Future<void> preload(final String assetPath) async {}
  @override
  Future<void> evictSources(final Set<String> keepAssetPaths) async {}
  @override
  Future<void> dispose() async {}

  // Cache-epoch API: skip-aware preload cancellation.
  int _epoch = 0;
  @override
  int get cacheEpoch => _epoch;
  @override
  void bumpCacheEpoch() {
    _epoch++;
  }

  // P3.4: Lifecycle observer — mock is a no-op.
  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {}

  // Missing methods from AudioEngineService
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class MockAudioEffectService implements AudioEffectService {
  @override
  ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(0);
  @override
  ValueNotifier<int> bassLevelNotifier = ValueNotifier(0);

  @override
  double calculateNormalizationGain(final double? peakDb) => 1;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class MockDatabaseServiceWrapper implements DatabaseServiceWrapper {
  @override
  Future<void> incrementPlayCount(final int songId) async {}

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late MockAudioEngineService mockEngine;
  late MockAudioEffectService mockEffect;
  late PlaylistService playlistService;

  final testSongs = [
    Song(name: 'Song A', sourcePath: 'song_a.mp3', artist: 'Artist 1'),
    Song(name: 'Song C', sourcePath: 'song_c.mp3', artist: 'Artist 2'),
    Song(name: 'Song B', sourcePath: 'song_b.mp3', artist: 'Artist 1'),
  ];

  setUp(() {
    mockEngine = MockAudioEngineService();
    mockEffect = MockAudioEffectService();
    playlistService = PlaylistService(
      mockEngine,
      mockEffect,
      MockDatabaseServiceWrapper(),
    );
  });

  tearDown(() {
    playlistService.dispose();
  });

  group('PlaylistService Core Logic', () {
    test('setPlaylist initializes correctly', () async {
      await playlistService.setPlaylist(testSongs);
      expect(playlistService.playlist.length, 3);
      expect(playlistService.currentIndex, 0);
      expect(playlistService.currentSong?.name, 'Song A');
    });

    test('next() increments index in sequential mode', () async {
      await playlistService.setPlaylist(testSongs);
      playlistService.setPlayMode(PlayMode.sequential);

      await playlistService.next();
      expect(playlistService.currentIndex, 1);
      expect(playlistService.currentSong?.name, 'Song C');

      await playlistService.next();
      expect(playlistService.currentIndex, 2);

      // Should loop back to 0
      await playlistService.next();
      expect(playlistService.currentIndex, 0);
    });

    test('previous() decrements index', () async {
      await playlistService.setPlaylist(testSongs, startIndex: 2);
      playlistService.setPlayMode(PlayMode.sequential);

      await playlistService.previous();
      expect(playlistService.currentIndex, 1);
    });

    test('Sorting by name works correctly', () async {
      await playlistService.setPlaylist(testSongs);

      // Default is SortMode.name ascending.
      // Getting sorted without changing mode first.
      final sortedAsc = playlistService.getSortedPlaylist(testSongs);
      expect(sortedAsc[0].name, 'Song A');
      expect(sortedAsc[1].name, 'Song B');
      expect(sortedAsc[2].name, 'Song C');

      // Toggle to descending
      playlistService.setSortMode(SortMode.name);
      final sortedDesc = playlistService.getSortedPlaylist(testSongs);
      expect(sortedDesc[0].name, 'Song C');
      expect(sortedDesc[1].name, 'Song B');
      expect(sortedDesc[2].name, 'Song A');
    });

    test('Sorting by artist works correctly', () async {
      await playlistService.setPlaylist(testSongs);

      playlistService.setSortMode(SortMode.artist);
      final sorted = playlistService.getSortedPlaylist(testSongs);
      expect(sorted[0].artist, 'Artist 1'); // Song A
      expect(sorted[1].artist, 'Artist 1'); // Song B
      expect(sorted[2].artist, 'Artist 2'); // Song C
    });

    test('Sorting by duration works correctly', () async {
      final songsWithDuration = [
        Song(name: 'Long', sourcePath: 'long.mp3', durationMs: 300000),
        Song(name: 'Short', sourcePath: 'short.mp3', durationMs: 120000),
        Song(name: 'Medium', sourcePath: 'medium.mp3', durationMs: 200000),
      ];

      playlistService.setSortMode(SortMode.duration);
      final sorted = playlistService.getSortedPlaylist(songsWithDuration);
      expect(sorted[0].name, 'Short'); // 120s
      expect(sorted[1].name, 'Medium'); // 200s
      expect(sorted[2].name, 'Long'); // 300s
    });

    test('Sorting by duration descending toggles correctly', () async {
      final songsWithDuration = [
        Song(name: 'Long', sourcePath: 'long.mp3', durationMs: 300000),
        Song(name: 'Short', sourcePath: 'short.mp3', durationMs: 120000),
        Song(name: 'Medium', sourcePath: 'medium.mp3', durationMs: 200000),
      ];

      // First call sets ascending
      playlistService.setSortMode(SortMode.duration);
      // Second call toggles to descending
      playlistService.setSortMode(SortMode.duration);
      final sorted = playlistService.getSortedPlaylist(songsWithDuration);
      expect(sorted[0].name, 'Long'); // 300s first
      expect(sorted[1].name, 'Medium'); // 200s
      expect(sorted[2].name, 'Short'); // 120s last
    });

    test('Sorting by duration handles null durationMs', () async {
      final songsMixed = [
        Song(name: 'Has Duration', sourcePath: 'a.mp3', durationMs: 200000),
        Song(name: 'No Duration', sourcePath: 'b.mp3'), // durationMs is null
        Song(name: 'Short', sourcePath: 'c.mp3', durationMs: 60000),
      ];

      playlistService.setSortMode(SortMode.duration);
      final sorted = playlistService.getSortedPlaylist(songsMixed);
      // null duration treated as Duration.zero, sorts first in ascending
      expect(sorted[0].name, 'No Duration');
      expect(sorted[1].name, 'Short');
      expect(sorted[2].name, 'Has Duration');
    });

    test('Sorting by dateAdded works correctly', () async {
      final songsWithDates = [
        Song(name: 'Old', sourcePath: 'old.mp3', dateAdded: DateTime(2026)),
        Song(
          name: 'New',
          sourcePath: 'new.mp3',
          dateAdded: DateTime(2026, 5, 18),
        ),
        Song(
          name: 'Mid',
          sourcePath: 'mid.mp3',
          dateAdded: DateTime(2026, 3, 10),
        ),
      ];

      playlistService.setSortMode(SortMode.dateAdded);
      final sorted = playlistService.getSortedPlaylist(songsWithDates);
      expect(sorted[0].name, 'Old');
      expect(sorted[1].name, 'Mid');
      expect(sorted[2].name, 'New');
    });

    test('Sorting by dateAdded handles null dates', () async {
      final songsMixedDates = [
        Song(
          name: 'Has Date',
          sourcePath: 'a.mp3',
          dateAdded: DateTime(2026, 5),
        ),
        Song(name: 'No Date', sourcePath: 'b.mp3'), // dateAdded is null
        Song(name: 'Old', sourcePath: 'c.mp3', dateAdded: DateTime(2026)),
      ];

      playlistService.setSortMode(SortMode.dateAdded);
      final sorted = playlistService.getSortedPlaylist(songsMixedDates);
      // null date treated as epoch (oldest), sorts first in ascending
      expect(sorted[0].name, 'No Date');
      expect(sorted[1].name, 'Old');
      expect(sorted[2].name, 'Has Date');
    });
  });
}
