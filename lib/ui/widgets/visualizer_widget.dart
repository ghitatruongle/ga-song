import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart' hide WindowCaptionButton;

import '../../core/audio/audio_engine_service.dart';
import '../../core/audio/playlist_service.dart';
import '../../core/performance_probe.dart';
import '../../core/service_locator.dart';
import '../../core/settings_manager.dart';
import '../../core/theme_utils.dart';
import '../painters/visualizer_painters.dart';
import '../visualizer/visualizer_controller.dart';
import 'cover_art_image.dart';

import 'window_caption_button.dart';

class PersonalVisualizerWidget extends StatefulWidget {
  const PersonalVisualizerWidget({super.key});

  @override
  State<PersonalVisualizerWidget> createState() =>
      _PersonalVisualizerWidgetState();
}

class _PersonalVisualizerWidgetState extends State<PersonalVisualizerWidget>
    with TickerProviderStateMixin {
  final PlaylistService _playlistService = sl<PlaylistService>();
  final AudioEngineService _engineService = sl<AudioEngineService>();
  final SettingsManager _settings = sl<SettingsManager>();

  late final VisualizerController _visualizerController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _visualizerController = VisualizerController(vsync: this)
      ..addListener(_syncRotationState);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _syncRotationState();
  }

  @override
  void dispose() {
    _visualizerController.removeListener(_syncRotationState);
    _visualizerController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _syncRotationState() {
    if (_visualizerController.isAudioReactive) {
      if (!_rotateController.isAnimating) {
        _rotateController.repeat();
      }
      return;
    }

    if (_rotateController.isAnimating) {
      _rotateController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    PerformanceProbe.instance.markSurface('Personal Visualizer');
    final textColor = context.adaptive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        _visualizerController.updateSize(containerSize);

        return ColoredBox(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<Color?>(
                    valueListenable: _settings.dynamicPrimaryColorNotifier,
                    builder: (context, color, _) {
                      final resolvedColor =
                          (!_settings.useDynamicColorNotifier.value ||
                              color == null)
                          ? Theme.of(context).primaryColor
                          : color;
                      return CustomPaint(
                        painter: AmbientGlowPainter(
                          controller: _visualizerController,
                          color: resolvedColor,
                        ),
                        isComplex: true,
                        willChange: true,
                      );
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ParticlePainter(
                      controller: _visualizerController,
                    ),
                    isComplex: true,
                    willChange: true,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _visualizerController,
                    builder: (context, _) {
                      final isBeat = _visualizerController.snapshot.isBeat;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: isBeat ? 50 : 200),
                        color: Colors.white.withValues(alpha: isBeat ? 0.15 : 0.0),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RepaintBoundary(child: _buildTitleBar(textColor)),
                    RepaintBoundary(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _playlistService.currentIndexNotifier,
                        builder: (context, _, _) {
                          final song = _playlistService.currentSong;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                song?.name ?? 'Phòng nghe nhạc cá nhân',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  height: 1.1,
                                  letterSpacing: -1.5,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: textColor.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song?.artist ??
                                    'Hiệu ứng âm thanh theo nhịp điệu',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      child: _buildControlsRow(context, textColor),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  _settings.visualizerShapeNotifier,
                              builder: (context, shape, _) {
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: RepaintBoundary(
                                    key: ValueKey<int>(shape),
                                    child: _buildVisualizerForShape(
                                      shape,
                                      containerSize,
                                    ),
                                  ),
                                );
                              },
                            ),
                            RepaintBoundary(
                              child: _buildAlbumArtOverlay(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleBar(Color textColor) {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return const SizedBox(height: 50);
    }
    return DragToMoveArea(
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              WindowCaptionButton.minimize(
                onPressed: () async => windowManager.minimize(),
                iconNormal: Icon(Icons.remove, color: textColor, size: 20),
              ),
              const SizedBox(width: 8),
              WindowCaptionButton.maximize(
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                iconNormal: Icon(Icons.crop_square, color: textColor, size: 18),
              ),
              const SizedBox(width: 8),
              WindowCaptionButton.close(
                onPressed: () async => windowManager.close(),
                iconNormal: Icon(Icons.close, color: textColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArtOverlay(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _playlistService.currentIndexNotifier,
      builder: (context, _, _) {
        final song = _playlistService.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<int>(
          valueListenable: _settings.visualizerShapeNotifier,
          builder: (context, shape, _) {
            if (shape == 1) {
              return const SizedBox.shrink();
            }

            final imageSize = shape == 2 ? 140.0 : (shape == 3 ? 120.0 : 220.0);
            return AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _rotateController,
                _visualizerController,
              ]),
              builder: (context, child) {
                final scale =
                    1.0 +
                    (_visualizerController.snapshot.smoothEnergy * 0.15).clamp(
                      0.0,
                      0.2,
                    );
                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: _rotateController.value * 2 * pi,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.6),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CoverArtImage(
                  fileName: song.fileName,
                  cacheWidth: imageSize.round() * 2,
                  cacheHeight: imageSize.round() * 2,
                  fallbackBuilder: (context) => DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.18),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: context.adaptive.withValues(alpha: 0.75),
                      size: imageSize * 0.32,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisualizerForShape(int shape, Size containerSize) {
    final availableWidth = containerSize.width;
    final availableHeight = containerSize.height;

    switch (shape) {
      case 1:
        final barsWidth = availableWidth;
        final barsHeight = min(availableHeight, 400.0);
        final paintHeight = min(barsHeight * 0.5, 200.0);
        return SizedBox(
          width: barsWidth,
          height: barsHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(barsWidth, paintHeight),
              painter: BarVisualizerPainter(controller: _visualizerController),
              isComplex: true,
              willChange: true,
            ),
          ),
        );
      case 2:
        final waveWidth = availableWidth;
        final waveHeight = min(availableHeight, 400.0);
        final paintHeight = min(waveHeight * 0.75, 300.0);
        return SizedBox(
          width: waveWidth,
          height: waveHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(waveWidth, paintHeight),
              painter: WaveVisualizerPainter(controller: _visualizerController),
              isComplex: true,
              willChange: true,
            ),
          ),
        );
      case 3:
        final tunnelDim = min(availableWidth, availableHeight) * 0.85;
        return SizedBox(
          width: tunnelDim,
          height: tunnelDim,
          child: CustomPaint(
            size: Size(tunnelDim, tunnelDim),
            painter: SpectrumTunnelPainter(controller: _visualizerController),
            isComplex: true,
            willChange: true,
          ),
        );
      case 4:
        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: CustomPaint(
            size: Size(availableWidth, availableHeight),
            painter: StarfieldPainter(controller: _visualizerController),
            isComplex: true,
            willChange: true,
          ),
        );
      case 5:
        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: CustomPaint(
            size: Size(availableWidth, availableHeight),
            painter: OscilloscopePainter(controller: _visualizerController),
            isComplex: true,
            willChange: true,
          ),
        );
      case 6:
        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: CustomPaint(
            size: Size(availableWidth, availableHeight),
            painter: RadialBurstPainter(controller: _visualizerController),
            isComplex: true,
            willChange: true,
          ),
        );
      default:
        final circleDim = min(min(availableWidth, availableHeight), 450.0);
        return CustomPaint(
          size: Size(circleDim, circleDim),
          painter: CircleVisualizerPainter(controller: _visualizerController),
          isComplex: true,
          willChange: true,
        );
    }
  }

  Widget _buildControlsRow(BuildContext context, Color textColor) {
    // B2 fix: Removed BackdropFilter — was re-rendering blur every frame
    // at 60fps on top of CustomPaint. Using opaque container instead.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Style: ',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<int>(
              valueListenable: _settings.visualizerShapeNotifier,
              builder: (context, shape, _) {
                return ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  fillColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.3),
                  selectedColor: Colors.white,
                  color: textColor.withValues(alpha: 0.6),
                  borderColor: Colors.transparent,
                  selectedBorderColor: Colors.transparent,
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 44,
                  ),
                  isSelected: <bool>[
                    shape == 0,
                    shape == 1,
                    shape == 2,
                    shape == 3,
                    shape == 4,
                    shape == 5,
                    shape == 6,
                  ],
                  onPressed: _settings.setVisualizerShape,
                  children: const <Widget>[
                    Tooltip(
                      message: 'Vòng đĩa xoay',
                      child: Icon(Icons.data_usage_rounded, size: 18),
                    ),
                    Tooltip(
                      message: 'Cột Neon',
                      child: Icon(Icons.bar_chart_rounded, size: 18),
                    ),
                    Tooltip(
                      message: 'Sóng Đại Dương',
                      child: Icon(Icons.water_rounded, size: 18),
                    ),
                    Tooltip(
                      message: 'Đường hầm Phổ',
                      child: Icon(Icons.blur_circular_rounded, size: 18),
                    ),
                    Tooltip(
                      message: 'Bầu trời Sao',
                      child: Icon(Icons.auto_awesome_rounded, size: 18),
                    ),
                    Tooltip(
                      message: 'Máy hiện sóng',
                      child: Icon(Icons.show_chart, size: 18),
                    ),
                    Tooltip(
                      message: 'Tia Sáng',
                      child: Icon(Icons.flare, size: 18),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 20),
            Container(
              width: 1,
              height: 30,
              color: textColor.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 16),
            Icon(Icons.tune, color: textColor.withValues(alpha: 0.6), size: 16),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              child: ValueListenableBuilder<double>(
                valueListenable: _settings.sensitivityNotifier,
                builder: (context, value, _) => Slider(
                  value: value,
                  min: 0.3,
                  max: 2.5,
                  divisions: 22,
                  label: '${(value * 100).round()}%',
                  onChanged: _settings.setSensitivity,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 1,
              height: 30,
              color: textColor.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 16),
            ValueListenableBuilder<AudioEngineState>(
              valueListenable: _engineService.engineState,
              builder: (context, playerState, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _miniControlButton(
                      icon: Icons.skip_previous_rounded,
                      onPressed: _playlistService.previous,
                      textColor: textColor,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          playerState == AudioEngineState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: context.isDark ? Colors.black : Colors.white,
                        ),
                        onPressed: () {
                          if (playerState == AudioEngineState.playing) {
                            _engineService.pause();
                          } else {
                            _playlistService.play();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _miniControlButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: _playlistService.next,
                      textColor: textColor,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: textColor.withValues(alpha: 0.8), size: 22),
      ),
    );
  }
}
