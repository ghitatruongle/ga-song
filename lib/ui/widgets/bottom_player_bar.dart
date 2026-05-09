
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';


import '../../core/audio/audio_effect_service.dart';
import '../../core/audio/playlist_service.dart';
import '../../core/service_locator.dart';
import '../../core/settings_manager.dart';
import '../../core/theme_utils.dart';
import '../../song_model.dart';
import '../../core/view_models/player_view_model.dart';
import '../../core/pip_service.dart';

import 'cover_art_image.dart';
import 'equalizer_widget.dart';
import 'sleep_timer_dialog.dart';

class BottomPlayerBarWidget extends StatelessWidget {
  const BottomPlayerBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<PlayerViewModel>(),
      builder: (context, _) {
        final song = sl<PlayerViewModel>().currentSong;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          height: 84,
          decoration: BoxDecoration(
            color: context.adaptive.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.adaptive.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: song == null
                  ? Center(
                      child: Text(
                        'Chưa chọn bài hát',
                        style: TextStyle(
                          color: context.adaptive.withValues(alpha: 0.4),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _SongInfo(song: song),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: const RepaintBoundary(
                      child: _CenterControls(),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: const RepaintBoundary(
                      child: _RightControls(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: context.adaptive.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CoverArtImage(
            fileName: song.fileName,
            cacheWidth: 104,
            cacheHeight: 104,
            fallbackBuilder: (context) =>
                Icon(Icons.music_note, color: context.adaptiveSubtle, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                song.name,
                style: TextStyle(
                  color: context.adaptive,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                song.artist ?? 'Unknown Artist',
                style: TextStyle(
                  color: context.adaptive.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<PlayerViewModel>(),
      builder: (context, _) {
        final viewModel = sl<PlayerViewModel>();
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const _PlayModeButton(),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: context.adaptive,
                      size: 32,
                    ),
                    onPressed: viewModel.previous,
                    hoverColor: context.adaptive.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.adaptive,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        viewModel.isLoading
                            ? Icons.hourglass_empty
                            : viewModel.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: context.onAdaptive,
                        size: 28,
                      ),
                      onPressed: viewModel.isLoading
                          ? null
                          : viewModel.togglePlayPause,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: context.adaptive,
                      size: 32,
                    ),
                    onPressed: viewModel.next,
                    hoverColor: context.adaptive.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 16),
                  const _BassButton(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const _ProgressBar(),
          ],
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = sl<PlayerViewModel>();
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        viewModel.positionNotifier,
        viewModel.durationNotifier,
      ]),
      builder: (context, _) {
        final position = viewModel.position;
        final duration = viewModel.duration;
        final progress = viewModel.progress;

        return Row(
          children: <Widget>[
            SizedBox(
              width: 36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: context.adaptive.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 12,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: context.adaptive,
                    inactiveTrackColor: context.adaptive.withValues(alpha: 0.2),
                    thumbColor: context.adaptive,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).round(),
                      );
                      viewModel.seek(newPosition);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: context.adaptive.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RightControls extends StatelessWidget {
  const _RightControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.picture_in_picture_alt_rounded,
            color: context.adaptiveSecondary,
            size: 22,
          ),
          tooltip: 'Trình phát thu nhỏ (Mini Player)',
          onPressed: () async {
            // Android: use native Picture-in-Picture
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              await sl<PipService>().enterPip();
              return;
            }
            // Desktop: use in-app mini player
            sl<SettingsManager>().setIsMiniPlayer(true);
            if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
              // Save current window size/state before entering mini player (desktop only)
              final isMaximized = await windowManager.isMaximized();
              final isFullScreen = await windowManager.isFullScreen();
              if (isFullScreen) {
                await windowManager.setFullScreen(false);
                // Small delay to let the OS fully exit fullscreen before resizing
                await Future<void>.delayed(const Duration(milliseconds: 200));
              } else if (isMaximized) {
                await windowManager.unmaximize();
                await Future<void>.delayed(const Duration(milliseconds: 100));
              }
              final currentSize = await windowManager.getSize();
              await sl<SettingsManager>().setSavedWindowState(currentSize, isMaximized, isFullScreen);
              // Lock to exactly the mini player dimensions (prevent resizing/distortion)
              await windowManager.setMinimumSize(const Size(350, 100));
              await windowManager.setMaximumSize(const Size(350, 100));
              await windowManager.setSize(const Size(350, 100));
              await windowManager.setAlwaysOnTop(true);
            }
          },
        ),
        const Expanded(child: _VolumeControl()),
      ],
    );
  }
}

class _VolumeControl extends StatefulWidget {
  const _VolumeControl();

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  // E2 fix: Store previous volume before muting so we can restore it later
  double _previousVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<PlayerViewModel>(),
      builder: (context, _) {
        final viewModel = sl<PlayerViewModel>();
        final volume = viewModel.volume;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: Icon(
                volume == 0
                    ? Icons.volume_off_rounded
                    : volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
                color: context.adaptiveSecondary,
                size: 22,
              ),
              onPressed: () {
                if (volume > 0) {
                  _previousVolume = volume;
                  viewModel.setVolume(0.0);
                } else {
                  viewModel.setVolume(_previousVolume > 0 ? _previousVolume : 1.0);
                }
              },
            ),
            Flexible(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                  activeTrackColor: context.adaptive,
                  inactiveTrackColor: context.adaptive.withValues(alpha: 0.2),
                  thumbColor: context.adaptive,
                ),
                child: Slider(
                  value: volume,
                  onChanged: viewModel.setVolume,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayModeButton extends StatelessWidget {
  const _PlayModeButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<PlayerViewModel>(),
      builder: (context, _) {
        final viewModel = sl<PlayerViewModel>();
        final playMode = viewModel.playMode;
        
        var icon = Icons.repeat_rounded;
        var color = context.adaptiveSecondary;

        switch (playMode) {
          case PlayMode.sequential:
            icon = Icons.repeat_rounded;
            break;
          case PlayMode.repeatOne:
            icon = Icons.repeat_one_rounded;
            color = context.adaptive;
            break;
          case PlayMode.playOneStop:
            icon = Icons.looks_one_rounded;
            break;
          case PlayMode.shuffle:
            icon = Icons.shuffle_rounded;
            color = context.adaptive;
            break;
        }

        return IconButton(
          icon: Icon(icon, color: color, size: 22),
          onPressed: viewModel.togglePlayMode,
          tooltip: 'Chế độ phát',
        );
      },
    );
  }
}

class _BassButton extends StatelessWidget {
  const _BassButton();

  @override
  Widget build(BuildContext context) {
    final effectService = sl<AudioEffectService>();
    final playlistService = sl<PlaylistService>();
    return ValueListenableBuilder<int>(
      valueListenable: effectService.bassLevelNotifier,
      builder: (context, bassLevel, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: bassLevel > 0
                ? context.adaptive.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: bassLevel > 0
                      ? context.adaptive
                      : context.adaptiveSecondary,
                  size: 22,
                ),
                onPressed: () => EqualizerWidget.show(context),
                tooltip: 'Equalizer',
              ),
              ValueListenableBuilder<Duration?>(
                valueListenable: playlistService.sleepTimerRemainingNotifier,
                builder: (context, remaining, _) {
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.timer_outlined,
                          size: 22,
                        ),
                        color: remaining != null
                            ? Theme.of(context).primaryColor
                            : context.adaptive.withValues(alpha: 0.7),
                        tooltip: 'Sleep Timer',
                        onPressed: () => SleepTimerDialog.show(context),
                      ),
                      if (remaining != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
