/// GPU Fragment Shader Visualizer for G.A - Song
///
/// Uses Flutter's FragmentProgram to render visualizers on the GPU,
/// providing significantly better performance than CustomPainter for
/// complex visualizations with many particles/stars/bars.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show FragmentProgram, FragmentShader;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../core/settings_manager.dart';
import '../../providers/service_providers.dart';
import '../../core/performance_probe.dart';

/// Fragment shader visualizer widget using Flutter's FragmentProgram.
class GpuVisualizerWidget extends ConsumerStatefulWidget {
  const GpuVisualizerWidget({super.key});

  @override
  ConsumerState<GpuVisualizerWidget> createState() => _GpuVisualizerWidgetState();
}

class _GpuVisualizerWidgetState extends ConsumerState<GpuVisualizerWidget> {
  FragmentProgram? _fragmentProgram;
  FragmentShader? _shader;
  Timer? _updateTimer;
  
  // Visualizer configuration
  int _currentShape = 0; // 0=circle, 1=bar, 2=wave, 3=tunnel, 4=starfield, 5=oscilloscope, 6=radial
  bool _isInitialized = false;
  
  // Shader uniforms
  double _time = 0.0;
  double _smoothEnergy = 0.0;
  double _beatIntensity = 0.0;
  int _numBars = 100;
  double _sensitivity = 1.0;
  Color _accentColor = Colors.blue;
  
  // FFT data for shader
  static const int _fftSize = 256;
  Float32List? _fftData;
  
  @override
  void initState() {
    super.initState();
    _initShader();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _shader?.dispose();
    super.dispose();
  }
  
  Future<void> _initShader() async {
    try {
      final shaderSource = await rootBundle.loadString('shaders/visualizer.frag');
      _fragmentProgram = await FragmentProgram.fromAsset(shaderSource);
      _isInitialized = true;
      
      // Start update timer
      _updateTimer = Timer.periodic(const Duration(milliseconds: 16), _updateShader);
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Failed to load visualizer shader: $e');
    }
  }
  
  void _updateShader(Timer timer) {
    if (!_isInitialized || _fragmentProgram == null || !mounted) return;
    
    final engineService = ref.read(audioEngineServiceProvider);
    final settings = ref.read(settingsManagerProvider);
    final playlist = ref.read(playlistServiceProvider);
    
    // Update visualizer state
    final isPlaying = engineService.engineState.value == AudioEngineState.playing;
    final isVisualizerEnabled = settings.visualizerEnabledNotifier.value;
    
    if (!isPlaying || !isVisualizerEnabled) {
      _smoothEnergy *= 0.9; // Fade out
    } else {
      // Get FFT data from audio engine
      _updateFftData();
    }
    
    // Update shape from settings
    _currentShape = settings.visualizerShapeNotifier.value;
    
    // Update time
    _time += 0.016;
    
    // Update shader if created
    if (_shader != null) {
      _updateShaderUniforms();
    }
    
    if (mounted) setState(() {});
  }
  
  void _updateFftData() {
    // We'll need to get FFT data from the audio engine
    // For now, generate placeholder data
    _fftData ??= Float32List(_fftSize);
    final random = Random();
    for (int i = 0; i < _fftSize; i++) {
      _fftData![i] = random.nextDouble() * 0.5;
    }
  }
  
  void _updateShaderUniforms() {
    if (_shader == null) return;
    
    final engineService = ref.read(audioEngineServiceProvider);
    final settings = ref.read(settingsManagerProvider);
    
    _shader!.setFloat(0, _time);                    // u_time
    _shader!.setFloat(1, _smoothEnergy);            // u_energy
    _shader!.setFloat(2, _beatIntensity);           // u_beat
    _shader!.setFloat(3, _currentShape.toDouble()); // u_shape
    _shader!.setFloat(4, _sensitivity);             // u_sensitivity
    _shader!.setFloat(5, _numBars.toDouble());      // u_numBars
    _shader!.setFloat(8, _fftData != null ? _fftData![0] : 0.0);   // u_bass
    _shader!.setFloat(9, _fftData != null ? _fftData![10] : 0.0);  // u_mid
    _shader!.setFloat(10, _fftData != null ? _fftData![50] : 0.0); // u_high
    _shader!.setFloat(11, _accentColor.r / 255.0);  // u_accentColor.r
    _shader!.setFloat(12, _accentColor.g / 255.0);  // u_accentColor.g
    _shader!.setFloat(13, _accentColor.b / 255.0);  // u_accentColor.b
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Initialize shader with correct size
        if (_shader == null && _fragmentProgram != null) {
          _shader = _fragmentProgram!.fragmentShader()
            ..setFloat(0, 0.0)
            ..setFloat(1, _smoothEnergy)
            ..setFloat(2, 0.0)
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
                  painter: _GpuShaderPainter(_shader!),
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
  
  _GpuShaderPainter(this.shader);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Update shader with current size (u_width, u_height)
    shader.setFloat(6, size.width);
    shader.setFloat(7, size.height);
    
    // Draw full-screen quad with shader
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..shader = shader);
  }
  
  @override
  bool shouldRepaint(covariant _GpuShaderPainter oldDelegate) {
    return oldDelegate.shader != shader;
  }
}