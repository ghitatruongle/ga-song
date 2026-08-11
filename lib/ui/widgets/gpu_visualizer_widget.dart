import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show FragmentProgram, FragmentShader;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../providers/service_providers.dart';
import '../../core/platform_capabilities.dart';
import '../visualizer/visualizer_controller.dart';

/// GPU Fragment Shader Visualizer for G.A - Song
///
/// Uses Flutter's FragmentProgram to render visualizers on the GPU,
/// providing significantly better performance than CustomPainter for
/// complex visualizations with many particles/stars/bars.
///
/// v0.9.5: Receives real FFT data from [VisualizerController] instead of
/// generating random placeholder data.
class GpuVisualizerWidget extends ConsumerStatefulWidget {
  const GpuVisualizerWidget({super.key, this.controller});

  /// The [VisualizerController] that produces FFT data.
  /// When null, the widget attempts to find one from the ancestor tree.
  final VisualizerController? controller;

  @override
  ConsumerState<GpuVisualizerWidget> createState() =>
      _GpuVisualizerWidgetState();
}

class _GpuVisualizerWidgetState extends ConsumerState<GpuVisualizerWidget> {
  FragmentProgram? _fragmentProgram;
  FragmentShader? _shader;
  Timer? _updateTimer;

  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

  // Visualizer configuration
  int _currentShape =
      0; // 0=circle, 1=bar, 2=wave, 3=tunnel, 4=starfield, 5=oscilloscope, 6=radial
  bool _isInitialized = false;

  // Shader uniforms
  double _time = 0;
  double _smoothEnergy = 0;
  double _beatIntensity = 0;
  final int _numBars = 100;
  final double _sensitivity = 1;
  final Color _accentColor = Colors.blue;

  // FFT data — populated from VisualizerController in v0.9.5
  static const int _fftSize = 100; // Shader uses 100 bars
  final Float32List _fftData = Float32List(_fftSize);

  // v0.9.5: Reference to the owner controller (passed from PersonalVisualizerWidget)
  VisualizerController? _controllerRef;

  @override
  void initState() {
    super.initState();
    _controllerRef = widget.controller;
    _initShader();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _shader?.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  Future<void> _initShader() async {
    try {
      // FragmentProgram.fromAsset expects the ASSET NAME, not the shader
      // source text. Passing a loadString() result always throws, leaving
      // the GPU visualizer spinner forever.
      _fragmentProgram = await FragmentProgram.fromAsset(
        'shaders/visualizer.frag',
      );
      _isInitialized = true;

      // Adaptive frame rate based on device tier
      final frameInterval = _getAdaptiveFrameInterval();
      _updateTimer = Timer.periodic(frameInterval, _updateShader);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load visualizer shader: $e');
    }
  }

  /// Returns adaptive frame interval based on device performance.
  /// v0.9.5: Reduces FPS to 30 on low-end devices and in power-saving mode.
  Duration _getAdaptiveFrameInterval() {
    final caps = PlatformCapabilities.instance;
    if (caps.isPowerSavingMode) {
      return const Duration(milliseconds: 33); // ~30fps in power saver
    }
    if (caps.isAndroid && caps.deviceTier == DeviceTier.low) {
      return const Duration(milliseconds: 33); // ~30fps
    } else if (caps.isAndroid && caps.deviceTier == DeviceTier.mid) {
      return const Duration(milliseconds: 20); // ~50fps
    }
    return const Duration(milliseconds: 16); // ~60fps
  }

  void _updateShader(final Timer timer) {
    if (!_isInitialized || _fragmentProgram == null || !mounted) return;

    final settings = ref.read(settingsManagerProvider);

    // Update visualizer state
    final isPlaying =
        ref.read(audioEngineServiceProvider).engineState.value ==
        AudioEngineState.playing;
    final isVisualizerEnabled = settings.visualizerEnabledNotifier.value;

    if (!isPlaying || !isVisualizerEnabled) {
      _smoothEnergy *= 0.9; // Fade out
      _beatIntensity *= 0.85;
    } else {
      // v0.9.5: Get real FFT data from VisualizerController
      _updateFftData();
    }

    // Update shape from settings
    _currentShape = settings.visualizerShapeNotifier.value;

    // Update time
    _time += 0.016;

    // Update shader if created
    if (_shader != null) {
      _updateShaderUniforms();
      _repaintNotifier.value++;
    }
  }

  /// v0.9.5: Populates _fftData from VisualizerController's real FFT data
  /// instead of generating random placeholder values.
  void _updateFftData() {
    // Prefer the explicitly-provided controller, then fall back to provider
    final controller = _controllerRef ?? ref.read(visualizerControllerProvider);
    if (controller == null) return;

    final fftView = controller.fftData;
    final energy = controller.smoothEnergy;
    final isBeat = controller.isBeat;

    // Copy FFT data into Float32List for shader uniforms
    // The shader expects 100 bars, we map from the 256-sample source
    final sourceCount = fftView.length;
    for (int i = 0; i < _fftSize; i++) {
      final srcIndex = (i * sourceCount / _fftSize).toInt().clamp(
        0,
        sourceCount - 1,
      );
      _fftData[i] = fftView[srcIndex];
    }

    // Clamp energy to [0, 1]
    _smoothEnergy = energy.clamp(0.0, 1.0);
    _beatIntensity = isBeat ? 1.0 : _beatIntensity * 0.9;
  }

  void _updateShaderUniforms() {
    if (_shader == null) return;

    _shader!.setFloat(0, _time); // u_time
    _shader!.setFloat(1, _smoothEnergy); // u_energy
    _shader!.setFloat(2, _beatIntensity); // u_beat
    _shader!.setFloat(3, _currentShape.toDouble()); // u_shape
    _shader!.setFloat(4, _sensitivity); // u_sensitivity
    _shader!.setFloat(5, _numBars.toDouble()); // u_numBars
    _shader!.setFloat(8, _fftData.isNotEmpty ? _fftData[0] : 0.0); // u_bass
    _shader!.setFloat(9, _fftData.length > 33 ? _fftData[33] : 0.0); // u_mid
    _shader!.setFloat(10, _fftData.length > 66 ? _fftData[66] : 0.0); // u_high
    _shader!.setFloat(11, _accentColor.r / 255.0); // u_accentColor.r
    _shader!.setFloat(12, _accentColor.g / 255.0); // u_accentColor.g
    _shader!.setFloat(13, _accentColor.b / 255.0); // u_accentColor.b
  }

  @override
  Widget build(final BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Initialize shader with correct size
        if (_shader == null && _fragmentProgram != null) {
          _shader = _fragmentProgram!.fragmentShader()
            ..setFloat(0, 0)
            ..setFloat(1, _smoothEnergy)
            ..setFloat(2, 0)
            ..setFloat(3, _currentShape.toDouble())
            ..setFloat(4, _sensitivity)
            ..setFloat(5, _numBars.toDouble())
            ..setFloat(6, size.width)
            ..setFloat(7, size.height);
        }

        return RepaintBoundary(
          child: _shader != null
              ? CustomPaint(
                  size: size,
                  painter: _GpuShaderPainter(
                    _shader!,
                    repaint: _repaintNotifier,
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// Painter that renders a FragmentShader to the canvas.
class _GpuShaderPainter extends CustomPainter {
  final FragmentShader shader;

  _GpuShaderPainter(this.shader, {super.repaint});

  @override
  void paint(final Canvas canvas, final Size size) {
    // Update shader with current size (u_width, u_height)
    shader.setFloat(6, size.width);
    shader.setFloat(7, size.height);

    // Draw full-screen quad with shader
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant final _GpuShaderPainter oldDelegate) =>
      oldDelegate.shader != shader;
}
