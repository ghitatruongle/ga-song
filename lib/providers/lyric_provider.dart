import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/playlist_service.dart';
import '../core/audio/lyric_parser.dart';
import '../core/services/online_lyrics_service.dart';
import '../core/services/db_service_wrapper.dart';
import 'service_providers.dart';

/// Simple boolean notifier for lyric visibility toggle.
class LyricVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void show() => state = true;
  void hide() => state = false;
}

final lyricVisibilityProvider = NotifierProvider<LyricVisibilityNotifier, bool>(
  LyricVisibilityNotifier.new,
);

/// Notifier managing the current song's parsed lyric lines
/// Watches the playlist index and loads lyrics (local → cache → online)
/// Uses the modern [Notifier] pattern (Riverpod)
class LyricNotifier extends Notifier<List<LyricLine>> {
  PlaylistService? _playlistService;
  DatabaseServiceWrapper? _databaseService;
  OnlineLyricsService? _onlineLyricsService;

  /// Incremented on each song change; stale async loads are discarded.
  int _loadGeneration = 0;

  @override
  List<LyricLine> build() {
    _playlistService = ref.watch(playlistServiceProvider);
    _databaseService = ref.watch(databaseServiceProvider);
    _onlineLyricsService = ref.read(onlineLyricsServiceProvider);

    // Listen to index changes
    ref.listen<int>(currentPlayingIndexProvider, (_, _) {
      _loadLyrics();
    });

    // Initial load
    _loadLyrics();

    return [];
  }

  Future<void> _loadLyrics() async {
    final generation = ++_loadGeneration;
    final song = _playlistService?.currentSong;
    if (song == null) {
      state = [];
      return;
    }

    // 1. Try local lyrics first
    final localLines = await LyricParser.loadLyricForSong(
      song.sourcePath,
      song.isBuiltIn,
    );
    if (!_isCurrent(generation)) return;
    if (localLines.isNotEmpty) {
      state = localLines;
      return;
    }

    // 2. Check cache
    if (song.id != null) {
      try {
        final cached = await _databaseService?.getCachedLyrics(song.id!);
        if (!_isCurrent(generation)) return;
        if (cached != null) {
          // Keys are 'synced'/'plain' (see DatabaseServiceWrapper.getCachedLyrics)
          final syncedLyrics = cached['synced'];
          if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
            state = LyricParser.parse(syncedLyrics);
            return;
          }
          final plainLyrics = cached['plain'];
          if (plainLyrics != null && plainLyrics.isNotEmpty) {
            state = plainLyrics
                .split('\n')
                .map(
                  (final line) =>
                      LyricLine(startTime: Duration.zero, text: line),
                )
                .toList();
            return;
          }
        }
      } catch (_) {
        // Cache miss or error, continue to online fetch
      }
    }

    // 3. Fetch from online
    try {
      final result = await _onlineLyricsService?.getBestMatch(
        title: song.name,
        artist: song.artist,
        album: song.album,
      );
      if (!_isCurrent(generation)) return;

      if (result != null) {
        if (song.id != null) {
          await _databaseService?.cacheLyrics(
            songId: song.id!,
            syncedLyrics: result.syncedLyrics,
            plainLyrics: result.plainLyrics,
            source: 'lrclib',
          );
        }

        if (result.hasSyncedLyrics) {
          state = result.parsedSyncedLyrics;
        } else if (result.hasPlainLyrics) {
          state = result.plainLyrics!
              .split('\n')
              .map(
                (final line) => LyricLine(startTime: Duration.zero, text: line),
              )
              .toList();
        } else {
          state = [];
        }
      } else {
        state = [];
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        state = [];
      }
    }
  }

  /// True if [generation] is still the latest load request.
  bool _isCurrent(final int generation) => generation == _loadGeneration;

  /// Manually fetch lyrics for the current song (e.g., from search results).
  Future<void> fetchLyrics({final String? title, final String? artist}) async {
    final song = _playlistService?.currentSong;
    if (song == null) return;

    final generation = ++_loadGeneration;
    try {
      final results = await _onlineLyricsService?.search(
        title: title ?? song.name,
        artist: artist ?? song.artist,
      );
      if (!_isCurrent(generation)) return;

      if (results != null && results.isNotEmpty) {
        final best = results.first;

        if (song.id != null) {
          await _databaseService?.cacheLyrics(
            source: 'lrclib',
            songId: song.id!,
            syncedLyrics: best.syncedLyrics,
            plainLyrics: best.plainLyrics,
          );
        }

        if (best.hasSyncedLyrics) {
          state = best.parsedSyncedLyrics;
        } else if (best.hasPlainLyrics) {
          state = best.plainLyrics!
              .split('\n')
              .map(
                (final line) => LyricLine(startTime: Duration.zero, text: line),
              )
              .toList();
        }
      }
    } catch (_) {
      // Error fetching lyrics
    }
  }
}

final lyricProvider = NotifierProvider<LyricNotifier, List<LyricLine>>(
  LyricNotifier.new,
);

/// Combines lyric lines + current playback position into a reactive
/// Current-line string notifier. Listens to lyric changes and position events.
class CurrentLyricLineNotifier extends Notifier<String> {
  List<LyricLine> _lines = [];
  // Local mirror — reading `state` inside build() throws
  // "uninitialized provider" StateError in Riverpod 3.
  String _currentLine = '';

  @override
  String build() {
    // Listen to lyric changes
    ref.listen<List<LyricLine>>(lyricProvider, (_, final next) {
      _lines = next;
      _updateCurrentLine();
    });

    // Listen to position changes for real-time updates
    ref.listen<Duration>(positionProvider, (_, _) => _onPositionChanged());

    _lines = ref.read(lyricProvider);
    _updateCurrentLine();

    return _currentLine;
  }

  void _onPositionChanged() {
    _updateCurrentLine();
  }

  void _updateCurrentLine() {
    if (_lines.isEmpty) {
      if (_currentLine.isNotEmpty) {
        _currentLine = '';
        state = '';
      }
      return;
    }

    final position = ref.read(positionProvider);

    // Binary search: last line with startTime <= currentPosition.
    int low = 0;
    int high = _lines.length - 1;
    int matchIndex = -1;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      if (_lines[mid].startTime <= position) {
        matchIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final newLine = matchIndex == -1
        ? _lines.first.text
        : _lines[matchIndex].text;
    if (newLine != _currentLine) {
      _currentLine = newLine;
      state = newLine;
    }
  }
}

final currentLyricLineProvider =
    NotifierProvider<CurrentLyricLineNotifier, String>(
      CurrentLyricLineNotifier.new,
    );

/// Provider for the current syllable index in the active lyric line.
/// Returns -1 if no syllable-level timing or no lyrics.
class CurrentSyllableIndexNotifier extends Notifier<int> {
  List<LyricLine> _lines = [];
  // Local cached value — reading `state` inside build() throws in Riverpod 3.
  int _currentSyllable = -1;

  @override
  int build() {
    // Listen to lyric changes
    ref.listen<List<LyricLine>>(lyricProvider, (_, final next) {
      _lines = next;
      _updateCurrentSyllable();
    });

    // Listen to position changes for real-time updates
    ref.listen<Duration>(positionProvider, (_, _) => _onPositionChanged());

    _lines = ref.read(lyricProvider);
    _updateCurrentSyllable();

    return _currentSyllable;
  }

  void _onPositionChanged() {
    _updateCurrentSyllable();
  }

  void _updateCurrentSyllable() {
    if (_lines.isEmpty) {
      if (_currentSyllable != -1) {
        _currentSyllable = -1;
        state = -1;
      }
      return;
    }

    final position = ref.read(positionProvider);

    // Binary search: last line with startTime <= currentPosition.
    int low = 0;
    int high = _lines.length - 1;
    int matchIndex = -1;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      if (_lines[mid].startTime <= position) {
        matchIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (matchIndex == -1) {
      if (_currentSyllable != -1) {
        _currentSyllable = -1;
        state = -1;
      }
      return;
    }

    final line = _lines[matchIndex];
    if (!line.hasSyllables) {
      if (_currentSyllable != -1) {
        _currentSyllable = -1;
        state = -1;
      }
      return;
    }

    final syllableIndex = line.getSyllableIndexAt(position);
    if (syllableIndex != _currentSyllable) {
      _currentSyllable = syllableIndex;
      state = syllableIndex;
    }
  }
}

final currentSyllableIndexProvider =
    NotifierProvider<CurrentSyllableIndexNotifier, int>(
      CurrentSyllableIndexNotifier.new,
    );
