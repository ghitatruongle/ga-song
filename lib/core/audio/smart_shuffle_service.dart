/// Smart Shuffle v2 - Weighted Algorithm Service
///
/// Implements a weighted shuffle algorithm that considers:
/// - Play count (less played = higher weight)
/// - Skip rate (less skipped = higher weight)
/// - Recency (less recently played = higher weight)
/// - Genre affinity (preferred genres = higher weight)
///
/// The algorithm computes a score for each candidate song and selects
/// probabilistically based on weighted distribution.

import 'dart:math';
import 'dart:collection';

import '../../models/song.dart';
import '../logging/app_logger.dart';

/// Configuration for Smart Shuffle weights
class SmartShuffleConfig {
  final double playCountWeight;
  final double skipRateWeight;
  final double recencyWeight;
  final double genreAffinityWeight;
  final double randomnessFactor; // 0.0 = deterministic, 1.0 = fully random

  const SmartShuffleConfig({
    this.playCountWeight = 1.0,
    this.skipRateWeight = 1.5,
    this.recencyWeight = 1.2,
    this.genreAffinityWeight = 1.0,
    this.randomnessFactor = 0.3,
  });

  /// Default balanced configuration
  static const SmartShuffleConfig balanced = SmartShuffleConfig();

  /// Discovery-focused: prioritizes unplayed/rarely played songs
  static const SmartShuffleConfig discovery = SmartShuffleConfig(
    playCountWeight: 2.0,
    skipRateWeight: 1.0,
    recencyWeight: 1.5,
    genreAffinityWeight: 0.5,
    randomnessFactor: 0.4,
  );

  /// Favorites-focused: prioritizes frequently played, low-skip songs
  static const SmartShuffleConfig favorites = SmartShuffleConfig(
    playCountWeight: 0.5,
    skipRateWeight: 2.0,
    recencyWeight: 0.8,
    genreAffinityWeight: 1.5,
    randomnessFactor: 0.2,
  );

  SmartShuffleConfig copyWith({
    double? playCountWeight,
    double? skipRateWeight,
    double? recencyWeight,
    double? genreAffinityWeight,
    double? randomnessFactor,
  }) {
    return SmartShuffleConfig(
      playCountWeight: playCountWeight ?? this.playCountWeight,
      skipRateWeight: skipRateWeight ?? this.skipRateWeight,
      recencyWeight: recencyWeight ?? this.recencyWeight,
      genreAffinityWeight: genreAffinityWeight ?? this.genreAffinityWeight,
      randomnessFactor: randomnessFactor ?? this.randomnessFactor,
    );
  }
}

/// Result of smart shuffle scoring
class _ScoredSong {
  final int index;
  final Song song;
  final double score;
  final double playCountScore;
  final double skipRateScore;
  final double recencyScore;
  final double genreScore;

  const _ScoredSong({
    required this.index,
    required this.song,
    required this.score,
    required this.playCountScore,
    required this.skipRateScore,
    required this.recencyScore,
    required this.genreScore,
  });
}

/// Smart Shuffle Service - implements weighted shuffle algorithm
class SmartShuffleService {
  SmartShuffleService({
    SmartShuffleConfig? config,
    Random? random,
  }) : _config = config ?? SmartShuffleConfig.balanced,
       _random = random ?? Random();

  SmartShuffleConfig _config;
  final Random _random;

  SmartShuffleConfig get config => _config;

  void setConfig(SmartShuffleConfig config) {
    _config = config;
  }

  /// Computes smart shuffle scores for all songs in the playlist
  /// Returns a list of scored songs sorted by score (highest first)
  List<_ScoredSong> computeScores({
    required List<Song> playlist,
    required int currentIndex,
    required Set<int> recentlyPlayedIndices,
    Map<String, double>? genrePreferences,
  }) {
    if (playlist.isEmpty) return [];

    final now = DateTime.now();
    final maxPlayCount = _getMaxPlayCount(playlist);
    final maxSkipRate = _getMaxSkipRate(playlist);
    final oldestRecency = _getOldestRecency(playlist, now);

    final scoredSongs = <_ScoredSong>[];

    for (int i = 0; i < playlist.length; i++) {
      // Skip current song and recently played
      if (i == currentIndex || recentlyPlayedIndices.contains(i)) {
        continue;
      }

      final song = playlist[i];
      final scores = _computeSongScores(
        song: song,
        index: i,
        playlist: playlist,
        maxPlayCount: maxPlayCount,
        maxSkipRate: maxSkipRate,
        oldestRecency: oldestRecency,
        now: now,
        genrePreferences: genrePreferences,
      );

      scoredSongs.add(_ScoredSong(
        index: i,
        song: song,
        score: scores.total,
        playCountScore: scores.playCount,
        skipRateScore: scores.skipRate,
        recencyScore: scores.recency,
        genreScore: scores.genre,
      ));
    }

    // Sort by score descending
    scoredSongs.sort((a, b) => b.score.compareTo(a.score));
    return scoredSongs;
  }

  /// Selects next song using weighted random selection based on scores
  int selectNext({
    required List<Song> playlist,
    required int currentIndex,
    required Set<int> recentlyPlayedIndices,
    Map<String, double>? genrePreferences,
  }) {
    final scoredSongs = computeScores(
      playlist: playlist,
      currentIndex: currentIndex,
      recentlyPlayedIndices: recentlyPlayedIndices,
      genrePreferences: genrePreferences,
    );

    if (scoredSongs.isEmpty) {
      // Fallback: return any valid index
      final available = List.generate(playlist.length, (i) => i)
          .where((i) => i != currentIndex && !recentlyPlayedIndices.contains(i))
          .toList();
      if (available.isEmpty) return currentIndex.clamp(0, playlist.length - 1);
      return available[_random.nextInt(available.length)];
    }

    // Weighted random selection
    return _weightedRandomSelect(scoredSongs);
  }

  /// Selects next song with some randomness mixed in
  int selectNextMixed({
    required List<Song> playlist,
    required int currentIndex,
    required Set<int> recentlyPlayedIndices,
    Map<String, double>? genrePreferences,
  }) {
    // With randomnessFactor probability, use pure random
    if (_random.nextDouble() < _config.randomnessFactor) {
      final available = List.generate(playlist.length, (i) => i)
          .where((i) => i != currentIndex && !recentlyPlayedIndices.contains(i))
          .toList();
      if (available.isEmpty) return currentIndex.clamp(0, playlist.length - 1);
      return available[_random.nextInt(available.length)];
    }

    return selectNext(
      playlist: playlist,
      currentIndex: currentIndex,
      recentlyPlayedIndices: recentlyPlayedIndices,
      genrePreferences: genrePreferences,
    );
  }

  int _weightedRandomSelect(List<_ScoredSong> scoredSongs) {
    if (scoredSongs.isEmpty) return 0;

    // Compute total weight
    double totalWeight = 0;
    for (final scored in scoredSongs) {
      totalWeight += scored.score;
    }

    if (totalWeight <= 0) {
      return scoredSongs[_random.nextInt(scoredSongs.length)].index;
    }

    // Generate random point in [0, totalWeight)
    final randomPoint = _random.nextDouble() * totalWeight;

    // Walk through songs accumulating weight
    double accumulated = 0;
    for (final scored in scoredSongs) {
      accumulated += scored.score;
      if (randomPoint <= accumulated) {
        return scored.index;
      }
    }

    // Fallback (shouldn't reach here)
    return scoredSongs.last.index;
  }

  _ScoreComponents _computeSongScores({
    required Song song,
    required int index,
    required List<Song> playlist,
    required int maxPlayCount,
    required double maxSkipRate,
    required DateTime oldestRecency,
    required DateTime now,
    Map<String, double>? genrePreferences,
  }) {
    // 1. Play Count Score (0-1, inverted: less played = higher score)
    double playCountScore = 0;
    if (maxPlayCount > 0) {
      playCountScore = 1.0 - (song.playCount / maxPlayCount);
    } else {
      playCountScore = 1.0; // Never played
    }

    // 2. Skip Rate Score (0-1, inverted: less skipped = higher score)
    // Note: skip tracking is not persisted yet; always returns 1.0 so the
    // weighted sum remains stable. When skip stats are added to the schema,
    // re-enable using song.skipCount / song.playCount.
    final double skipRateScore = 1.0;

    // 3. Recency Score (0-1, less recent = higher score)
    double recencyScore = 0;
    if (song.lastPlayed != null) {
      final daysSincePlayed = now.difference(song.lastPlayed!).inDays;
      final maxDaysSincePlayed = now.difference(oldestRecency).inDays;
      if (maxDaysSincePlayed > 0) {
        recencyScore = daysSincePlayed / maxDaysSincePlayed;
      } else {
        recencyScore = 1.0;
      }
    } else {
      recencyScore = 1.0; // Never played
    }

    // 4. Genre Affinity Score (0-1)
    double genreScore = 0;
    if (genrePreferences != null && genrePreferences.isNotEmpty && song.genre != null) {
      genreScore = genrePreferences[song.genre!] ?? 0.0;
    } else if (song.genre != null) {
      // Default: small boost for having any genre tag
      genreScore = 0.1;
    }

    // Apply weights and compute total
    final weightedPlayCount = playCountScore * _config.playCountWeight;
    final weightedSkipRate = skipRateScore * _config.skipRateWeight;
    final weightedRecency = recencyScore * _config.recencyWeight;
    final weightedGenre = genreScore * _config.genreAffinityWeight;

    final total = weightedPlayCount + weightedSkipRate + weightedRecency + weightedGenre;

    return _ScoreComponents(
      total: total,
      playCount: weightedPlayCount,
      skipRate: weightedSkipRate,
      recency: weightedRecency,
      genre: weightedGenre,
    );
  }

  int _getMaxPlayCount(List<Song> playlist) {
    int maxCount = 0;
    for (final song in playlist) {
      if (song.playCount > maxCount) maxCount = song.playCount;
    }
    return maxCount;
  }

  double _getMaxSkipRate(List<Song> playlist) {
    // Skip tracking not persisted yet; always 0.
    return 0.0;
  }

  DateTime _getOldestRecency(List<Song> playlist, DateTime now) {
    DateTime? oldest;
    for (final song in playlist) {
      if (song.lastPlayed != null) {
        if (oldest == null || song.lastPlayed!.isBefore(oldest)) {
          oldest = song.lastPlayed;
        }
      }
    }
    return oldest ?? now;
  }
}

/// Internal score components for debugging/inspection
class _ScoreComponents {
  final double total;
  final double playCount;
  final double skipRate;
  final double recency;
  final double genre;

  const _ScoreComponents({
    required this.total,
    required this.playCount,
    required this.skipRate,
    required this.recency,
    required this.genre,
  });
}