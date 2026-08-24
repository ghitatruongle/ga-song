import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/playlist_service.dart';
import '../../providers/service_providers.dart';
import '../../core/audio/audio_engine_service.dart';
import '../widgets/cover_art_image.dart';
import '../widgets/lyric_view.dart';
import '../../core/logging/app_logger.dart';

class IOSFullscreenPlayerScreen extends ConsumerStatefulWidget {
  const IOSFullscreenPlayerScreen({super.key});

  /// Opens the fullscreen player as a full-screen page route.
  static Future<void> show(final BuildContext context) async {
    AppLogger.i(
      'IOSFullscreenPlayerScreen',
      'show() called, context mounted=${context.mounted}',
    );
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (final _) {
            AppLogger.i('IOSFullscreenPlayerScreen', 'builder() called');
            return const IOSFullscreenPlayerScreen();
          },
        ),
      );
      AppLogger.i('IOSFullscreenPlayerScreen', 'push completed normally');
    } catch (e, st) {
      AppLogger.e('IOSFullscreenPlayerScreen', 'push ERROR: $e\n$st');
    }
  }

  @override
  ConsumerState<IOSFullscreenPlayerScreen> createState() =>
      _IOSFullscreenPlayerScreenState();
}

class _IOSFullscreenPlayerScreenState
    extends ConsumerState<IOSFullscreenPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showLyrics = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(final Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(final BuildContext context) {
    final playlistService = ref.watch(playlistServiceProvider);
    final engineService = ref.watch(audioEngineServiceProvider);
    final currentSong = playlistService.currentSong;
    final isAndroid = !kIsWeb && Platform.isAndroid;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.chevron_down,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.music_note,
                        size: 64,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa chọn bài hát',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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

    return ValueListenableBuilder(
      valueListenable: engineService.engineState,
      builder: (final context, final state, _) {
        final isPlaying = state == AudioEngineState.playing;
        if (isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!isPlaying && _rotationController.isAnimating) {
          _rotationController.stop();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: CoverArtImage(
                  song: currentSong,
                  fallbackBuilder: (_) => Container(color: Colors.grey[900]),
                ),
              ),
              Positioned.fill(
                child: isAndroid
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xF018181B),
                              Color(0xF009090B),
                              Colors.black,
                            ],
                          ),
                        ),
                      )
                    // Use ImageFiltered instead of BackdropFilter for performance:
                    // BackdropFilter re-blurs every pixel every frame (GPU killer on ProMotion).
                    // ImageFiltered blurs only its child; result is cached by compositor.
                    : ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.chevron_down,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          SegmentedButton<bool>(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (final states) =>
                                    states.contains(WidgetState.selected)
                                    ? const Color(0xFF1DB954)
                                    : Colors.white10,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.white,
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Bài hát'),
                                icon: Icon(CupertinoIcons.music_note, size: 16),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Lời hát'),
                                icon: Icon(
                                  CupertinoIcons.quote_bubble,
                                  size: 16,
                                ),
                              ),
                            ],
                            selected: {_showLyrics},
                            onSelectionChanged: (final set) {
                              HapticFeedback.selectionClick();
                              setState(() => _showLyrics = set.first);
                            },
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _showLyrics
                            ? const LyricView()
                            : Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    RotationTransition(
                                      turns: _rotationController,
                                      child: Container(
                                        width: 260,
                                        height: 260,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(
                                            alpha: 0.85,
                                          ),
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              blurRadius: 25,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: CoverArtImage(
                                            song: currentSong,
                                            fallbackBuilder: (_) => const Icon(
                                              Icons.music_note,
                                              size: 80,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black,
                                        border: Border.all(
                                          color: Colors.white38,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.artist ?? 'Ca sĩ chưa rõ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<Duration>(
                        valueListenable: engineService.positionNotifier,
                        builder: (final context, final position, _) {
                          final duration = engineService.durationNotifier.value;
                          final maxSeconds = duration.inSeconds > 0
                              ? duration.inSeconds.toDouble()
                              : 1.0;
                          final currentSeconds = position.inSeconds
                              .toDouble()
                              .clamp(0.0, maxSeconds);

                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF1DB954),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: currentSeconds,
                                  max: maxSeconds,
                                  onChanged: (final val) {
                                    engineService.seek(
                                      Duration(seconds: val.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (final context) {
                          final playMode = ref.watch(playModeProvider);
                          final isShuffle = playMode == PlayMode.shuffle;
                          final isRepeatOne = playMode == PlayMode.repeatOne;
                          final isRepeatAll = playMode == PlayMode.sequential;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.shuffle,
                                  color: isShuffle
                                      ? const Color(0xFF1DB954)
                                      : Colors.white60,
                                  size: 24,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  if (isShuffle) {
                                    playlistService.setPlayMode(
                                      PlayMode.sequential,
                                    );
                                  } else {
                                    playlistService.setPlayMode(
                                      PlayMode.shuffle,
                                    );
                                  }
                                },
                                tooltip: 'Phát ngẫu nhiên',
                              ),
                              IconButton(
                                icon: const Icon(
                                  CupertinoIcons.backward_fill,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  playlistService.previous();
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? CupertinoIcons.pause_circle_fill
                                      : CupertinoIcons.play_circle_fill,
                                  color: const Color(0xFF1DB954),
                                  size: 64,
                                ),
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  if (isPlaying) {
                                    engineService.pause();
                                  } else {
                                    playlistService.play();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  CupertinoIcons.forward_fill,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  playlistService.next();
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isRepeatOne
                                      ? CupertinoIcons.repeat_1
                                      : CupertinoIcons.repeat,
                                  color: (isRepeatOne || isRepeatAll)
                                      ? const Color(0xFF1DB954)
                                      : Colors.white60,
                                  size: 24,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  playlistService.nextPlayMode();
                                },
                                tooltip: 'Chế độ lặp lại',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
