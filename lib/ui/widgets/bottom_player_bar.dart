import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../models/song.dart';
import 'player_bar/song_info.dart';
import 'player_bar/center_controls.dart';
import 'player_bar/right_controls.dart';
import '../screens/now_playing_screen.dart';
import '../../core/motion/app_motion.dart';

/// Width below which the player bar switches to a compact vertical
/// layout (SongInfo on top, controls below) instead of the wide
/// 3-column horizontal layout.  Picked so any viewport narrower than
/// ~half a desktop window collapses gracefully.
const double _kNarrowPlayerBarThreshold = 400.0;
const double _kPlayerBarHeightWide = 72.0;
const double _kPlayerBarHeightNarrow = 130.0;

/// Opacity of the per-song dominant color blended into the player bar
/// background.  Low enough to preserve readability, high enough to be
/// noticeably different per-song.
const double _kDominantColorBgBlendOpacity = 0.18;

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

    // v0.6.5: Per-song dominant color for accent-tinted player bar.
    final dominantColorAsync = ref.watch(currentSongDominantColorProvider);
    final dominantColor = switch (dominantColorAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phase 4 device-debug fix: at narrow widths (mobile portrait with
        // sidebar visible, ~191 logical px), the 3-column horizontal
        // layout overflows by ~50 px.  Collapse to a vertical layout
        // (SongInfo on top, controls below) which scales gracefully.
        final isNarrow = constraints.maxWidth < _kNarrowPlayerBarThreshold;
        final barHeight = isNarrow
            ? _kPlayerBarHeightNarrow
            : _kPlayerBarHeightWide;

        // v0.6.5: Blend per-song dominant color into the bar background
        // so the player bar subtly reflects the currently playing song's
        // cover art palette.  AnimatedContainer smooths the transition
        // between songs.
        // v0.8.0: Use gradient overlay for richer visual depth (Spotify-like).
        final baseColor = isDark ? AppColors.darkPlayerBar : Colors.white;
        final blendedBg = dominantColor != null
            ? Color.alphaBlend(
                dominantColor.withValues(alpha: _kDominantColorBgBlendOpacity),
                baseColor,
              )
            : baseColor;
        final borderColor = dominantColor != null
            ? (isDark
                ? dominantColor.withValues(alpha: 0.35)
                : dominantColor.withValues(alpha: 0.25))
            : (isDark
                ? AppColors.darkPlayerBarBorder
                : AppColors.lightPlayerBarBorder);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: barHeight,
          decoration: BoxDecoration(
            color: blendedBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              // v0.8.0: Swipe-up gesture to open Now Playing full-screen.
              // This is the signature Spotify interaction.
              // Only swipe-up triggers navigation — tap is handled by
              // individual controls (play/pause, next, prev, cover art).
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < -8) {
                  // Swipe up detected — open NowPlayingScreen
                  if (song != null && context.mounted) {
                    _openNowPlaying(context);
                  }
                }
              },
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
          ),
        );
      },
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionDuration: AppDurations.medium,
        reverseTransitionDuration: AppDurations.medium,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade + slight slide up, matching the motion language
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AppCurves.decelerate,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
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
            child: SongInfo(
              song: song,
              onCoverTap: () {
                // Tap cover art opens Now Playing
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const NowPlayingScreen(),
                      transitionDuration: AppDurations.medium,
                      reverseTransitionDuration: AppDurations.medium,
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: AppCurves.decelerate,
                        ));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: offsetAnimation, child: child),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ),
        const Expanded(
          flex: 4,
          child: RepaintBoundary(child: CenterControls()),
        ),
        const Expanded(flex: 3, child: RepaintBoundary(child: RightControls())),
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
