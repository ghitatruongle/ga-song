import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart' hide WindowCaptionButton;
import '../../core/service_locator.dart';
import '../../core/settings_manager.dart';
import '../../core/theme_utils.dart';
import '../../core/view_models/player_view_model.dart';
import '../../core/pip_service.dart';
import '../widgets/cover_art_image.dart';

/// Whether the current platform is desktop (Windows/macOS/Linux).
bool get _isDesktopPlatform =>
    !kIsWeb &&
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

class MiniPlayerScreen extends StatelessWidget {
  const MiniPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (_isDesktopPlatform) {
      return const _DesktopMiniPlayer();
    }
    // On Android in PiP mode, use a compact layout that fits the tiny window
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return ValueListenableBuilder<bool>(
        valueListenable: sl<PipService>().isInPipNotifier,
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

class _DesktopMiniPlayer extends StatelessWidget {
  const _DesktopMiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: sl<PlayerViewModel>(),
        builder: (context, _) {
          final viewModel = sl<PlayerViewModel>();
          final song = viewModel.currentSong;

          return Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    if (song != null) {
                      const maxCacheSize = 256;
                      final mediaSize = MediaQuery.sizeOf(context);
                      final pixelRatio =
                          MediaQuery.devicePixelRatioOf(context);
                      final cacheWidth = (mediaSize.width * pixelRatio)
                          .clamp(1, maxCacheSize)
                          .round();
                      final cacheHeight = (mediaSize.height * pixelRatio)
                          .clamp(1, maxCacheSize)
                          .round();
                      return CoverArtImage(
                        fileName: song.fileName,
                        cacheWidth: cacheWidth,
                        cacheHeight: cacheHeight,
                        fallbackBuilder: (context) =>
                            Container(color: const Color(0xFF0F0F0F)),
                      );
                    }
                    return Container(color: const Color(0xFF0F0F0F));
                  },
                ),
              ),

              // Blur overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.4)),
                  ),
                ),
              ),

              // Drag Window Area (desktop only)
              const Positioned.fill(
                child: DragToMoveArea(child: SizedBox.expand()),
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
                          margin: const EdgeInsets.all(12),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CoverArtImage(
                            fileName: song.fileName,
                            cacheWidth: 112,
                            cacheHeight: 112,
                            fallbackBuilder: (context) => DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .cardColor
                                    .withValues(alpha: 0.16),
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

                        // Info
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
                                size: 24,
                              ),
                              color: textColor,
                              onPressed: viewModel.previous,
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: textColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  viewModel.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  size: 20,
                                ),
                                onPressed: viewModel.togglePlayPause,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 24,
                              ),
                              color: textColor,
                              onPressed: viewModel.next,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_full_rounded,
                                size: 20,
                              ),
                              color: textColor.withValues(alpha: 0.6),
                              tooltip: 'Trở lại bình thường',
                              onPressed: () async {
                                sl<SettingsManager>().setIsMiniPlayer(false);
                                // First unlock the size constraints (mini player locks them)
                                await windowManager.setMinimumSize(
                                  const Size(800, 600),
                                );
                                await windowManager.setMaximumSize(
                                  const Size(32000, 32000), // effectively no limit
                                );
                                final savedSize =
                                    sl<SettingsManager>().savedWindowSize;
                                if (savedSize != null) {
                                  await windowManager.setSize(savedSize);
                                } else {
                                  await windowManager.setSize(
                                    const Size(1000, 700),
                                  );
                                }
                                if (sl<SettingsManager>().savedWindowMaximized) {
                                  await windowManager.maximize();
                                }
                                if (sl<SettingsManager>().savedWindowFullScreen) {
                                  await windowManager.setFullScreen(true);
                                }
                                await windowManager.setAlwaysOnTop(false);
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile: full-screen immersive mini player
// ─────────────────────────────────────────────────────────────────────────────

class _MobileMiniPlayer extends StatelessWidget {
  const _MobileMiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: sl<PlayerViewModel>(),
        builder: (context, _) {
          final viewModel = sl<PlayerViewModel>();
          final song = viewModel.currentSong;

          return Stack(
            children: [
              // Background — blurred cover art
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    if (song != null) {
                      return CoverArtImage(
                        fileName: song.fileName,
                        cacheWidth: 256,
                        cacheHeight: 256,
                        fallbackBuilder: (context) =>
                            Container(color: const Color(0xFF0F0F0F)),
                      );
                    }
                    return Container(color: const Color(0xFF0F0F0F));
                  },
                ),
              ),

              // Blur + dark scrim
              Positioned.fill(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ),
              ),

              // Content
              SafeArea(
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
                    : _MobileMiniPlayerContent(
                        song: song,
                        viewModel: viewModel,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileMiniPlayerContent extends StatelessWidget {
  const _MobileMiniPlayerContent({
    required this.song,
    required this.viewModel,
  });

  final dynamic song;
  final PlayerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;

    return Column(
      children: [
        // Top bar — back / expand button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: textColor, size: 32),
                tooltip: 'Trở lại bình thường',
                onPressed: () {
                  sl<SettingsManager>().setIsMiniPlayer(false);
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
                    fileName: song.fileName,
                    cacheWidth: 512,
                    cacheHeight: 512,
                    fallbackBuilder: (context) => Container(
                      color: Theme.of(context)
                          .cardColor
                          .withValues(alpha: 0.16),
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
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              viewModel.positionNotifier,
              viewModel.durationNotifier,
            ]),
            builder: (context, _) {
              final position = viewModel.position;
              final duration = viewModel.duration;
              final progress = viewModel.progress;

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
                      inactiveTrackColor:
                          textColor.withValues(alpha: 0.2),
                      thumbColor: textColor,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds:
                              (value * duration.inMilliseconds).round(),
                        );
                        viewModel.seek(newPosition);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
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
                icon: Icon(Icons.skip_previous_rounded,
                    size: 40, color: textColor),
                onPressed: viewModel.previous,
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
                    viewModel.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    size: 36,
                  ),
                  onPressed: viewModel.togglePlayPause,
                ),
              ),
              IconButton(
                icon: Icon(Icons.skip_next_rounded,
                    size: 40, color: textColor),
                onPressed: viewModel.next,
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Android PiP: ultra-compact layout (cover art + play/pause only)
// ─────────────────────────────────────────────────────────────────────────────

class _PipCompactPlayer extends StatelessWidget {
  const _PipCompactPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: sl<PlayerViewModel>(),
        builder: (context, _) {
          final viewModel = sl<PlayerViewModel>();
          final song = viewModel.currentSong;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed cover art background
              if (song != null)
                CoverArtImage(
                  fileName: song.fileName,
                  cacheWidth: 256,
                  cacheHeight: 144,
                  fallbackBuilder: (context) =>
                      Container(color: const Color(0xFF1A1A1A)),
                )
              else
                Container(color: const Color(0xFF1A1A1A)),

              // Dark scrim for readability
              Container(color: Colors.black.withValues(alpha: 0.35)),

              // Centered play/pause button
              Center(
                child: GestureDetector(
                  onTap: viewModel.togglePlayPause,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      viewModel.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 28,
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
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
