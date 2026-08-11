/// Mock implementation of [PlaylistService] for testing.
/// Provides controlled playlist behavior without database/audio dependencies.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/models/song.dart';

class MockPlaylistService implements PlaylistService {
  @override
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier(-1);
  @override
  final ValueNotifier<PlayMode> playModeNotifier = ValueNotifier(
    PlayMode.sequential,
  );
  @override
  final ValueNotifier<Duration?> sleepTimerRemainingNotifier = ValueNotifier(
    null,
  );

  // Internal queue state (the real service exposes `playlist`).
  List<Song> _queue = [];

  // Track calls for verification
  int playCallCount = 0;
  int nextCallCount = 0;
  int previousCallCount = 0;
  int addCallCount = 0;
  int removeCallCount = 0;
  int clearCallCount = 0;
  int reorderCallCount = 0;

  Song? lastPlayedSong;
  int? lastPlayedIndex;

  // ─── Getters ────────────────────────────────────────────────────────

  @override
  List<Song> get playlist => _queue;

  @override
  int get currentIndex => currentIndexNotifier.value;

  @override
  PlayMode get playMode => playModeNotifier.value;

  @override
  Song? get currentSong {
    final index = currentIndexNotifier.value;
    if (index >= 0 && index < _queue.length) {
      return _queue[index];
    }
    return null;
  }

  // ─── Queue Management ───────────────────────────────────────────────

  @override
  Future<void> setPlaylist(
    final List<Song> songs, {
    final int startIndex = 0,
  }) async {
    _queue = List<Song>.from(songs);
    currentIndexNotifier.value = _queue.isEmpty
        ? -1
        : startIndex.clamp(0, _queue.length - 1);
  }

  @override
  void reorderPlaylist(final List<Song> songs) {
    final currentFileName = currentSong?.fileName;
    _queue = List<Song>.from(songs);
    if (currentFileName != null) {
      final newIndex = _queue.indexWhere(
        (final s) => s.fileName == currentFileName,
      );
      if (newIndex >= 0) {
        currentIndexNotifier.value = newIndex;
      }
    }
  }

  @override
  Future<void> reorderQueue(final int oldIndex, int newIndex) async {
    reorderCallCount++;
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;
    if (oldIndex == newIndex) return;

    if (oldIndex < newIndex) {
      newIndex--;
    }
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    final cur = currentIndexNotifier.value;
    if (cur == oldIndex) {
      currentIndexNotifier.value = newIndex;
    } else if (oldIndex < cur && newIndex >= cur) {
      currentIndexNotifier.value = cur - 1;
    } else if (oldIndex > cur && newIndex <= cur) {
      currentIndexNotifier.value = cur + 1;
    }
  }

  @override
  Future<void> add(final Song song) async {
    addCallCount++;
    _queue.add(song);
  }

  @override
  Future<void> remove(final int index) async {
    removeCallCount++;
    if (index < 0 || index >= _queue.length) return;

    final wasCurrent = index == currentIndexNotifier.value;
    _queue.removeAt(index);

    if (currentIndexNotifier.value > index) {
      currentIndexNotifier.value = currentIndexNotifier.value - 1;
    } else if (wasCurrent) {
      if (_queue.isEmpty) {
        currentIndexNotifier.value = -1;
      } else {
        currentIndexNotifier.value = currentIndexNotifier.value.clamp(
          0,
          _queue.length - 1,
        );
      }
    }
  }

  @override
  Future<void> clear() async {
    clearCallCount++;
    _queue.clear();
    currentIndexNotifier.value = -1;
  }

  // ─── Playback Control ───────────────────────────────────────────────

  @override
  Future<void> play() async {
    playCallCount++;
    if (_queue.isEmpty) return;
    if (currentIndexNotifier.value < 0) {
      currentIndexNotifier.value = 0;
    }
  }

  @override
  Future<void> playSongAt(
    final int index, {
    final bool isHistoryNavigation = false,
  }) async {
    playCallCount++;
    if (index < 0 || index >= _queue.length) return;
    lastPlayedIndex = index;
    currentIndexNotifier.value = index;
  }

  @override
  Future<void> playSongByFileName(final String fileName) async {
    final index = _queue.indexWhere((final s) => s.fileName == fileName);
    if (index != -1) {
      await playSongAt(index);
    }
  }

  @override
  Future<void> next() async {
    nextCallCount++;
    if (_queue.isEmpty) return;
    final nextIdx = currentIndexNotifier.value + 1;
    currentIndexNotifier.value = nextIdx < _queue.length ? nextIdx : 0;
  }

  @override
  Future<void> previous() async {
    previousCallCount++;
    if (_queue.isEmpty) return;
    final prevIdx = currentIndexNotifier.value - 1;
    currentIndexNotifier.value = prevIdx >= 0 ? prevIdx : _queue.length - 1;
  }

  // ─── Play Mode / Sort ───────────────────────────────────────────────

  @override
  void setPlayMode(final PlayMode mode) {
    playModeNotifier.value = mode;
  }

  @override
  Future<void> nextPlayMode() async {
    const modes = PlayMode.values;
    final next = (playModeNotifier.value.index + 1) % modes.length;
    setPlayMode(modes[next]);
  }

  @override
  bool get isSleepTimerActive => false;

  @override
  SortMode get sortMode => SortMode.name;

  @override
  bool get sortAscending => true;

  @override
  void setSortMode(final SortMode mode) {}

  @override
  List<Song> getSortedPlaylist(final List<Song> songs) =>
      List<Song>.from(songs);

  // ─── Sleep Timer ────────────────────────────────────────────────────

  @override
  void startSleepTimer(final Duration duration) {
    sleepTimerRemainingNotifier.value = duration;
  }

  @override
  void startSleepTimerEndOfSong() {}

  @override
  void cancelSleepTimer() {
    sleepTimerRemainingNotifier.value = null;
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void dispose() {
    currentIndexNotifier.dispose();
    playModeNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
  }
}
