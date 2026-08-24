import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../providers/lyric_provider.dart';
import '../../core/audio/lyric_parser.dart';
import '../../core/motion/app_motion.dart';
import '../utils/animation_utils.dart';

/// Enhanced lyric view with karaoke-style effects
/// Features:
/// - Gradient color on current line (accent → white)
/// - Fade effect on past/future lines
/// - Smooth scroll to current line
/// - Tap to seek
/// - Full-screen mode for KTV
/// - Per-syllable karaoke highlighting (when enhanced LRC available)
class LyricView extends ConsumerStatefulWidget {
  final bool isFullScreen;
  const LyricView({super.key, this.isFullScreen = false});

  @override
  ConsumerState<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends ConsumerState<LyricView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPositionChanged(final Duration currentPosition) {
    final lyrics = ref.read(lyricProvider);
    if (lyrics.isEmpty) return;

    // Binary search: find the last lyric line whose startTime <= currentPosition
    int low = 0;
    int high = lyrics.length - 1;
    int newIndex = -1;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      if (lyrics[mid].startTime <= currentPosition) {
        newIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // Also handle -1: position before the first line → clear highlight
    // instead of keeping a stale line marked as "past".
    if (newIndex != _currentIndex) {
      if (mounted) {
        setState(() {
          _currentIndex = newIndex;
        });
        if (newIndex != -1) _scrollToCurrentIndex();
      }
    }
  }

  void _scrollToCurrentIndex() {
    if (!_scrollController.hasClients) return;

    // Approximate line height — scale with the user's font-size setting so
    // the active line stays centered when lyrics are enlarged.
    final lyricScale = ref.read(settingsNotifierProvider).lyricFontSize;
    final baseLineHeight = widget.isFullScreen ? 70.0 : 48.0;
    final lineHeight = baseLineHeight * lyricScale;
    final viewportHeight = MediaQuery.of(context).size.height;
    final offset = (_currentIndex * lineHeight) - (viewportHeight / 3);

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final lyrics = ref.watch(lyricProvider);
    final accentColor = Theme.of(context).colorScheme.primary;
    final lyricScale = ref.watch(settingsNotifierProvider).lyricFontSize;
    final currentPosition = ref.watch(positionProvider);

    // Reactive position updates for scrolling
    ref.listen<Duration>(positionProvider, (_, final next) {
      _onPositionChanged(next);
    });

    if (lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: widget.isFullScreen ? 64 : 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tìm lời bài hát...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: widget.isFullScreen ? 20 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height / 2.5,
            horizontal: 24,
          ),
          itemCount: lyrics.length,
          itemBuilder: (final context, final index) {
            final line = lyrics[index];
            final isActive = index == _currentIndex;
            final isPast = index < _currentIndex;
            final distance = (index - _currentIndex).abs();

            // Calculate opacity based on distance from current line
            double opacity;
            if (isActive) {
              opacity = 1.0;
            } else if (isPast) {
              opacity = (0.4 - (distance * 0.08)).clamp(0.1, 0.4);
            } else {
              opacity = (0.5 - (distance * 0.08)).clamp(0.15, 0.5);
            }

            return RepaintBoundary(
              child: GestureDetector(
                onTap: () {
                  ref.read(audioEngineServiceProvider).seek(line.startTime);
                },
                child: AnimatedSwitcher(
                  duration: animationsEnabled(context)
                      ? AppDurations.medium
                      : Duration.zero,
                  switchInCurve: AppCurves.decelerate,
                  switchOutCurve: AppCurves.accelerate,
                  transitionBuilder: (final child, final animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Container(
                    key: ValueKey(line.startTime),
                    height: widget.isFullScreen ? 70.0 : 48.0,
                    alignment: Alignment.center,
                    child: _buildLyricLine(
                      line,
                      isActive,
                      opacity,
                      accentColor,
                      lyricScale,
                      currentPosition,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLyricLine(
    final LyricLine line,
    final bool isActive,
    final double opacity,
    final Color accentColor,
    final double lyricScale,
    final Duration currentPosition,
  ) {
    // If line has syllable-level timing, render karaoke style
    if (line.hasSyllables) {
      return _buildKaraokeLine(
        line,
        isActive,
        accentColor,
        lyricScale,
        currentPosition,
      );
    }

    // Standard line rendering
    return _buildStandardLine(line, isActive, opacity, accentColor, lyricScale);
  }

  Widget _buildStandardLine(
    final LyricLine line,
    final bool isActive,
    final double opacity,
    final Color accentColor,
    final double lyricScale,
  ) => AnimatedDefaultTextStyle(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
    style: TextStyle(
      color: isActive ? Colors.white : Colors.white.withValues(alpha: opacity),
      fontSize:
          (widget.isFullScreen ? (isActive ? 40 : 26) : (isActive ? 24 : 17)) *
          lyricScale,
      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
      letterSpacing: isActive ? 0.5 : 0,
      height: 1.4,
      shadows: isActive && widget.isFullScreen
          ? [
              Shadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 16),
              const Shadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ]
          : isActive
          ? [const Shadow(color: Colors.black38, blurRadius: 4)]
          : null,
    ),
    child: ShaderMask(
      shaderCallback: (final bounds) {
        if (!isActive) {
          return const LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(bounds);
        }
        // Gradient effect on active line
        return LinearGradient(
          colors: [accentColor, Colors.white],
          stops: const [0.0, 0.6],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Text(line.text, textAlign: TextAlign.center),
    ),
  );

  Widget _buildKaraokeLine(
    final LyricLine line,
    final bool isActive,
    final Color accentColor,
    final double lyricScale,
    final Duration currentPosition,
  ) {
    final syllables = line.syllables!;
    final syllableIndex = line.getSyllableIndexAt(currentPosition);
    final baseFontSize = widget.isFullScreen
        ? (isActive ? 40 : 26)
        : (isActive ? 24 : 17);
    final fontSize = baseFontSize * lyricScale;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: syllables.asMap().entries.map((final entry) {
        final i = entry.key;
        final syllable = entry.value;
        final isCurrentSyllable = i == syllableIndex;
        final isPastSyllable = i < syllableIndex;
        final progress = isCurrentSyllable
            ? syllable.progressAt(currentPosition)
            : (isPastSyllable ? 1.0 : 0.0);

        return ShaderMask(
          shaderCallback: (final bounds) {
            if (isPastSyllable) {
              // Past syllables: solid accent color
              return LinearGradient(
                colors: [accentColor, accentColor],
              ).createShader(bounds);
            } else if (isCurrentSyllable) {
              // Current syllable: gradient based on progress
              return LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  accentColor,
                  Colors.white,
                ],
                stops: [0.0, progress, 1.0],
              ).createShader(bounds);
            } else {
              // Future syllables: dimmed
              return LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.3),
                ],
              ).createShader(bounds);
            }
          },
          blendMode: BlendMode.srcIn,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 50),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isCurrentSyllable ? FontWeight.w800 : FontWeight.w500,
              letterSpacing: isCurrentSyllable ? 0.5 : 0,
              height: 1.4,
              shadows: isActive && widget.isFullScreen
                  ? [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                      const Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : isCurrentSyllable
                  ? [const Shadow(color: Colors.black38, blurRadius: 4)]
                  : null,
            ),
            child: Text(syllable.text, textAlign: TextAlign.center),
          ),
        );
      }).toList(),
    );
  }
}
