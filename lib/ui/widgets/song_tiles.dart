import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/playlist_service.dart';
import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import '../../core/theme/tokens.dart';
import '../../core/motion/app_motion.dart';
import '../../models/song.dart';
import 'cover_art_image.dart';
import 'playlist_manager_widget.dart';
import '../utils/animation_utils.dart';
import '../utils/haptic_helper.dart';

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
    final widget = context
        .dependOnInheritedWidgetOfExactType<SongPlaybackInheritedWidget>();
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

class SongGridTile extends ConsumerStatefulWidget {
  const SongGridTile({super.key, required this.song, required this.songIndex});

  final Song song;
  final int songIndex;

  @override
  ConsumerState<SongGridTile> createState() => _SongGridTileState();
}

class _SongGridTileState extends ConsumerState<SongGridTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final playback = SongPlaybackInheritedWidget.of(context);
    final isCurrent = playback.currentIndex == widget.songIndex;
    final isPlaying = isCurrent && playback.isPlaying;
    final playlistService = ref.read(playlistServiceProvider);
    final isDark = context.isDark;
    final animations = animationsEnabled(context);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          if (animations) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (animations) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTap: () {
            if (playlistService.playMode == PlayMode.playOneStop) {
              playlistService.setPlayMode(PlayMode.sequential);
            }
            playlistService.playSongByFileName(widget.song.fileName);
          },
          onTapDown: (_) {
            if (animations) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (animations) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (animations) setState(() => _isPressed = false);
          },
          child: AnimatedContainer(
            duration: animations ? AppDurations.short : Duration.zero,
            curve: AppCurves.decelerate,
            transform: Matrix4.diagonal3Values(
              _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
              _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
              1.0,
            ),
            transformAlignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: isCurrent
                    ? (isDark
                          ? AppColors.darkSidebarHover
                          : AppColors.lightSurface2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? (isDark ? AppColors.darkSurface3 : AppColors.lightBorder)
                      : (isDark ? AppColors.darkSurface2 : AppColors.lightDivider),
                  width: 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                            song: widget.song,
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
                          // Favorite heart overlay — top-right corner of cover art
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () async {
                                safeHaptic(HapticType.light);
                                final db = ref.read(databaseServiceProvider);
                                if (widget.song.id != null) {
                                  await db.toggleFavorite(widget.song.id!);
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.song.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 14,
                                  color: widget.song.isFavorite
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white.withValues(alpha: 0.7),
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
                              widget.song.name,
                              style: TextStyle(
                                color: context.adaptive,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.song.artist ?? 'Unknown',
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
  bool _isPressed = false;

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
    final animations = animationsEnabled(context);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          if (animations) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (animations) setState(() => _isHovered = false);
        },
        child: GestureDetector(
        onTap: () {
          final playlistService = ref.read(playlistServiceProvider);
          if (playlistService.playMode == PlayMode.playOneStop) {
            playlistService.setPlayMode(PlayMode.sequential);
          }
          playlistService.playSongByFileName(widget.song.fileName);
        },
        onTapDown: (_) {
          if (animationsEnabled(context)) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (animationsEnabled(context)) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (animationsEnabled(context)) setState(() => _isPressed = false);
        },
        child: AnimatedContainer(
          duration: animationsEnabled(context)
              ? AppDurations.short
              : Duration.zero,
          curve: AppCurves.decelerate,
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.98 : (_isHovered ? 1.01 : 1.0),
            _isPressed ? 0.98 : (_isHovered ? 1.01 : 1.0),
            1.0,
          ),
          transformAlignment: Alignment.center,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Phase 4 fix: at narrow viewports (mobile portrait with
                // sidebar visible, ~63 px inner) the fixed-width children
                // (32+12+36+12+8+40 = 140) overflow.  Drop the index and
                // shrink the cover/duration so the row fits.
                final isNarrow = constraints.maxWidth < 240;
                final coverSize = isNarrow ? 28.0 : 36.0;
                final durationWidth = isNarrow ? 32.0 : 40.0;
                final coverSpacing = isNarrow ? 8.0 : 12.0;

                return Row(
                  children: [
                    // Index / Playing indicator (hidden on narrow)
                    if (!isNarrow)
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
                                  color: context.adaptive.withValues(
                                    alpha: 0.35,
                                  ),
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),

                    if (!isNarrow) const SizedBox(width: 12),

                    // Cover art (smaller on narrow)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: coverSize,
                        height: coverSize,
                        child: CoverArtImage(
                          song: widget.song,
                          cacheWidth: (coverSize * 2).toInt(),
                          cacheHeight: (coverSize * 2).toInt(),
                          fallbackBuilder: (context) => Container(
                            color: isDark
                                ? AppColors.darkSurface2
                                : AppColors.lightSidebarHover,
                            child: Icon(
                              Icons.music_note_rounded,
                              size: isNarrow ? 14 : 18,
                              color: context.adaptive.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: coverSpacing),

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
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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

                    // Favorite heart button — Spotify signature interaction.
                    // Always visible; filled red when favorited, subtle outline otherwise.
                    if (!isNarrow)
                      GestureDetector(
                        onTap: () async {
                          safeHaptic(HapticType.light);
                          final db = ref.read(databaseServiceProvider);
                          if (widget.song.id != null) {
                            await db.toggleFavorite(widget.song.id!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Icon(
                            widget.song.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: widget.song.isFavorite
                                ? Theme.of(context).colorScheme.primary
                                : context.adaptive.withValues(alpha: 0.35),
                          ),
                        ),
                      ),

                    // Add to playlist button (on hover) — hidden on narrow
                    // because there is no room and it is a desktop-only
                    // convenience.
                    if (_isHovered && !isNarrow)
                      GestureDetector(
                        onTap: () => PlaylistManagerWidget.showAddToPlaylist(
                          context,
                          widget.song,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.playlist_add_rounded,
                            size: 18,
                            color: context.adaptive.withValues(alpha: 0.4),
                          ),
                        ),
                      ),

                    if (!isNarrow) const SizedBox(width: 8),

                    // Duration
                    SizedBox(
                      width: durationWidth,
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
                );
              },
            ),
          ),
        ),
      ),
      ),
    );
  }
}
