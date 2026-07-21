import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../models/song.dart';
import 'player_bar/song_info.dart';
import 'player_bar/center_controls.dart';
import 'player_bar/right_controls.dart';

/// Width below which the player bar switches to a compact vertical
/// layout (SongInfo on top, controls below) instead of the wide
/// 3-column horizontal layout.  Picked so any viewport narrower than
/// ~half a desktop window collapses gracefully.
const double _kNarrowPlayerBarThreshold = 400.0;
const double _kPlayerBarHeightWide = 72.0;
const double _kPlayerBarHeightNarrow = 130.0;

class BottomPlayerBarWidget extends ConsumerWidget {
  const BottomPlayerBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 2.2: read state from Riverpod providers (was PlayerViewModel).
    final playlist = ref.watch(playlistServiceProvider);
    final index = ref.watch(currentPlayingIndexProvider);
    final song = (index >= 0 && index < playlist.playlist.length)
        ? playlist.playlist[index]
        : null;
    final isDark = context.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phase 4 device-debug fix: at narrow widths (mobile portrait with
        // sidebar visible, ~191 logical px), the 3-column horizontal
        // layout overflows by ~50 px.  Collapse to a vertical layout
        // (SongInfo on top, controls below) which scales gracefully.
        final isNarrow = constraints.maxWidth < _kNarrowPlayerBarThreshold;
        final barHeight =
            isNarrow ? _kPlayerBarHeightNarrow : _kPlayerBarHeightWide;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: barHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPlayerBar : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkPlayerBarBorder
                  : AppColors.lightPlayerBarBorder,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // Thin progress line on top
                if (song != null) const _TopProgressBar(),

                // Main content — split by available width.
                Expanded(
                  child: song == null
                      ? Center(
                          child: Text(
                            'Chưa chọn bài hát',
                            style: TextStyle(
                              color: context.adaptive.withValues(alpha: 0.35),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      : (isNarrow
                          ? _CompactPlayerContent(song: song)
                          : _WidePlayerContent(song: song)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wide horizontal layout: 3 columns (SongInfo | CenterControls | RightControls).
class _WidePlayerContent extends StatelessWidget {
  const _WidePlayerContent({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SongInfo(song: song),
          ),
        ),
        const Expanded(
          flex: 4,
          child: RepaintBoundary(child: CenterControls()),
        ),
        const Expanded(
          flex: 3,
          child: RepaintBoundary(child: RightControls()),
        ),
      ],
    );
  }
}

//// Narrow vertical layout: SongInfo on top, CenterControls below.
/// Right-side controls (PiP, lyrics, volume slider) are hidden on
/// narrow widths because they are desktop-only conveniences; the
/// primary playback controls are kept so the user can still play,
/// pause, and navigate tracks.
class _CompactPlayerContent extends StatelessWidget {
  const _CompactPlayerContent({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // SongInfo needs 52 px for the cover image; an undersized
        // SizedBox triggers a "BOTTOM OVERFLOWED" warning.
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SongInfo(song: song),
          ),
        ),
        const SizedBox(height: 4),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: CenterControls(),
          ),
        ),
      ],
    );
  }
}

/// Thin 2px progress indicator at the top of the player bar.
class _TopProgressBar extends ConsumerWidget {
  const _TopProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider);
    final duration = ref.watch(trackDurationProvider);
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}