import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart' hide WindowCaptionButton;
import '../../core/audio/audio_engine_service.dart';
import '../../core/settings_manager.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../core/utils/time_utils.dart';
import '../../models/song.dart';
import '../../providers/lyric_provider.dart';
import '../../core/audio/lyric_parser.dart';
import '../../providers/service_providers.dart';
import '../utils/haptic_helper.dart';
import '../widgets/cover_art_image.dart';
import '../widgets/queue_management.dart';

/// Whether the current platform is desktop (Windows/macOS/Linux).
bool get _isDesktopPlatform =>
    !kIsWeb &&
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

class MiniPlayerScreen extends ConsumerWidget {
  const MiniPlayerScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (_isDesktopPlatform) {
      return const _DesktopMiniPlayer();
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final pipService = ref.read(pipServiceProvider);
      return ValueListenableBuilder<bool>(
        valueListenable: pipService.isInPipNotifier,
        builder: (final context, final isInPip, _) {
          if (isInPip) return const _PipCompactPlayer();
          return const _MobileMiniPlayer();
        },
      );
    }
    return const _MobileMiniPlayer();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop: compact 350×100 strip (existing design)
// ─────────────────────────────────────────────────────────────────────────────

/// Restores the window from mini player mode to normal size.
Future<void> _restoreFromMiniPlayer(
  final BuildContext context,
  final SettingsManager settings,
) async {
  final screenSize = MediaQuery.sizeOf(context);
  settings.setIsMiniPlayer(false);
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setMaximumSize(const Size(32000, 32000));
  final savedSize = settings.savedWindowSize;
  final targetSize = savedSize ?? const Size(1000, 700);
  final maxWidth = (screenSize.width * 0.9).clamp(800.0, 32000.0);
  final maxHeight = (screenSize.height * 0.9).clamp(600.0, 32000.0);
  final clampedSize = Size(
    targetSize.width.clamp(800.0, maxWidth),
    targetSize.height.clamp(600.0, maxHeight),
  );
  await windowManager.setSize(clampedSize);
  if (settings.savedWindowMaximized) {
    await windowManager.maximize();
  }
  if (settings.savedWindowFullScreen) {
    await windowManager.setFullScreen(true);
  }
  await windowManager.setAlwaysOnTop(false);
}

/// Dismisses the mini player (closes it without restoring).
Future<void> _dismissMiniPlayer(
  final BuildContext context,
  final SettingsManager settings,
) async {
  settings.setIsMiniPlayer(false);
  await windowManager.hide();
}

/// Shows the queue management sheet.
void _showQueueSheet(final BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (final context) => const QueueManagementSheet(),
  );
}

class _DesktopMiniPlayer extends ConsumerWidget {
  const _DesktopMiniPlayer();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.read(settingsManagerProvider);
    final playlist = ref.read(playlistServiceProvider);

    // Watch playback state to drive cover art + button rebuilds.
    final isPlaying =
        ref.watch(engineStateProvider) == AudioEngineState.playing;
    final song = playlist.currentSong;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Builder(
              builder: (final context) {
                if (song != null) {
                  const maxCacheSize = 256;
                  final mediaSize = MediaQuery.sizeOf(context);
                  final pixelRatio = MediaQuery.devicePixelRatioOf(context);
                  final cacheWidth = (mediaSize.width * pixelRatio)
                      .clamp(1, maxCacheSize)
                      .round();
                  final cacheHeight = (mediaSize.height * pixelRatio)
                      .clamp(1, maxCacheSize)
                      .round();
                  return CoverArtImage(
                    song: song,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    fallbackBuilder: (final context) =>
                        Container(color: AppColors.darkBackground),
                  );
                }
                return Container(color: AppColors.darkBackground);
              },
            ),
          ),

          // Blur overlay — RepaintBoundary isolates blur from content repaints
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),

          // Drag Area - handles both horizontal (next/prev) and vertical (expand/dismiss) swipes
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (final details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  ref.read(playlistServiceProvider).next();
                } else if (details.primaryVelocity! > 300) {
                  ref.read(playlistServiceProvider).previous();
                }
              },
              onVerticalDragEnd: (final details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -500) {
                  // Swipe up → expand to full player
                  _restoreFromMiniPlayer(context, settings);
                } else if (details.primaryVelocity! > 500) {
                  // Swipe down → dismiss/hide mini player
                  _dismissMiniPlayer(context, settings);
                }
              },
              child: const DragToMoveArea(child: SizedBox.expand()),
            ),
          ),

          // Content
          Positioned.fill(
            child: Builder(
              builder: (final context) {
                if (song == null) return const SizedBox.shrink();

                final textColor = context.adaptive;

                return Row(
                  children: [
                    // Album Art
                    Container(
                      margin: const EdgeInsets.all(10),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CoverArtImage(
                        song: song,
                        cacheWidth: 128,
                        cacheHeight: 128,
                        fallbackBuilder: (final context) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: context.adaptiveSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Info + Lyric compact
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.name,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist ?? 'Unknown',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Compact lyric scroll
                          _MiniPlayerLyricLine(song: song),
                        ],
                      ),
                    ),

                    // Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            size: 22,
                          ),
                          color: textColor,
                          onPressed: () {
                            safeHaptic(HapticType.light);
                            ref.read(playlistServiceProvider).previous();
                          },
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: textColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              size: 18,
                            ),
                            onPressed: () {
                              safeHaptic(HapticType.medium);
                              final playing =
                                  ref.read(engineStateProvider) ==
                                  AudioEngineState.playing;
                              if (playing) {
                                ref.read(audioEngineServiceProvider).pause();
                              } else {
                                ref.read(playlistServiceProvider).play();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 22),
                          color: textColor,
                          onPressed: () {
                            safeHaptic(HapticType.light);
                            ref.read(playlistServiceProvider).next();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.queue_music_rounded, size: 22),
                          color: textColor,
                          onPressed: () {
                            safeHaptic(HapticType.light);
                            _showQueueSheet(context);
                          },
                          tooltip: 'Hàng đợi phát',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: textColor.withValues(alpha: 0.6),
                          tooltip: 'Đóng mini player',
                          onPressed: () =>
                              _dismissMiniPlayer(context, settings),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_full_rounded,
                            size: 20,
                          ),
                          color: textColor.withValues(alpha: 0.6),
                          tooltip: 'Trở lại bình thường',
                          onPressed: () =>
                              _restoreFromMiniPlayer(context, settings),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile: full-screen immersive mini player
// ─────────────────────────────────────────────────────────────────────────────

class _MobileMiniPlayer extends ConsumerWidget {
  const _MobileMiniPlayer();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playlist = ref.read(playlistServiceProvider);
    final settings = ref.read(settingsManagerProvider);
    final song = playlist.currentSong;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background — blurred cover art
          Positioned.fill(
            child: Builder(
              builder: (final context) {
                if (song != null) {
                  return CoverArtImage(
                    song: song,
                    cacheWidth: 256,
                    cacheHeight: 256,
                    fallbackBuilder: (final context) =>
                        Container(color: AppColors.darkBackground),
                  );
                }
                return Container(color: AppColors.darkBackground);
              },
            ),
          ),

          // Blur + dark scrim — RepaintBoundary isolates blur from content repaints
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),

          // Content with swipe gestures:
          // - Horizontal: next/prev track
          // - Vertical up: expand to full now playing screen
          // - Vertical down: dismiss mini player
          SafeArea(
            child: GestureDetector(
              onHorizontalDragEnd: (final details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  ref.read(playlistServiceProvider).next();
                } else if (details.primaryVelocity! > 300) {
                  ref.read(playlistServiceProvider).previous();
                }
              },
              onVerticalDragEnd: (final details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -500) {
                  // Swipe up → expand to full now playing screen
                  settings.setIsMiniPlayer(false);
                } else if (details.primaryVelocity! > 500) {
                  // Swipe down → dismiss mini player
                  settings.setIsMiniPlayer(false);
                }
              },
              child: song == null
                  ? Center(
                      child: Text(
                        'Chưa chọn bài hát',
                        style: TextStyle(
                          color: context.adaptive.withValues(alpha: 0.4),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : _MobileMiniPlayerContent(song: song),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileMiniPlayerContent extends ConsumerWidget {
  const _MobileMiniPlayerContent({required this.song});

  final Song song;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textColor = context.adaptive;
    final isPlaying =
        ref.watch(engineStateProvider) == AudioEngineState.playing;

    return Column(
      children: [
        // Top bar — back / expand button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textColor,
                  size: 32,
                ),
                tooltip: 'Trở lại bình thường',
                onPressed: () {
                  ref.read(settingsManagerProvider).setIsMiniPlayer(false);
                },
              ),
              const Spacer(),
              Text(
                'ĐANG PHÁT',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // balance the left icon
            ],
          ),
        ),

        // Cover art — large, centered
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CoverArtImage(
                    song: song,
                    cacheWidth: 512,
                    cacheHeight: 512,
                    fallbackBuilder: (final context) => ColoredBox(
                      color: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.16),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: context.adaptiveSecondary,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Song info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                song.name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                song.artist ?? 'Unknown',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Consumer(
            builder: (final context, final ref, _) {
              final position = ref.watch(positionProvider);
              final duration = ref.watch(trackDurationProvider);
              final progress = duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    )
                  : 0.0;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: textColor,
                      inactiveTrackColor: textColor.withValues(alpha: 0.2),
                      thumbColor: textColor,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (final value) {
                        final newPosition = Duration(
                          milliseconds: (value * duration.inMilliseconds)
                              .round(),
                        );
                        ref.read(audioEngineServiceProvider).seek(newPosition);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(position),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatDuration(duration),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Playback controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  size: 40,
                  color: textColor,
                ),
                onPressed: () {
                  safeHaptic(HapticType.light);
                  ref.read(playlistServiceProvider).previous();
                },
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    size: 36,
                  ),
                  onPressed: () {
                    safeHaptic(HapticType.medium);
                    final playing =
                        ref.read(engineStateProvider) ==
                        AudioEngineState.playing;
                    if (playing) {
                      ref.read(audioEngineServiceProvider).pause();
                    } else {
                      ref.read(playlistServiceProvider).play();
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.skip_next_rounded, size: 40, color: textColor),
                onPressed: () {
                  safeHaptic(HapticType.light);
                  ref.read(playlistServiceProvider).next();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Android PiP: ultra-compact layout (cover art + play/pause only)
// ─────────────────────────────────────────────────────────────────────────────

class _PipCompactPlayer extends ConsumerWidget {
  const _PipCompactPlayer();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playlist = ref.read(playlistServiceProvider);
    final isPlaying =
        ref.watch(engineStateProvider) == AudioEngineState.playing;
    final song = playlist.currentSong;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed cover art background
          if (song != null)
            CoverArtImage(
              song: song,
              cacheWidth: 256,
              cacheHeight: 144,
              fallbackBuilder: (final context) =>
                  Container(color: AppColors.darkSurface),
            )
          else
            Container(color: AppColors.darkSurface),

          // Dark scrim for readability
          Container(color: Colors.black.withValues(alpha: 0.35)),

          // Centered play/pause button & swipe
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (final details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  ref.read(playlistServiceProvider).next();
                } else if (details.primaryVelocity! > 300) {
                  ref.read(playlistServiceProvider).previous();
                }
              },
              onVerticalDragEnd: (final details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -500) {
                  // Swipe up → expand to full now playing screen
                  // In PiP mode, we just close PiP
                  ref.read(pipServiceProvider).isInPipNotifier.value = false;
                } else if (details.primaryVelocity! > 500) {
                  // Swipe down → close PiP
                  ref.read(pipServiceProvider).isInPipNotifier.value = false;
                }
              },
              onTap: () {
                final playing =
                    ref.read(engineStateProvider) == AudioEngineState.playing;
                if (playing) {
                  ref.read(audioEngineServiceProvider).pause();
                } else {
                  ref.read(playlistServiceProvider).play();
                }
              },
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          // Song name at bottom
          if (song != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Text(
                song.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact lyric line for the desktop mini player.
/// Uses the shared LyricProvider via Riverpod to show the current line with karaoke highlighting.
class _MiniPlayerLyricLine extends ConsumerWidget {
  final Song? song;
  const _MiniPlayerLyricLine({required this.song});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final song = this.song;
    if (song == null) return const SizedBox.shrink();

    final lyrics = ref.watch(lyricProvider);
    final currentPosition = ref.watch(positionProvider);
    final currentSyllableIndex = ref.watch(currentSyllableIndexProvider);
    final textColor = context.adaptive;

    if (lyrics.isEmpty) return const SizedBox.shrink();

    // Find the current lyric line
    LyricLine? currentLine;
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (lyrics[i].startTime <= currentPosition) {
        currentLine = lyrics[i];
        break;
      }
    }

    if (currentLine == null || currentLine.text.isEmpty) {
      return const SizedBox.shrink();
    }

    // If line has syllables, show karaoke style
    if (currentLine.hasSyllables) {
      return _buildKaraokeLine(
        currentLine,
        currentSyllableIndex,
        textColor,
        context,
      );
    }

    // Standard line
    return SizedBox(
      height: 18,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          currentLine.text,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildKaraokeLine(
    final LyricLine line,
    final int currentSyllableIndex,
    final Color textColor,
    final BuildContext context,
  ) {
    final syllables = line.syllables!;

    return SizedBox(
      height: 18,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: syllables.asMap().entries.map((final entry) {
            final i = entry.key;
            final syllable = entry.value;
            final isCurrentSyllable = i == currentSyllableIndex;
            final isPastSyllable = i < currentSyllableIndex;

            return ShaderMask(
              shaderCallback: (final bounds) {
                if (isPastSyllable) {
                  // Past syllables: solid accent color
                  return LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary,
                    ],
                  ).createShader(bounds);
                } else if (isCurrentSyllable) {
                  // Current syllable: gradient from dim to accent to white
                  return LinearGradient(
                    colors: [
                      textColor.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.primary,
                      textColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                } else {
                  // Future syllables: dimmed
                  return LinearGradient(
                    colors: [
                      textColor.withValues(alpha: 0.3),
                      textColor.withValues(alpha: 0.3),
                    ],
                  ).createShader(bounds);
                }
              },
              blendMode: BlendMode.srcIn,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrentSyllable
                      ? FontWeight.w800
                      : FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  letterSpacing: isCurrentSyllable ? 0.5 : 0,
                  height: 1.4,
                ),
                child: Text(syllable.text),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
