import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/service_locator.dart';
import '../core/audio/playlist_service.dart';
import '../core/audio/lyric_parser.dart';
import '../core/view_models/player_view_model.dart';

final lyricVisibilityProvider = StateProvider<bool>((ref) => false);

class LyricNotifier extends StateNotifier<List<LyricLine>> {
  LyricNotifier() : super([]) {
    final playlistService = sl<PlaylistService>();
    playlistService.currentIndexNotifier.addListener(() {
      _loadLyrics(playlistService);
    });
    // Load initial
    _loadLyrics(playlistService);
  }

  Future<void> _loadLyrics(PlaylistService playlistService) async {
    final song = playlistService.currentSong;
    if (song != null) {
      final lines = await LyricParser.loadLyricForSong(song.sourcePath, song.isBuiltIn);
      state = lines;
    } else {
      state = [];
    }
  }
}

final lyricProvider = StateNotifierProvider<LyricNotifier, List<LyricLine>>((ref) {
  return LyricNotifier();
});

/// P-7 fix: Combines lyric lines + current playback position into a reactive
/// current-line string. Listens to BOTH lyric changes AND position changes.
/// Previous implementation only watched lyricProvider, so the displayed line
/// was stale during playback.
class CurrentLyricLineNotifier extends StateNotifier<String> {
  final Ref _ref;
  List<LyricLine> _lines = [];
  Timer? _pollTimer;

  CurrentLyricLineNotifier(this._ref) : super('') {
    // Listen to lyric list changes (new song loaded)
    _ref.listen<List<LyricLine>>(lyricProvider, (previous, next) {
      _lines = next;
      _updateCurrentLine();
    });

    // Listen to position changes (fires every ~250ms during playback)
    final positionNotifier = sl<PlayerViewModel>().positionNotifier;
    positionNotifier.addListener(_onPositionChanged);

    // Load initial lyrics
    _lines = _ref.read(lyricProvider);
    _updateCurrentLine();

    // Fallback timer: if position notifier doesn't fire (e.g. paused),
    // still check periodically for edge cases
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

    final position = sl<PlayerViewModel>().position;

    // Find the last line whose startTime <= position
    String newLine = '';
    for (int i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].startTime <= position) {
        newLine = _lines[i].text;
        break;
      }
    }

    // Only update state if line actually changed to avoid unnecessary rebuilds
    if (newLine != state) {
      state = newLine;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    try {
      sl<PlayerViewModel>().positionNotifier.removeListener(_onPositionChanged);
    } catch (_) {
      // Service locator may already be disposed
    }
    super.dispose();
  }
}

final currentLyricLineProvider =
    StateNotifierProvider<CurrentLyricLineNotifier, String>((ref) {
  return CurrentLyricLineNotifier(ref);
});
