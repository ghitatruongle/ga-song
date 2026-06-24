import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/playlist_service.dart';
import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import 'package:ga_song/models/song.dart';
import 'cover_art_image.dart';
import 'playlist_manager_widget.dart';

/// InheritedWidget that provides playback state to all song tiles.
/// Replaces per-tile listener registration (200+ listeners → 2 parent listeners).
class SongPlaybackInheritedWidget extends InheritedWidget {
  const SongPlaybackInheritedWidget({
    super.key,
    required this.currentIndex,
    required this.isPlaying,
    required super.child,
  });

  final int currentIndex;
  final bool isPlaying;

  static SongPlaybackInheritedWidget of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<SongPlaybackInheritedWidget>();
    assert(widget != null, 'No SongPlaybackInheritedWidget found in context');
    return widget!;
  }

  @override
  bool updateShouldNotify(SongPlaybackInheritedWidget oldWidget) {
    return currentIndex != oldWidget.currentIndex ||
           isPlaying != oldWidget.isPlaying;
  }
}

// ─── Grid Tile ───────────────────────────────────────────────────────────────

class SongGridTile extends ConsumerWidget {
  const SongGridTile({super.key, required this.song, required this.songIndex});

  final Song song;
  final int songIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = SongPlaybackInheritedWidget.of(context);
    final isCurrent = playback.currentIndex == songIndex;
    final isPlaying = isCurrent && playback.isPlaying;
    final playlistService = ref.read(playlistServiceProvider);
    final isDark = context.isDark;

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (playlistService.playMode == PlayMode.playOneStop) {
            playlistService.setPlayMode(PlayMode.sequential);
          }
          playlistService.playSongByFileName(song.fileName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? (isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0))
                  : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Cover art
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CoverArtImage(
                        song: song,
                        cacheWidth: 320,
                        cacheHeight: 320,
                        fallbackBuilder: (context) => Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: context.adaptive.withValues(alpha: 0.3),
                            size: 32,
                          ),
                        ),
                      ),
                      if (isPlaying)
                        IgnorePointer(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: const Center(
                              child: Icon(
                                Icons.equalizer_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Song info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          song.name,
                          style: TextStyle(
                            color: context.adaptive,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist ?? 'Unknown',
                          style: TextStyle(
                            color: context.adaptive.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── List Tile ───────────────────────────────────────────────────────────────

class SongListTile extends ConsumerStatefulWidget {
  const SongListTile({super.key, required this.song, required this.songIndex});

  final Song song;
  final int songIndex;

  @override
  ConsumerState<SongListTile> createState() => _SongListTileState();
}

class _SongListTileState extends ConsumerState<SongListTile> {
  bool _isHovered = false;

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playback = SongPlaybackInheritedWidget.of(context);
    final isCurrent = playback.currentIndex == widget.songIndex;
    final isPlaying = isCurrent && playback.isPlaying;
    final isDark = context.isDark;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            final playlistService = ref.read(playlistServiceProvider);
            if (playlistService.playMode == PlayMode.playOneStop) {
              playlistService.setPlayMode(PlayMode.sequential);
            }
            playlistService.playSongByFileName(widget.song.fileName);
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isHovered && !isCurrent
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03))
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Index / Playing indicator
                SizedBox(
                  width: 32,
                  child: isPlaying
                      ? Icon(
                          Icons.equalizer_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Text(
                          '${widget.songIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.adaptive.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),

                const SizedBox(width: 12),

                // Cover art (small)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CoverArtImage(
                      song: widget.song,
                      cacheWidth: 72,
                      cacheHeight: 72,
                      fallbackBuilder: (context) => Container(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF0F0F0),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 18,
                          color: context.adaptive.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Song name + artist
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : context.adaptive,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.song.artist ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.adaptive.withValues(alpha: 0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Add to playlist button (on hover)
                if (_isHovered)
                  GestureDetector(
                    onTap: () => PlaylistManagerWidget.showAddToPlaylist(context, widget.song),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.playlist_add_rounded,
                        size: 18,
                        color: context.adaptive.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Duration
                SizedBox(
                  width: 40,
                  child: Text(
                    _formatDuration(widget.song.durationMs),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.adaptive.withValues(alpha: 0.35),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
