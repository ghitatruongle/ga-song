import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/song.dart';
import '../audio_source_cache_policy.dart';
import '../platform_capabilities.dart';
import '../services/database_service.dart';
import '../utils/sort_utils.dart';
import 'audio_engine_service.dart';
import 'audio_effect_service.dart';

enum PlayMode { sequential, repeatOne, playOneStop, shuffle }

enum SortMode { name, artist, dateAdded, duration, playCount, lastPlayed }

/// Manages playlist, playback order, shuffle logic, and cache eviction.
///
/// This service handles:
/// - Playlist setup and song ordering
/// - Play modes: sequential, repeat-one, play-one-stop, shuffle
/// - Sort modes: by name, artist, date added, duration
/// - Shuffle with history-aware randomization (avoids recent repeats)
/// - Sleep timer with countdown
/// - Crossfade coordination with [AudioEngineService]
/// - Audio source cache window management via [AudioSourceCachePolicy]
class PlaylistService {
  final AudioEngineService _engineService;
  final AudioEffectService _effectService;
  final DatabaseService _databaseService;
  final AudioSourceCachePolicy _cachePolicy = const AudioSourceCachePolicy();

  List<Song> _playlist = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequential;
  SortMode _sortMode = SortMode.name;
  bool _sortAscending = true;

  int? _plannedShuffleIndex;
  final List<int> _shuffleHistory = [];
  int _historyOffset = 0;
  bool _isPreparingCache = false;

  final ValueNotifier<int> currentIndexNotifier = ValueNotifier(-1);
  final ValueNotifier<PlayMode> playModeNotifier = ValueNotifier(
    PlayMode.sequential,
  );
  final ValueNotifier<Duration?> sleepTimerRemainingNotifier = ValueNotifier(
    null,
  );

  Timer? _sleepTimer;
  StreamSubscription<void>? _songCompletedSub;

  PlaylistService(this._engineService, this._effectService, this._databaseService) {
    _songCompletedSub = _engineService.onSongCompleted.listen((_) {
      _onSongCompleted();
    });
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  // ─── Setup ─────────────────────────────────────────────────────────────────

  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    await _engineService.stop();

    _playlist = songs;
    // C2 fix: Always reset shuffle state when playlist changes
    _shuffleHistory.clear();
    _plannedShuffleIndex = null;
    _historyOffset = 0;

    if (_playlist.isEmpty) {
      _currentIndex = -1;
      currentIndexNotifier.value = -1;
      return;
    }

    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    currentIndexNotifier.value = _currentIndex;

    await _prepareCacheWindow();
  }

  /// Updates the playlist order without stopping the current playback.
  /// Used when the user changes sort mode while music is playing.
  void reorderPlaylist(List<Song> songs) {
    final currentFileName = currentSong?.fileName;
    _playlist = songs;

    // Reset shuffle state for new order
    _shuffleHistory.clear();
    _plannedShuffleIndex = null;
    _historyOffset = 0;

    // Relocate current song in the new order
    if (currentFileName != null) {
      final newIndex = songs.indexWhere((s) => s.fileName == currentFileName);
      if (newIndex >= 0) {
        _currentIndex = newIndex;
        currentIndexNotifier.value = _currentIndex;
      }
    }

    unawaited(_prepareCacheWindow());
  }

  // ─── Playback ──────────────────────────────────────────────────────────────

  Future<void> play() async {
    if (_playlist.isEmpty) return;

    if (_engineService.engineState.value == AudioEngineState.paused) {
      await _engineService.resume();
      return;
    }

    await _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;

    final song = _playlist[_currentIndex];

    // Normalization logic: estimate based on setting or pre-calculated
    // For now we use -12.0 DB as per old logic.
    final gain = _effectService.calculateNormalizationGain(song.peakDb);

    await _engineService.playAsset(song.assetPath, normalizationGain: gain);

    currentIndexNotifier.value = _currentIndex;
    _markShufflePlayback(_currentIndex);

    // Persist duration once the engine reports it (fire-and-forget).
    if (song.durationMs == null) {
      _persistDurationWhenReady(song);
    }

    await _prepareCacheWindow();
  }

  /// Listens for the engine's duration and writes it to the database the
  /// first time a non-zero value is reported.  Self-cancels after one write.
  void _persistDurationWhenReady(Song song) {
    void listener() {
      final dur = _engineService.durationNotifier.value;
      if (dur.inMilliseconds > 0) {
        _engineService.durationNotifier.removeListener(listener);
        // Fire-and-forget: don't block playback for a DB write.
        final updated = song.copyWith(durationMs: dur.inMilliseconds);
        _databaseService.putSong(updated).catchError((Object e) {
          debugPrint('Failed to persist duration for ${song.name}: $e');
        });
      }
    }
    _engineService.durationNotifier.addListener(listener);
  }

  Future<void> playSongAt(int index, {bool isHistoryNavigation = false}) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    currentIndexNotifier.value = _currentIndex;
    if (!isHistoryNavigation) {
      _historyOffset = 0;
    }
    await _playCurrentSong();
  }

  Future<void> playSongByFileName(String fileName) async {
    final index = _playlist.indexWhere((s) => s.fileName == fileName);
    if (index != -1) {
      await playSongAt(index);
    }
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;

    switch (_playMode) {
      case PlayMode.sequential:
        final nextIdx = _currentIndex + 1;
        await playSongAt(nextIdx < _playlist.length ? nextIdx : 0);
        break;
      case PlayMode.repeatOne:
        await _engineService.seek(Duration.zero);
        await _playCurrentSong();
        break;
      case PlayMode.playOneStop:
        if (_currentIndex < _playlist.length - 1) {
          await playSongAt(_currentIndex + 1);
        }
        break;
      case PlayMode.shuffle:
        await _playNextShuffle();
        break;
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    if (_engineService.positionNotifier.value.inSeconds > 3) {
      await _engineService.seek(Duration.zero);
      return;
    }

    switch (_playMode) {
      case PlayMode.sequential:
      case PlayMode.playOneStop:
        if (_currentIndex > 0) {
          await playSongAt(_currentIndex - 1);
        } else {
          await _engineService.seek(Duration.zero);
        }
        break;
      case PlayMode.repeatOne:
        await _engineService.seek(Duration.zero);
        break;
      case PlayMode.shuffle:
        await _playPreviousShuffle();
        break;
    }
  }

  void _onSongCompleted() {
    // Track play count for the song that just completed
    final song = currentSong;
    if (song?.id != null) {
      unawaited(_databaseService.incrementPlayCount(song!.id!));
    }

    switch (_playMode) {
      case PlayMode.sequential:
        if (_currentIndex < _playlist.length - 1) {
          if (_effectService.crossfadeDurationNotifier.value > 0) {
            unawaited(_performCrossfade(_currentIndex + 1));
          } else {
            unawaited(playSongAt(_currentIndex + 1));
          }
        }
        break;
      case PlayMode.repeatOne:
        unawaited(_playCurrentSong());
        break;
      case PlayMode.playOneStop:
        // Do nothing, just stops
        break;
      case PlayMode.shuffle:
        if (_effectService.crossfadeDurationNotifier.value > 0) {
          final nextIdx = _plannedShuffleIndex ?? _selectNextShuffleIndex();
          unawaited(_performCrossfade(nextIdx));
        } else {
          unawaited(_playNextShuffle());
        }
        break;
    }
  }

  Future<void> _performCrossfade(int nextIndex) async {
    if (nextIndex < 0 || nextIndex >= _playlist.length) return;

    final nextSong = _playlist[nextIndex];
    final gain = _effectService.calculateNormalizationGain(nextSong.peakDb);
    
    // Get crossfade curve from settings
    final curveIndex = _effectService.crossfadeCurveNotifier.value;
    final curve = CrossfadeCurve.values[curveIndex.clamp(0, CrossfadeCurve.values.length - 1)];

    await _engineService.crossfadeTo(
      nextSong.assetPath,
      _effectService.crossfadeDurationNotifier.value,
      nextNormalizationGain: gain,
      curve: curve,
    );

    _currentIndex = nextIndex;
    currentIndexNotifier.value = _currentIndex;
    _markShufflePlayback(_currentIndex);
    await _prepareCacheWindow();
  }

  // ─── Play Mode & Shuffle ───────────────────────────────────────────────────

  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    if (mode == PlayMode.shuffle) {
      _shuffleHistory.clear();
    }
    _plannedShuffleIndex = null;
    _historyOffset = 0;
    playModeNotifier.value = mode;
    unawaited(_prepareCacheWindow());
  }

  Future<void> nextPlayMode() async {
    switch (_playMode) {
      case PlayMode.sequential:
        _playMode = PlayMode.repeatOne;
        break;
      case PlayMode.repeatOne:
        _playMode = PlayMode.playOneStop;
        break;
      case PlayMode.playOneStop:
        _playMode = PlayMode.shuffle;
        _shuffleHistory.clear();
        break;
      case PlayMode.shuffle:
        _playMode = PlayMode.sequential;
        _plannedShuffleIndex = null;
        _historyOffset = 0;
        break;
    }
    playModeNotifier.value = _playMode;
    unawaited(_prepareCacheWindow());
  }

  Future<void> _playNextShuffle() async {
    if (_playlist.length <= 1) {
      await _playCurrentSong();
      return;
    }
    if (_historyOffset > 0) {
      _historyOffset--;
      final idx = _shuffleHistory[_shuffleHistory.length - 1 - _historyOffset];
      await playSongAt(idx, isHistoryNavigation: true);
      return;
    }
    final nextIdx = _plannedShuffleIndex ?? _selectNextShuffleIndex();
    _plannedShuffleIndex = null;
    await playSongAt(nextIdx);
  }

  Future<void> _playPreviousShuffle() async {
    if (_playlist.length <= 1) {
      await _engineService.seek(Duration.zero);
      return;
    }
    if (_historyOffset < _shuffleHistory.length - 1) {
      _historyOffset++;
      final idx = _shuffleHistory[_shuffleHistory.length - 1 - _historyOffset];
      await playSongAt(idx, isHistoryNavigation: true);
    } else {
      await _engineService.seek(Duration.zero);
    }
  }

  void _markShufflePlayback(int index) {
    if (_playMode != PlayMode.shuffle || index < 0) return;
    // C2 fix: Bounds-check before adding to history
    if (index >= _playlist.length) return;
    // Do not modify history if we are navigating backwards
    if (_historyOffset > 0) return;
    
    _shuffleHistory.remove(index);
    _shuffleHistory.add(index);
    if (_shuffleHistory.length > _playlist.length) {
      _shuffleHistory.removeAt(0);
    }
  }

  /// C2 fix: Remove stale indices that are out of bounds after playlist change.
  void _sanitizeShuffleHistory() {
    _shuffleHistory.removeWhere((i) => i < 0 || i >= _playlist.length);
    if (_plannedShuffleIndex != null &&
        (_plannedShuffleIndex! < 0 ||
            _plannedShuffleIndex! >= _playlist.length)) {
      _plannedShuffleIndex = null;
    }
  }

  int _selectNextShuffleIndex() {
    // C2 fix: Sanitize history before using it to prevent stale index access
    _sanitizeShuffleHistory();

    final historySize = (_playlist.length * 0.4).ceil().clamp(
      1,
      _playlist.length - 1,
    );
    final recentlyPlayed = _shuffleHistory.length > historySize
        ? _shuffleHistory.sublist(_shuffleHistory.length - historySize)
        : List.of(_shuffleHistory);

    List<int> available = List.generate(
      _playlist.length,
      (i) => i,
    ).where((i) => i != _currentIndex && !recentlyPlayed.contains(i)).toList();

    if (available.isEmpty) {
      available = List.generate(
        _playlist.length,
        (i) => i,
      ).where((i) => i != _currentIndex).toList();
    }

    if (available.isEmpty) return _currentIndex.clamp(0, _playlist.length - 1);

    available.shuffle();
    return available.first;
  }

  // ─── Caching ───────────────────────────────────────────────────────────────

  Future<void> _prepareCacheWindow() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    if (_isPreparingCache) return;
    _isPreparingCache = true;

    try {
      if (_playMode == PlayMode.shuffle) {
        _plannedShuffleIndex ??= _selectNextShuffleIndex();
        final plannedIndex = _plannedShuffleIndex;
        if (plannedIndex != null) {
          await _engineService.preload(_playlist[plannedIndex].assetPath);
        }

        final keepIndices = _cachePolicy.shuffleWindow(
          currentIndex: _currentIndex,
          playlistLength: _playlist.length,
          plannedNextIndex: plannedIndex,
        );
        final keepPaths = keepIndices
            .map((i) => _playlist[i].assetPath)
            .toSet();
        await _engineService.evictSources(keepPaths);
        return;
      }

      final keepIndices = _cachePolicy.linearWindow(
        currentIndex: _currentIndex,
        playlistLength: _playlist.length,
      );
      final keepPaths = keepIndices.map((i) => _playlist[i].assetPath).toSet();

      // Concurrency-limited preload: sequential on Android (1), parallel on desktop (3)
      final concurrency = PlatformCapabilities.instance.preloadConcurrency;
      final indicesToPreload = keepIndices.toList();
      if (concurrency >= indicesToPreload.length) {
        // Fast path: parallel preload (desktop)
        await Future.wait(
          indicesToPreload.map((i) => _engineService.preload(_playlist[i].assetPath)),
        );
      } else {
        // Throttled path: sequential preload (Android)
        for (final i in indicesToPreload) {
          await _engineService.preload(_playlist[i].assetPath);
        }
      }
      await _engineService.evictSources(keepPaths);
    } finally {
      _isPreparingCache = false;
    }
  }

  // ─── Sleep Timer ───────────────────────────────────────────────────────────

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepTimerRemainingNotifier.value = duration;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = sleepTimerRemainingNotifier.value;
      if (remaining == null || remaining.inSeconds <= 1) {
        cancelSleepTimer();
        _engineService.pause();
        sleepTimerRemainingNotifier.value = null;
      } else {
        sleepTimerRemainingNotifier.value =
            remaining - const Duration(seconds: 1);
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerRemainingNotifier.value = null;
  }

  bool get isSleepTimerActive => _sleepTimer != null;

  // ─── Sort Mode ─────────────────────────────────────────────────────────────

  SortMode get sortMode => _sortMode;
  bool get sortAscending => _sortAscending;

  void setSortMode(SortMode mode) {
    if (_sortMode == mode) {
      _sortAscending = !_sortAscending;
    } else {
      _sortMode = mode;
      _sortAscending = true;
    }
  }

  List<Song> getSortedPlaylist(List<Song> songs) {
    return SongSortUtils.sorted(songs, _sortMode, ascending: _sortAscending);
  }

  void dispose() {
    _songCompletedSub?.cancel();
    _sleepTimer?.cancel();
    currentIndexNotifier.dispose();
    playModeNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
  }
}
