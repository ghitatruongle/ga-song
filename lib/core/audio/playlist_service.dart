import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/song.dart';
import '../../core/settings_manager.dart';
import '../audio_source_cache_policy.dart';
import '../logging/app_logger.dart';
import '../platform_capabilities.dart';
import '../services/db_service_wrapper.dart';
import '../utils/sort_utils.dart';
import 'audio_engine_service.dart';
import 'audio_effect_service.dart';
import 'smart_shuffle_service.dart';

enum PlayMode { sequential, repeatOne, playOneStop, shuffle }

enum SortMode { name, artist, dateAdded, duration, playCount, lastPlayed }

/// Manages playlist, playback order, shuffle logic, and cache eviction.
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
  final DatabaseServiceWrapper _databaseService;
  final SettingsManager _settingsManager;
  final AudioSourceCachePolicy _cachePolicy = const AudioSourceCachePolicy();
  final SmartShuffleService _smartShuffle = SmartShuffleService();

  List<Song> _playlist = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequential;
  SortMode _sortMode = SortMode.name;
  bool _sortAscending = true;

  int? _plannedShuffleIndex;
  final List<int> _shuffleHistory = [];
  int _historyOffset = 0;
  bool _isPreparingCache = false;

  /// Set when [_prepareCacheWindow] runs while another run is in flight — a
  /// fresh run must follow, else a skip leaves the new window with no preloads.
  bool _preparePending = false;

  final ValueNotifier<int> currentIndexNotifier = ValueNotifier(-1);
  final ValueNotifier<PlayMode> playModeNotifier = ValueNotifier(
    PlayMode.sequential,
  );
  final ValueNotifier<Duration?> sleepTimerRemainingNotifier = ValueNotifier(
    null,
  );

  Timer? _sleepTimer;
  Timer? _fadeOutTimer;
  StreamSubscription<void>? _songCompletedSub;

  // Sleep Timer v2 state
  bool _sleepAtEndOfSong = false;
  bool _isFadingOut = false;

  PlaylistService(
    this._engineService,
    this._effectService,
    this._databaseService, [
    final SettingsManager? settingsManager,
  ]) : _settingsManager = settingsManager ?? SettingsManager() {
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

  Future<void> setPlaylist(
    final List<Song> songs, {
    final int startIndex = 0,
  }) async {
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
  void reorderPlaylist(final List<Song> songs) {
    final currentFileName = currentSong?.fileName;
    _playlist = songs;

    // Reset shuffle state for new order
    _shuffleHistory.clear();
    _plannedShuffleIndex = null;
    _historyOffset = 0;

    // Relocate current song in the new order
    if (currentFileName != null) {
      final newIndex = songs.indexWhere(
        (final s) => s.fileName == currentFileName,
      );
      if (newIndex >= 0) {
        _currentIndex = newIndex;
        currentIndexNotifier.value = _currentIndex;
      }
    }

    unawaited(_prepareCacheWindow());
  }

  /// Reorders queue by moving song from oldIndex to newIndex.
  /// Callers must pass FINAL indices (post-removal semantics, the way
  /// ReorderableListView.onReorder already compensates). We do NOT adjust
  /// newIndex here — doing so caused a double-offset when callers also
  /// applied the legacy `newIndex--` compensation.
  Future<void> reorderQueue(final int oldIndex, final int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0 || newIndex >= _playlist.length) return;
    if (oldIndex == newIndex) return;

    final song = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, song);

    // Update current index if affected
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    currentIndexNotifier.value = _currentIndex;

    // Update shuffle history indices
    for (int i = 0; i < _shuffleHistory.length; i++) {
      final int histIndex = _shuffleHistory[i];
      if (histIndex == oldIndex) {
        _shuffleHistory[i] = newIndex;
      } else if (oldIndex < newIndex) {
        if (histIndex > oldIndex && histIndex <= newIndex) {
          _shuffleHistory[i] = histIndex - 1;
        }
      } else if (oldIndex > newIndex) {
        if (histIndex >= newIndex && histIndex < oldIndex) {
          _shuffleHistory[i] = histIndex + 1;
        }
      }
    }

    // Update planned shuffle index
    if (_plannedShuffleIndex != null) {
      if (_plannedShuffleIndex == oldIndex) {
        _plannedShuffleIndex = newIndex;
      } else if (oldIndex < newIndex) {
        if (_plannedShuffleIndex! > oldIndex &&
            _plannedShuffleIndex! <= newIndex) {
          _plannedShuffleIndex = _plannedShuffleIndex! - 1;
        }
      } else if (oldIndex > newIndex) {
        if (_plannedShuffleIndex! >= newIndex &&
            _plannedShuffleIndex! < oldIndex) {
          _plannedShuffleIndex = _plannedShuffleIndex! + 1;
        }
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
  void _persistDurationWhenReady(final Song song) {
    void listener() {
      final dur = _engineService.durationNotifier.value;
      if (dur.inMilliseconds > 0) {
        _engineService.durationNotifier.removeListener(listener);
        // Fire-and-forget: don't block playback for a DB write.
        final updated = song.copyWith(durationMs: dur.inMilliseconds);
        _databaseService.putSong(updated).catchError((final Object e) {
          AppLogger.w(
            'audio.playlist_service',
            'Failed to persist duration for ${song.name}',
            error: e,
          );
        });
      }
    }

    _engineService.durationNotifier.addListener(listener);
  }

  Future<void> playSongAt(
    final int index, {
    final bool isHistoryNavigation = false,
  }) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    currentIndexNotifier.value = _currentIndex;
    if (!isHistoryNavigation) {
      _historyOffset = 0;
    }
    await _playCurrentSong();
  }

  /// Adds a song to the end of the queue.
  Future<void> add(final Song song) async {
    _playlist.add(song);
    currentIndexNotifier.value = _currentIndex;
    unawaited(_prepareCacheWindow());
  }

  /// Removes a song at [index] from the queue.
  Future<void> remove(final int index) async {
    if (index < 0 || index >= _playlist.length) return;

    final wasCurrent = index == _currentIndex;
    _playlist.removeAt(index);

    // Adjust current index
    if (_currentIndex > index) {
      _currentIndex--;
    } else if (wasCurrent) {
      if (_playlist.isEmpty) {
        _currentIndex = -1;
      } else {
        _currentIndex = _currentIndex.clamp(0, _playlist.length - 1);
      }
    }
    currentIndexNotifier.value = _currentIndex;

    // Update shuffle history
    _sanitizeShuffleHistory();
    unawaited(_prepareCacheWindow());
  }

  /// Removes all songs from the queue.
  Future<void> clear() async {
    await _engineService.stop();
    _playlist.clear();
    _currentIndex = -1;
    currentIndexNotifier.value = -1;
    _shuffleHistory.clear();
    _plannedShuffleIndex = null;
    _historyOffset = 0;
  }

  Future<void> playSongByFileName(final String fileName) async {
    final index = _playlist.indexWhere((final s) => s.fileName == fileName);
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

    if (_sleepAtEndOfSong) {
      _sleepAtEndOfSong = false;
      _engineService.pause();
      return;
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

  Future<void> _performCrossfade(final int nextIndex) async {
    if (nextIndex < 0 || nextIndex >= _playlist.length) return;

    final nextSong = _playlist[nextIndex];
    final gain = _effectService.calculateNormalizationGain(nextSong.peakDb);

    // Get crossfade curve from settings
    final curveIndex = _effectService.crossfadeCurveNotifier.value;
    final curve = CrossfadeCurve
        .values[curveIndex.clamp(0, CrossfadeCurve.values.length - 1)];

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

  void setPlayMode(final PlayMode mode) {
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

  void _markShufflePlayback(final int index) {
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
    _shuffleHistory.removeWhere((final i) => i < 0 || i >= _playlist.length);
    if (_plannedShuffleIndex != null &&
        (_plannedShuffleIndex! < 0 ||
            _plannedShuffleIndex! >= _playlist.length)) {
      _plannedShuffleIndex = null;
    }
  }

  int _selectNextShuffleIndex() {
    // Use SmartShuffleService for weighted selection
    return _smartShuffle.selectNextMixed(
      playlist: _playlist,
      currentIndex: _currentIndex,
      recentlyPlayedIndices: _shuffleHistory.toSet(),
      genrePreferences: _buildGenrePreferences(),
    );
  }

  /// Builds genre preferences map from play history
  Map<String, double> _buildGenrePreferences() {
    final genreCounts = <String, int>{};
    for (final song in _playlist) {
      if (song.genre != null && song.playCount > 0) {
        genreCounts[song.genre!] =
            (genreCounts[song.genre!] ?? 0) + song.playCount;
      }
    }

    if (genreCounts.isEmpty) return {};

    final maxCount = genreCounts.values.reduce(
      (final a, final b) => a > b ? a : b,
    );
    return genreCounts.map(
      (final genre, final count) => MapEntry(genre, count / maxCount),
    );
  }

  // ─── Caching ───────────────────────────────────────────────────────────────

  Future<void> _prepareCacheWindow() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    // Invalidate in-flight preloads of the previous window via cache epoch.
    _engineService.bumpCacheEpoch();
    if (_isPreparingCache) {
      _preparePending = true;
      return;
    }
    _isPreparingCache = true;
    final epoch = _engineService.cacheEpoch;

    try {
      if (_playMode == PlayMode.shuffle) {
        _plannedShuffleIndex ??= _selectNextShuffleIndex();
        final plannedIndex = _plannedShuffleIndex;
        if (plannedIndex != null && _engineService.cacheEpoch == epoch) {
          await _engineService.preload(_playlist[plannedIndex].assetPath);
        }

        final keepIndices = _cachePolicy.shuffleWindow(
          currentIndex: _currentIndex,
          playlistLength: _playlist.length,
          plannedNextIndex: plannedIndex,
        );
        final keepPaths = keepIndices
            .map((final i) => _playlist[i].assetPath)
            .toSet();
        await _engineService.evictSources(keepPaths);
        return;
      }

      final keepIndices = _cachePolicy.linearWindow(
        currentIndex: _currentIndex,
        playlistLength: _playlist.length,
      );
      final keepPaths = keepIndices
          .map((final i) => _playlist[i].assetPath)
          .toSet();

      // Concurrency-limited preload: sequential on Android (1), parallel on desktop (3)
      final concurrency = PlatformCapabilities.instance.preloadConcurrency;
      final indicesToPreload = keepIndices.toList();
      if (concurrency >= indicesToPreload.length) {
        // Fast path: parallel preload (desktop)
        await Future.wait(
          indicesToPreload.map((final i) async {
            if (_engineService.cacheEpoch != epoch) return;
            await _engineService.preload(_playlist[i].assetPath);
          }),
        );
      } else {
        // Throttled path: sequential preload (Android)
        for (final i in indicesToPreload) {
          if (_engineService.cacheEpoch != epoch) return;
          await _engineService.preload(_playlist[i].assetPath);
        }
      }
      await _engineService.evictSources(keepPaths);
    } finally {
      _isPreparingCache = false;
      if (_preparePending) {
        _preparePending = false;
        // Re-enter after releasing the lock so the newest window (the one
        // that bumped the epoch) is prepared with the current index.
        unawaited(_prepareCacheWindow());
      }
    }
  }

  // ─── Sleep Timer ───────────────────────────────────────────────────────────

  void startSleepTimer(final Duration duration) {
    cancelSleepTimer();

    final fadeOutEnabled =
        _settingsManager.sleepTimerFadeOutEnabledNotifier.value;
    final fadeOutDuration = Duration(
      seconds: _settingsManager.sleepTimerFadeOutDurationNotifier.value,
    );

    sleepTimerRemainingNotifier.value = duration;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      final remaining = sleepTimerRemainingNotifier.value;
      if (remaining == null || remaining.inSeconds <= 1) {
        cancelSleepTimer();

        // Handle fade out before pause
        if (fadeOutEnabled && !_isFadingOut) {
          _startFadeOut(fadeOutDuration);
        } else {
          _engineService.pause();
        }

        sleepTimerRemainingNotifier.value = null;
      } else {
        sleepTimerRemainingNotifier.value =
            remaining - const Duration(seconds: 1);
      }
    });
  }

  /// Starts fade out over the specified duration, then pauses.
  void _startFadeOut(final Duration fadeOutDuration) {
    if (_isFadingOut) return;
    _isFadingOut = true;

    final currentVolume = _engineService.volumeNotifier.value;
    final steps = fadeOutDuration.inMilliseconds ~/ 50; // 50ms steps
    final double volumeStep = currentVolume / steps;

    _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 50), (
      final timer,
    ) {
      if (!_isFadingOut) {
        timer.cancel();
        return;
      }

      final newVolume = (_engineService.volumeNotifier.value - volumeStep)
          .clamp(0.0, 1.0);
      _engineService.setVolume(newVolume);

      if (newVolume <= 0.01) {
        timer.cancel();
        _isFadingOut = false;
        _engineService.pause();
        _engineService.setVolume(currentVolume); // Restore volume for next play
      }
    });
  }

  /// Stops playback when the current song finishes naturally.
  void startSleepTimerEndOfSong() {
    _sleepAtEndOfSong = true;
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _fadeOutTimer?.cancel();
    _sleepTimer = null;
    _fadeOutTimer = null;
    _isFadingOut = false;
    sleepTimerRemainingNotifier.value = null;
    _sleepAtEndOfSong = false;
  }

  bool get isSleepTimerActive =>
      _sleepTimer != null || _sleepAtEndOfSong || _isFadingOut;

  // ─── Sort Mode ─────────────────────────────────────────────────────────────

  SortMode get sortMode => _sortMode;
  bool get sortAscending => _sortAscending;

  void setSortMode(final SortMode mode) {
    if (_sortMode == mode) {
      _sortAscending = !_sortAscending;
    } else {
      _sortMode = mode;
      _sortAscending = true;
    }
  }

  List<Song> getSortedPlaylist(final List<Song> songs) =>
      SongSortUtils.sorted(songs, _sortMode, ascending: _sortAscending);

  void dispose() {
    _songCompletedSub?.cancel();
    _sleepTimer?.cancel();
    _fadeOutTimer?.cancel();
    currentIndexNotifier.dispose();
    playModeNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
  }
}
