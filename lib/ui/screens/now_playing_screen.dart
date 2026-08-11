import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../providers/lyric_provider.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../core/audio/playlist_service.dart';
import '../../core/theme_utils.dart';
import '../../core/theme/tokens.dart';
import '../../core/motion/app_motion.dart';
import '../../models/song.dart';
import '../../ui/utils/haptic_helper.dart';
import '../utils/theme_helpers.dart';
import '../widgets/cover_art_image.dart';
import '../widgets/queue_management.dart';

/// Full-screen "Now Playing" view — the Spotify signature interaction.
///
/// Opens via swipe-up or tap on the bottom player bar's cover art.
/// Dismisses via swipe-down or system back gesture.
///
/// Features:
/// - Blurred cover art background with dark scrim
/// - Large cover art with vinyl rotation animation when playing
/// - Song title + artist with gradient accent
/// - Seekable progress slider
/// - Playback controls (prev, play/pause, next, shuffle, repeat)
/// - Volume slider
/// - Like/favorite button
/// - Lyrics overlay toggle
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _startRotationIfPlaying();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _startRotationIfPlaying() {
    final isPlaying = ref.read(engineStateProvider) == AudioEngineState.playing;
    if (isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final playlist = ref.watch(playlistServiceProvider);
    final index = ref.watch(currentPlayingIndexProvider);
    final song = (index >= 0 && index < playlist.playlist.length)
        ? playlist.playlist[index]
        : null;
    final isPlaying =
        ref.watch(engineStateProvider) == AudioEngineState.playing;
    final isDark = context.isDark;
    final position = ref.watch(positionProvider);
    final duration = ref.watch(trackDurationProvider);
    final playMode = ref.watch(playModeProvider);
    final isShuffle = playMode == PlayMode.shuffle;
    final isRepeatOne = playMode == PlayMode.repeatOne;
    final isFavorite = song?.isFavorite ?? false;

    // Listen for playback state changes to control rotation
    ref.listen<AudioEngineState>(engineStateProvider, (_, final next) {
      if (next == AudioEngineState.playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    if (song == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 64,
                color: context.adaptive.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa chọn bài hát',
                style: TextStyle(
                  color: context.adaptive.withValues(alpha: 0.5),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Blurred cover art background
          Positioned.fill(
            child: RepaintBoundary(
              child: CoverArtImage(
                song: song,
                cacheWidth: 400,
                cacheHeight: 400,
                fallbackBuilder: (final context) => Container(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // 2. Swipe-down dismiss gesture — only from top area to avoid
          // conflicting with scrollable content (lyrics, queue, etc.)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: GestureDetector(
              onVerticalDragUpdate: (final details) {
                if (details.delta.dy > 0) {
                  setState(() => _dragOffset += details.delta.dy);
                }
              },
              onVerticalDragEnd: (final details) {
                if (_dragOffset > 80 ||
                    (details.primaryVelocity != null &&
                        details.primaryVelocity! > 400)) {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                }
                setState(() => _dragOffset = 0.0);
              },
              child: AnimatedContainer(
                duration: AppDurations.short,
                curve: AppCurves.decelerate,
                transform: Matrix4.translationValues(0, _dragOffset * 0.3, 0),
                child: _TopBar(isDark: isDark),
              ),
            ),
          ),

          // 3. Main content — SafeArea handles notches, Column centers content
          SafeArea(
            child: Column(
              children: [
                // Spacer replaces the top bar (which is in the swipe-down gesture above)
                const SizedBox(height: 8),

                // Main centered content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large cover art with vinyl rotation
                      _CoverArtWithRotation(
                        song: song,
                        isPlaying: isPlaying,
                        rotationController: _rotationController,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Song info
                      _SongInfo(song: song, isDark: isDark),

                      const SizedBox(height: 24),

                      // Progress bar
                      _ProgressBar(
                        position: position,
                        duration: duration,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Playback controls
                      _PlaybackControls(
                        isPlaying: isPlaying,
                        isShuffle: isShuffle,
                        isRepeatOne: isRepeatOne,
                        isDark: isDark,
                        isFavorite: isFavorite,
                        songId: song.id,
                      ),

                      const SizedBox(height: 24),

                      // Volume slider
                      _VolumeSlider(isDark: isDark),

                      const SizedBox(height: 16),

                      // Lyrics toggle
                      _LyricsToggle(isDark: isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isDark;
  const _TopBar({required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final textColor = context.adaptive;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ThemeSpacing.of(context).md,
        vertical: ThemeSpacing.of(context).sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textColor,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Thu nhỏ',
          ),
          Expanded(
            child: Text(
              'Đang phát',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textColor, size: 24),
            onPressed: () {
              // TODO: Show options menu (add to playlist, view album, etc.)
            },
          ),
        ],
      ),
    );
  }
}

// ─── Cover Art with Rotation ────────────────────────────────────────────────

class _CoverArtWithRotation extends ConsumerWidget {
  final Song song;
  final bool isPlaying;
  final AnimationController rotationController;
  final bool isDark;

  const _CoverArtWithRotation({
    required this.song,
    required this.isPlaying,
    required this.rotationController,
    required this.isDark,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      AnimatedBuilder(
        animation: rotationController,
        builder: (final context, final child) {
          final rotation = rotationController.value * 2 * pi;
          return Transform.rotate(
            angle: rotation,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CoverArtImage(
                  song: song,
                  cacheWidth: 560,
                  cacheHeight: 560,
                  fallbackBuilder: (final context) => ColoredBox(
                    color: isDark
                        ? AppColors.darkSurface2
                        : AppColors.lightSurface2,
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 64,
                      color: context.adaptive.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

// ─── Song Info ──────────────────────────────────────────────────────────────

class _SongInfo extends StatelessWidget {
  final Song song;
  final bool isDark;
  const _SongInfo({required this.song, required this.isDark});

  @override
  Widget build(final BuildContext context) {
    final textColor = context.adaptive;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ThemeSpacing.of(context).xl),
      child: Column(
        children: [
          // Song title with gradient accent
          ShaderMask(
            shaderCallback: (final bounds) => LinearGradient(
              colors: [accentColor, textColor],
              stops: const [0.0, 0.7],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              song.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            song.artist ?? 'Unknown Artist',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Progress Bar ───────────────────────────────────────────────────────────

class _ProgressBar extends ConsumerWidget {
  final Duration position;
  final Duration duration;
  final bool isDark;
  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.isDark,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final textColor = context.adaptive.withValues(alpha: 0.5);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ThemeSpacing.of(context).xl),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: accentColor,
              inactiveTrackColor: textColor,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (final value) {
                final seekPosition = duration * value;
                ref.read(audioEngineServiceProvider).seek(seekPosition);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeSpacing.of(context).md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(position),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(final Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ─── Playback Controls ──────────────────────────────────────────────────────

class _PlaybackControls extends ConsumerWidget {
  final bool isPlaying;
  final bool isShuffle;
  final bool isRepeatOne;
  final bool isDark;
  final bool isFavorite;
  final int? songId;

  const _PlaybackControls({
    required this.isPlaying,
    required this.isShuffle,
    required this.isRepeatOne,
    required this.isDark,
    required this.isFavorite,
    this.songId,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final playlist = ref.read(playlistServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        _ControlIcon(
          icon: isShuffle ? Icons.shuffle_rounded : Icons.shuffle_rounded,
          isActive: isShuffle,
          onTap: () {
            safeHaptic(HapticType.light);
            playlist.setPlayMode(
              isShuffle ? PlayMode.sequential : PlayMode.shuffle,
            );
          },
          isDark: isDark,
        ),

        // Previous
        _ControlIcon(
          icon: Icons.skip_previous_rounded,
          size: 36,
          onTap: () {
            safeHaptic(HapticType.light);
            playlist.previous();
          },
          isDark: isDark,
        ),

        // Play/Pause — toggling: playing → pause, paused → resume/play.
        // Calling playlist.play() while playing RESTARTS the song instead.
        GestureDetector(
          onTap: () {
            safeHaptic(HapticType.medium);
            final engine = ref.read(audioEngineServiceProvider);
            if (engine.engineState.value == AudioEngineState.playing) {
              engine.pause();
            } else {
              playlist.play();
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isDark ? Colors.black : Colors.white,
              size: 36,
            ),
          ),
        ),

        // Next
        _ControlIcon(
          icon: Icons.skip_next_rounded,
          size: 36,
          onTap: () {
            safeHaptic(HapticType.light);
            playlist.next();
          },
          isDark: isDark,
        ),

        // Queue
        _ControlIcon(
          icon: Icons.queue_music_rounded,
          onTap: () {
            safeHaptic(HapticType.light);
            _showQueueSheet(context);
          },
          isDark: isDark,
        ),

        // Repeat
        _ControlIcon(
          icon: isRepeatOne ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          isActive: isRepeatOne,
          onTap: () {
            safeHaptic(HapticType.light);
            if (isRepeatOne) {
              playlist.setPlayMode(PlayMode.sequential);
            } else {
              playlist.setPlayMode(PlayMode.repeatOne);
            }
          },
          isDark: isDark,
        ),
      ],
    );
  }

  void _showQueueSheet(final BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final context) => const QueueManagementSheet(),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _ControlIcon({
    required this.icon,
    this.size = 28,
    this.isActive = false,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(final BuildContext context) {
    final textColor = context.adaptive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: isActive
              ? textColor.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ─── Volume Slider ──────────────────────────────────────────────────────────

class _VolumeSlider extends ConsumerWidget {
  final bool isDark;
  const _VolumeSlider({required this.isDark});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final volume = ref.watch(volumeProvider);
    final textColor = context.adaptive.withValues(alpha: 0.5);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ThemeSpacing.of(context).xl),
      child: Row(
        children: [
          Icon(
            volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: accentColor,
                inactiveTrackColor: textColor,
                thumbColor: accentColor,
              ),
              child: Slider(
                value: volume,
                onChanged: (final value) {
                  ref.read(audioEngineServiceProvider).setVolume(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              '${(volume * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lyrics Toggle ──────────────────────────────────────────────────────────

class _LyricsToggle extends ConsumerWidget {
  final bool isDark;
  const _LyricsToggle({required this.isDark});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final showLyrics = ref.watch(lyricVisibilityProvider);
    final textColor = context.adaptive.withValues(alpha: 0.5);
    final accentColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        ref.read(lyricVisibilityProvider.notifier).toggle();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ThemeSpacing.of(context).lg,
          vertical: ThemeSpacing.of(context).sm,
        ),
        decoration: BoxDecoration(
          color: showLyrics
              ? accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ThemeRadius.of(context).xl),
          border: Border.all(
            color: showLyrics ? accentColor.withValues(alpha: 0.3) : textColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_rounded,
              size: 18,
              color: showLyrics ? accentColor : textColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Lời bài hát',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: showLyrics ? accentColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
