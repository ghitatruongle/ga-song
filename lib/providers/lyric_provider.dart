import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/audio/playlist_service.dart';
import '../core/audio/lyric_parser.dart';
import '../core/services/online_lyrics_service.dart';
import '../core/services/database_service.dart';
import 'service_providers.dart';

final lyricVisibilityProvider = StateProvider<bool>((ref) => false);

class LyricNotifier extends StateNotifier<List<LyricLine>> {
  LyricNotifier(this._playlistService, this._databaseService, this._onlineLyricsService) : super([]) {
    _playlistService.currentIndexNotifier.addListener(() {
      _loadLyrics();
    });
    _loadLyrics();
  }

  final PlaylistService _playlistService;
  final DatabaseService _databaseService;
  final OnlineLyricsService _onlineLyricsService;

  Future<void> _loadLyrics() async {
    final song = _playlistService.currentSong;
    if (song == null) {
      state = [];
      return;
    }

    // 1. Try local lyrics first
    final localLines = await LyricParser.loadLyricForSong(song.sourcePath, song.isBuiltIn);
    if (localLines.isNotEmpty) {
      state = localLines;
      return;
    }

    // 2. Check cache
    if (song.id != null) {
      try {
        final cached = await _databaseService.getCachedLyrics(song.id!);
        if (cached != null) {
          final syncedLyrics = cached['syncedLyrics'];
          if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
            state = LyricParser.parse(syncedLyrics);
            return;
          }
          final plainLyrics = cached['plainLyrics'];
          if (plainLyrics != null && plainLyrics.isNotEmpty) {
            // Convert plain lyrics to LyricLine format (no timestamps)
            state = plainLyrics.split('\n').map((line) => 
              LyricLine(startTime: Duration.zero, text: line)
            ).toList();
            return;
          }
        }
      } catch (e) {
        // Cache miss or error, continue to online fetch
      }
    }

    // 3. Fetch from online
    try {
      final result = await _onlineLyricsService.getBestMatch(
        title: song.name,
        artist: song.artist,
        album: song.album,
      );

      if (result != null) {
        // Cache the result
        if (song.id != null) {
          await _databaseService.cacheLyrics(
            songId: song.id!,
            syncedLyrics: result.syncedLyrics,
            plainLyrics: result.plainLyrics,
          );
        }

        // Parse and set lyrics
        if (result.hasSyncedLyrics) {
          state = result.parsedSyncedLyrics;
        } else if (result.hasPlainLyrics) {
          state = result.plainLyrics!.split('\n').map((line) => 
            LyricLine(startTime: Duration.zero, text: line)
          ).toList();
        } else {
          state = [];
        }
      } else {
        state = [];
      }
    } catch (e) {
      state = [];
    }
  }

  /// Manually fetch lyrics for the current song (e.g., from search results)
  Future<void> fetchLyrics({String? title, String? artist}) async {
    final song = _playlistService.currentSong;
    if (song == null) return;

    try {
      final results = await _onlineLyricsService.search(
        title: title ?? song.name,
        artist: artist ?? song.artist,
      );

      if (results.isNotEmpty) {
        final best = results.first;
        
        // Cache the result
        if (song.id != null) {
          await _databaseService.cacheLyrics(
            songId: song.id!,
            syncedLyrics: best.syncedLyrics,
            plainLyrics: best.plainLyrics,
          );
        }

        if (best.hasSyncedLyrics) {
          state = best.parsedSyncedLyrics;
        } else if (best.hasPlainLyrics) {
          state = best.plainLyrics!.split('\n').map((line) => 
            LyricLine(startTime: Duration.zero, text: line)
          ).toList();
        }
      }
    } catch (e) {
      // Error fetching lyrics
    }
  }
}

final lyricProvider = StateNotifierProvider<LyricNotifier, List<LyricLine>>((ref) {
  final playlist = ref.read(playlistServiceProvider);
  final db = ref.read(databaseServiceProvider);
  final onlineLyrics = ref.read(onlineLyricsServiceProvider);
  return LyricNotifier(playlist, db, onlineLyrics);
});

/// Combines lyric lines + current playback position into a reactive
/// current-line string. Listens to BOTH lyric changes AND position changes.
class CurrentLyricLineNotifier extends StateNotifier<String> {
  final Ref _ref;
  List<LyricLine> _lines = [];
  Timer? _pollTimer;

  CurrentLyricLineNotifier(this._ref) : super('') {
    _ref.listen<List<LyricLine>>(lyricProvider, (previous, next) {
      _lines = next;
      _updateCurrentLine();
    });

    _ref.listen(positionProvider, (_, _) => _onPositionChanged());

    _lines = _ref.read(lyricProvider);
    _updateCurrentLine();

    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateCurrentLine();
    });
  }

  void _onPositionChanged() {
    _updateCurrentLine();
  }

  void _updateCurrentLine() {
    if (_lines.isEmpty) {
      if (state.isNotEmpty) state = '';
      return;
    }

    final position = _ref.read(positionProvider);

    String newLine = '';
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].startTime <= position) {
        newLine = _lines[i].text;
        break;
      }
    }

    if (newLine != state) {
      state = newLine;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final currentLyricLineProvider =
    StateNotifierProvider<CurrentLyricLineNotifier, String>((ref) {
  return CurrentLyricLineNotifier(ref);
});
