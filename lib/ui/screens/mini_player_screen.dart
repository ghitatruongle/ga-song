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
import '../../providers/service_providers.dart';
import '../widgets/cover_art_image.dart';
import '../utils/haptic_helper.dart';

/// Whether the current platform is desktop (Windows/macOS/Linux).
bool get _isDesktopPlatform =>
    !kIsWeb &&
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

class MiniPlayerScreen extends ConsumerWidget {
  const MiniPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isDesktopPlatform) {
      return const _DesktopMiniPlayer();
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final pipService = ref.read(pipServiceProvider);
      return ValueListenableBuilder<bool>(
        valueListenable: pipService.isInPipNotifier,
        builder: (context, isInPip, _) {
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
  BuildContext context,
  SettingsManager settings,
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

class _DesktopMiniPlayer extends ConsumerWidget {
  const _DesktopMiniPlayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              builder: (context) {
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
                    fallbackBuilder: (context) =>
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

          // Drag Window Area (desktop only)
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  ref.read(playlistServiceProvider).next();
                } else if (details.primaryVelocity! > 300) {
                  ref.read(playlistServiceProvider).previous();
                }
              },
              child: const DragToMoveArea(child: SizedBox.expand()),
            ),
          ),

          // Content
          Positioned.fill(
            child: Builder(
              builder: (context) {
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
                        fallbackBuilder: (context) => DecoratedBox(
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
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: textColor.withValues(alpha: 0.6),
                          tooltip: 'Đóng mini player',
                          onPressed: () =>
                              _restoreFromMiniPlayer(context, settings),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.read(playlistServiceProvider);
    final song = playlist.currentSong;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background — blurred cover art
          Positioned.fill(
            child: Builder(
              builder: (context) {
                if (song != null) {
                  return CoverArtImage(
                    song: song,
                    cacheWidth: 256,
                    cacheHeight: 256,
                    fallbackBuilder: (context) =>
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

          // Content
          SafeArea(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  ref.read(playlistServiceProvider).next();
                } else if (details.primaryVelocity! > 300) {
                  ref.read(playlistServiceProvider).previous();
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                    fallbackBuilder: (context) => Container(
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
            builder: (context, ref, _) {
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
                      onChanged: (value) {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              fallbackBuilder: (context) =>
                  Container(color: AppColors.darkSurface),
            )
          else
            Container(color: AppColors.darkSurface),

          // Dark scrim for readability
          Container(color: Colors.black.withValues(alpha: 0.35)),

          // Centered play/pause button & swipe
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  ref.read(playlistServiceProvider).next();
                } else if (details.primaryVelocity! > 300) {
                  ref.read(playlistServiceProvider).previous();
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
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
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
/// Uses the shared LyricProvider via Riverpod to show the current line.
class _MiniPlayerLyricLine extends ConsumerStatefulWidget {
  final Song? song;
  const _MiniPlayerLyricLine({required this.song});

  @override
  ConsumerState<_MiniPlayerLyricLine> createState() =>
      _MiniPlayerLyricLineState();
}

class _MiniPlayerLyricLineState extends ConsumerState<_MiniPlayerLyricLine> {
  final ScrollController _scrollController = ScrollController();
  String _currentLine = '';

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    if (song == null) return const SizedBox.shrink();

    // Watch the current lyric line provider
    final line = ref.watch(currentLyricLineProvider);

    // Auto-scroll horizontally when line changes
    if (line != _currentLine) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // P4 BUG-3: state may have been disposed before the next frame
        // fires (e.g. mini-player closed mid-lyric-change). Guard so we
        // don't touch the ScrollController of a defunct widget.
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      _currentLine = line;
    }

    if (line.isEmpty) return const SizedBox.shrink();

    final textColor = context.adaptive;
    return SizedBox(
      height: 18,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Text(
          line,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
