import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/audio_effect_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/song_model.dart';

class MockAudioEngineService implements AudioEngineService {
  @override
  ValueNotifier<AudioEngineState> engineState = ValueNotifier(AudioEngineState.idle);
  @override
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  @override
  ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  @override
  ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);

  final StreamController<void> _songCompletedController = StreamController<void>.broadcast();
  @override
  Stream<void> get onSongCompleted => _songCompletedController.stream;

  void triggerSongCompleted() {
    _songCompletedController.add(null);
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> playAsset(String assetPath, {double? normalizationGain}) async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  void setVolume(double volume) {}
  @override
  void setNormalizationGain(double gain) {}
  @override
  Future<void> crossfadeTo(String nextAssetPath, double crossfadeDuration, {double? nextNormalizationGain}) async {}
  @override
  Future<void> preload(String assetPath) async {}
  @override
  Future<void> evictSources(Set<String> keepAssetPaths) async {}
  @override
  Future<void> dispose() async {}

  // Missing methods from AudioEngineService
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAudioEffectService implements AudioEffectService {
  @override
  ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(0.0);
  @override
  ValueNotifier<int> bassLevelNotifier = ValueNotifier(0);
  
  @override
  double calculateNormalizationGain(double? peakDb) => 1.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAudioEngineService mockEngine;
  late MockAudioEffectService mockEffect;
  late PlaylistService playlistService;

  final testSongs = [
    SongModel(name: 'Song A', fileName: 'song_a.mp3', artist: 'Artist 1'),
    SongModel(name: 'Song C', fileName: 'song_c.mp3', artist: 'Artist 2'),
    SongModel(name: 'Song B', fileName: 'song_b.mp3', artist: 'Artist 1'),
  ];

  setUp(() {
    mockEngine = MockAudioEngineService();
    mockEffect = MockAudioEffectService();
    playlistService = PlaylistService(mockEngine, mockEffect);
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
  });
}
