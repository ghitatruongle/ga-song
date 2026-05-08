import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../song_model.dart';
import '../audio_source_cache_policy.dart';
import 'audio_engine_service.dart';
import 'audio_effect_service.dart';

enum PlayMode { sequential, repeatOne, playOneStop, shuffle }

enum SortMode { name, artist, dateAdded, duration }

/// Manages playlist, playback order, shuffle logic, and cache eviction.
class PlaylistService {
  final AudioEngineService _engineService;
  final AudioEffectService _effectService;
  final AudioSourceCachePolicy _cachePolicy = const AudioSourceCachePolicy();

  List<SongModel> _playlist = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequential;
  SortMode _sortMode = SortMode.name;
  bool _sortAscending = true;

  int? _plannedShuffleIndex;
  final List<int> _shuffleHistory = [];
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

  PlaylistService(this._engineService, this._effectService) {
    _songCompletedSub = _engineService.onSongCompleted.listen((_) {
      _onSongCompleted();
    });
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  // ─── Setup ─────────────────────────────────────────────────────────────────

  Future<void> setPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    await _engineService.stop();

    _playlist = songs;
    // C2 fix: Always reset shuffle state when playlist changes
    _shuffleHistory.clear();
    _plannedShuffleIndex = null;

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
  void reorderPlaylist(List<SongModel> songs) {
    final currentFileName = currentSong?.fileName;
    _playlist = songs;

    // Reset shuffle state for new order
    _shuffleHistory.clear();
    _plannedShuffleIndex = null;

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

    await _prepareCacheWindow();
  }

  Future<void> playSongAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    currentIndexNotifier.value = _currentIndex;
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
        await _playNextShuffle();
        break;
    }
  }

  void _onSongCompleted() {
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

    await _engineService.crossfadeTo(
      nextSong.assetPath,
      _effectService.crossfadeDurationNotifier.value,
      nextNormalizationGain: gain,
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
    final nextIdx = _plannedShuffleIndex ?? _selectNextShuffleIndex();
    _plannedShuffleIndex = null;
    await playSongAt(nextIdx);
  }

  void _markShufflePlayback(int index) {
    if (_playMode != PlayMode.shuffle || index < 0) return;
    // C2 fix: Bounds-check before adding to history
    if (index >= _playlist.length) return;
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

      await Future.wait(
        keepIndices.map((i) => _engineService.preload(_playlist[i].assetPath)),
      );
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

  List<SongModel> getSortedPlaylist(List<SongModel> songs) {
    final sorted = List<SongModel>.from(songs);
    switch (_sortMode) {
      case SortMode.name:
        sorted.sort(
          (a, b) => _sortAscending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case SortMode.artist:
        sorted.sort(
          (a, b) => _sortAscending
              ? (a.artist ?? '').toLowerCase().compareTo(
                  (b.artist ?? '').toLowerCase(),
                )
              : (b.artist ?? '').toLowerCase().compareTo(
                  (a.artist ?? '').toLowerCase(),
                ),
        );
        break;
      case SortMode.duration:
        sorted.sort(
          (a, b) => _sortAscending
              ? (a.duration ?? Duration.zero).compareTo(
                  b.duration ?? Duration.zero,
                )
              : (b.duration ?? Duration.zero).compareTo(
                  a.duration ?? Duration.zero,
                ),
        );
        break;
      case SortMode.dateAdded:
        final indexMap = <String, int>{};
        for (int i = 0; i < _playlist.length; i++) {
          indexMap[_playlist[i].fileName] = i;
        }
        sorted.sort(
          (a, b) => _sortAscending
              ? (indexMap[a.fileName] ?? 0).compareTo(indexMap[b.fileName] ?? 0)
              : (indexMap[b.fileName] ?? 0).compareTo(
                  indexMap[a.fileName] ?? 0,
                ),
        );
        break;
    }
    return sorted;
  }

  void dispose() {
    _songCompletedSub?.cancel();
    _sleepTimer?.cancel();
    currentIndexNotifier.dispose();
    playModeNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
  }
}
