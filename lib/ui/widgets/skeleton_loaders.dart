/// Skeleton Loaders for G.A - Song
///
/// Placeholder widgets that mimic the layout of content while loading.
/// Provides better perceived performance than spinners.
library;

import 'package:flutter/material.dart';
import '../../core/platform_capabilities.dart';

/// Base skeleton shimmer animation
class _SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SkeletonShimmer({required this.child})
    : duration = const Duration(milliseconds: 1500);

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Skip animation on low-end devices for better performance
    if (!PlatformCapabilities.instance.allowShimmerLoading) {
      return Opacity(opacity: 0.6, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (final context, final child) =>
          Opacity(opacity: _animation.value, child: child),
      child: widget.child,
    );
  }
}

/// Skeleton for song list tile
class SongListTileSkeleton extends StatelessWidget {
  final bool isDark;

  const SongListTileSkeleton({super.key, required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final baseColor = isDark ? Colors.white12 : Colors.black12;
    final highlightColor = isDark ? Colors.white24 : Colors.black26;

    return _SkeletonShimmer(
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: baseColor)),
        ),
        child: Row(
          children: [
            // Index placeholder
            Container(
              width: 32,
              height: 16,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Cover art placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Song info placeholders
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 13,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 120,
                    height: 11,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Duration placeholder
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for song grid tile
class SongGridTileSkeleton extends StatelessWidget {
  final bool isDark;

  const SongGridTileSkeleton({super.key, required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final baseColor = isDark ? Colors.white12 : Colors.black12;
    final highlightColor = isDark ? Colors.white24 : Colors.black26;

    return _SkeletonShimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover art placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            // Song info placeholders
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 13,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 11,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for album grid
class AlbumGridSkeleton extends StatelessWidget {
  final bool isDark;
  final int count;

  const AlbumGridSkeleton({super.key, required this.isDark, this.count = 6});

  @override
  Widget build(final BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    ),
    itemCount: count,
    itemBuilder: (final context, final index) =>
        AlbumTileSkeleton(isDark: isDark),
  );
}

/// Skeleton for single album tile
class AlbumTileSkeleton extends StatelessWidget {
  final bool isDark;

  const AlbumTileSkeleton({super.key, required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final baseColor = isDark ? Colors.white12 : Colors.black12;
    final highlightColor = isDark ? Colors.white24 : Colors.black26;

    return _SkeletonShimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 13,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 11,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for playlist view
class PlaylistViewSkeleton extends StatelessWidget {
  final bool isDark;
  final int count;

  const PlaylistViewSkeleton({super.key, required this.isDark, this.count = 8});

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
    itemExtent: 86,
    itemCount: count,
    itemBuilder: (final context, final index) =>
        SongListTileSkeleton(isDark: isDark),
  );
}

/// Skeleton for KTV screen
class KTVScreenSkeleton extends StatelessWidget {
  final bool isDark;

  const KTVScreenSkeleton({super.key, required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final baseColor = isDark ? Colors.white12 : Colors.black12;
    final highlightColor = isDark ? Colors.white24 : Colors.black26;

    return _SkeletonShimmer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Video placeholder
            Container(
              width: 400,
              height: 225,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Lyrics area placeholder
            Container(
              width: 400,
              height: 200,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for online screen (YouTube)
class OnlineScreenSkeleton extends StatelessWidget {
  final bool isDark;

  const OnlineScreenSkeleton({super.key, required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final baseColor = isDark ? Colors.white12 : Colors.black12;
    final highlightColor = isDark ? Colors.white24 : Colors.black26;

    return _SkeletonShimmer(
      child: Column(
        children: [
          // Search bar placeholder
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 10, 40, 30),
            child: Container(
              height: 44,
              width: 320,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          // Video list placeholder
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
              itemExtent: 120,
              itemCount: 6,
              itemBuilder: (final context, final index) => _VideoItemSkeleton(
                isDark: isDark,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoItemSkeleton extends StatelessWidget {
  final bool isDark;
  final Color baseColor;
  final Color highlightColor;

  const _VideoItemSkeleton({
    required this.isDark,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(final BuildContext context) => _SkeletonShimmer(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 160,
            height: 90,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
