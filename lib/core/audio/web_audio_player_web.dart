// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, avoid_dynamic_calls
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';
import 'web_audio_player.dart';

WebAudioPlayer getWebAudioPlayer() => WebAudioPlayerWeb();

class WebAudioPlayerWeb implements WebAudioPlayer {
  html.AudioElement? _audioElement;
  dynamic _audioContext;
  dynamic _sourceNode;
  dynamic _analyserNode;

  final _onEndedController = StreamController<void>.broadcast();
  bool _isPlaying = false;
  bool _isPaused = false;
  StreamSubscription? _endedSubscription;

  WebAudioPlayerWeb() {
    _audioElement = html.AudioElement();
    _endedSubscription = _audioElement?.onEnded.listen((_) {
      _isPlaying = false;
      _isPaused = false;
      _onEndedController.add(null);
    });
  }

  void _initAudioContext() {
    if (_audioContext != null) return;
    try {
      final jsContextClass =
          js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (jsContextClass != null) {
        _audioContext = js.JsObject(jsContextClass as js.JsFunction);
      }
      if (_audioElement != null && _audioContext != null) {
        _sourceNode = _audioContext.callMethod('createMediaElementSource', [
          _audioElement,
        ]);
        _analyserNode = _audioContext.callMethod('createAnalyser');
        _analyserNode['fftSize'] = 512;

        // Connect: source -> analyser -> destination
        _sourceNode.callMethod('connect', [_analyserNode]);
        final destination = _audioContext['destination'];
        _analyserNode.callMethod('connect', [destination]);
      }
    } catch (e) {
      html.window.console.error('Failed to initialize Web Audio Context: $e');
    }
  }

  @override
  Future<void> play(final String assetPath) async {
    await stop();

    String url = assetPath;
    if (assetPath.startsWith('assets/')) {
      // Flutter web assets are served under 'assets/' prefix.
      url = 'assets/$assetPath';
    }

    _audioElement?.src = url;
    _audioElement?.load();

    _initAudioContext();
    if (_audioContext != null && _audioContext['state'] == 'suspended') {
      try {
        _audioContext.callMethod('resume');
      } catch (e) {
        html.window.console.error('Failed to resume AudioContext: $e');
      }
    }

    try {
      await _audioElement?.play();
      _isPlaying = true;
      _isPaused = false;
    } catch (e) {
      _isPlaying = false;
      _isPaused = false;
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    if (_isPlaying) {
      _audioElement?.pause();
      _isPlaying = false;
      _isPaused = true;
    }
  }

  @override
  Future<void> resume() async {
    if (_isPaused) {
      _initAudioContext();
      if (_audioContext != null && _audioContext['state'] == 'suspended') {
        try {
          _audioContext.callMethod('resume');
        } catch (e) {
          html.window.console.error('Failed to resume AudioContext: $e');
        }
      }
      try {
        await _audioElement?.play();
        _isPlaying = true;
        _isPaused = false;
      } catch (e) {
        rethrow;
      }
    }
  }

  @override
  Future<void> stop() async {
    _audioElement?.pause();
    // Setting currentTime before metadata is available can throw
    // InvalidStateError in some browsers — swallow it.
    try {
      _audioElement?.currentTime = 0;
    } catch (_) {}
    _isPlaying = false;
    _isPaused = false;
  }

  @override
  Future<void> seek(final Duration position) async {
    if (_audioElement != null) {
      try {
        _audioElement!.currentTime = position.inMilliseconds / 1000.0;
      } catch (_) {
        // Seek on a not-yet-loaded element — ignore, next tick will retry.
      }
    }
  }

  @override
  void setVolume(final double volume) {
    if (_audioElement != null) {
      _audioElement!.volume = volume.clamp(0.0, 1.0);
    }
  }

  @override
  Duration get position {
    if (_audioElement == null) return Duration.zero;
    final seconds = _audioElement!.currentTime;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  Duration get duration {
    if (_audioElement == null) return Duration.zero;
    final seconds = _audioElement!.duration;
    if (seconds.isNaN || seconds.isInfinite) return Duration.zero;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isPaused => _isPaused;

  @override
  Stream<void> get onEnded => _onEndedController.stream;

  @override
  List<double> getFftData() {
    if (_analyserNode == null) {
      return List<double>.filled(128, 0);
    }
    final int binCount = _analyserNode['frequencyBinCount'] as int;
    final buffer = Float32List(binCount);
    _analyserNode.callMethod('getFloatFrequencyData', [buffer]);

    // Float frequency data is in dB (ranges from -100 to 0).
    // Normalize it to 0.0 to 1.0.
    final List<double> fft = List<double>.filled(binCount, 0);
    for (int i = 0; i < binCount; i++) {
      // Normalize -100dB..0dB to 0.0..1.0 range
      final val = (buffer[i] + 100).clamp(0.0, 100.0) / 100.0;
      // Square or scale to match visualizer expectation (0.0 to 1.0+)
      fft[i] = val * val;
    }
    return fft;
  }

  @override
  void dispose() {
    _endedSubscription?.cancel();
    _audioElement?.pause();
    _audioElement?.remove();
    _audioElement = null;
    _onEndedController.close();
    try {
      _sourceNode?.callMethod('disconnect');
      _analyserNode?.callMethod('disconnect');
      _audioContext?.callMethod('close');
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
