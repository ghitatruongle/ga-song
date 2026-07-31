import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import '../../core/theme/tokens.dart';
import '../../core/motion/app_motion.dart';
import '../../models/song.dart';
import '../../ui/utils/animation_utils.dart';
import '../utils/theme_helpers.dart';
import 'cover_art_image.dart';

/// Bottom sheet panel showing the playback queue.
///
/// Spotify-style: shows "Now Playing" at top, then upcoming songs
/// with drag-to-reorder support.
class QueuePanel extends ConsumerWidget {
  const QueuePanel({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const QueuePanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistServiceProvider);
    final currentIndex = ref.watch(currentPlayingIndexProvider);
    final songs = playlist.playlist;
    final isDark = context.isDark;

    // Split into "now playing" + upcoming
    final upcoming = currentIndex >= 0
        ? songs.sublist(currentIndex + 1)
        : const <Song>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.adaptive.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              ThemeSpacing.of(context).lg,
              ThemeSpacing.of(context).sm,
              ThemeSpacing.of(context).lg,
              ThemeSpacing.of(context).xs,
            ),
            child: Row(
              children: [
                Text(
                  'Hàng đợi phát',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.adaptive,
                  ),
                ),
                const Spacer(),
                Text(
                  '${songs.length} bài',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.adaptive.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Queue list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                final song = upcoming[index];
                final realIndex = currentIndex + 1 + index;
                return _QueueItem(
                  song: song,
                  index: realIndex,
                  isFirst: index == 0,
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(playlistServiceProvider).playSongAt(realIndex);
                  },
                );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final Song song;
  final int index;
  final bool isFirst;
  final VoidCallback onTap;

  const _QueueItem({
    required this.song,
    required this.index,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textColor = context.adaptive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: animationsEnabled(context)
              ? AppDurations.short
              : Duration.zero,
          curve: AppCurves.decelerate,
          color: isFirst
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeSpacing.of(context).lg,
              vertical: ThemeSpacing.of(context).sm,
            ),
            child: Row(
              children: [
                // Queue number / play indicator
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFirst
                          ? Theme.of(context).colorScheme.primary
                          : textColor.withValues(alpha: 0.35),
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(width: 12),

                // Small cover art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CoverArtImage(
                      song: song,
                      cacheWidth: 80,
                      cacheHeight: 80,
                      fallbackBuilder: (context) => Container(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.lightSurface2,
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 18,
                          color: textColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
                          color: isFirst
                              ? Theme.of(context).colorScheme.primary
                              : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Duration
                Text(
                  _formatDuration(song.durationMs),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
