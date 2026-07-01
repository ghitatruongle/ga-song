import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../core/audio/audio_engine_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform_capabilities.dart';

import '../../core/settings_manager.dart';

@immutable
class VisualizerFrameSnapshot {
  const VisualizerFrameSnapshot({
    required this.fftData,
    required this.particles,
    required this.stars,
    required this.smoothEnergy,
    required this.time,
    required this.size,
    required this.isBeat,
  });

  final UnmodifiableListView<double> fftData;
  final UnmodifiableListView<Particle> particles;
  final UnmodifiableListView<Star> stars;
  final double smoothEnergy;
  final double time;
  final Size size;
  final bool isBeat;
}

class Particle {
  Particle(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.size,
    this.life,
    this.maxLife,
    this.color,
  );

  double x;
  double y;
  double vx;
  double vy;
  double size;
  double life;
  double maxLife;
  Color color;
}

class Star {
  Star({
    required this.x,
    required this.y,
    required this.z,
    required this.speed,
    required this.baseAngle,
    required this.color,
  });

  double x;
  double y;
  double z;
  double speed;
  double baseAngle;
  Color color;
}

class VisualizerController extends ChangeNotifier with WidgetsBindingObserver {
  VisualizerController({
    required TickerProvider vsync,
    required AudioEngineService audioService,
    required SettingsManager settings,
  }) : _audioService = audioService,
       _settings = settings {
    _audioData = null; // D2 fix: deferred to lazy init in _updateAudioFrame

    _initStars();
    _ticker = vsync.createTicker(_handleTick);
    _audioService.engineState.addListener(_handleActivityChanged);
    _settings.visualizerEnabledNotifier.addListener(_handleActivityChanged);
    WidgetsBinding.instance.addObserver(this);
    _publishSnapshot();
    _handleActivityChanged();
  }

  // P4.3: Lifecycle state flag to stop ticker when app is in background
  bool _isAppInBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _isAppInBackground = true;
      _stopTicker();
    } else if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      _handleActivityChanged();
    }
  }

  static const int fftSampleCount = 256;
  static final int maxParticleCount =
      PlatformCapabilities.instance.maxParticleCount;
  static final int starCount =
      PlatformCapabilities.instance.maxStarCount;

  static const double _fftSmoothFactor = 0.45;
  static const double _fftNewFactor = 0.55;
  static const double _energyDivisor = 64.0;

  static const List<double> _frequencyWeights = [
    2.0,  // 0-51:   Sub-bass — nhạy gấp đôi
    1.8,  // 52-102: Bass
    1.4,  // 103-153: Low-mid
    1.0,  // 154-204: Mid — bình thường
    0.8,  // 205-255: High — giảm noise
  ];

  final AudioEngineService _audioService;
  final SettingsManager _settings;
  final Random _random = Random();
  final List<double> _fftData = List<double>.filled(fftSampleCount, 0.0);
  final List<double> _smoothedFft = List<double>.filled(fftSampleCount, 0.0);
  final List<Star> _stars = <Star>[];
  late final Ticker _ticker;
  AudioData? _audioData;

  // ── Particle pool (zero-allocation per frame) ──────────────────────────────
  late final List<Particle> _particlePool = List<Particle>.generate(
    maxParticleCount,
    (_) => Particle(0, 0, 0, 0, 0, 0, 0, Colors.transparent),
  );
  int _activeParticleCount = 0;

  late final UnmodifiableListView<double> _fftView =
      UnmodifiableListView<double>(_smoothedFft);
  late final UnmodifiableListView<Star> _starView = UnmodifiableListView<Star>(
    _stars,
  );

  Size _size = Size.zero;
  double _smoothEnergy = 0.0;
  double _elapsedSeconds = 0.0;
  Duration? _lastElapsed;
  bool _tickerRunning = false;
  int _lowEnergySkipCounter = 0;

  // P1.1: Cached active-particle view — avoids sublist() allocation every frame.
  // Updated only when _activeParticleCount changes.
  int _lastPublishedParticleCount = -1;
  late UnmodifiableListView<Particle> _activeParticleView =
      UnmodifiableListView<Particle>(const <Particle>[]);

  // P1.2: Adaptive half-rate mode.
  // When 3+ consecutive frames exceed the budget, tick every other frame.
  int _overBudgetCount = 0;
  bool _halfRateMode = false;
  int _frameCounter = 0;
  int get _frameBudgetMs =>
      PlatformCapabilities.instance.visualizerFrameBudgetMs;

  // P1.3: Pre-computed star color palette (20 slots, ~18° hue apart).
  // Updated only when baseHue drifts >1° — avoids 200× HSVColor.toColor()/frame.
  static const int _starPaletteSize = 20;
  final List<Color> _starColorPalette =
      List<Color>.filled(_starPaletteSize, Colors.transparent);
  double _lastPaletteHue = -999.0;

  // Beat detection
  bool _isBeat = false;
  int _beatCooldown = 0;

  late VisualizerFrameSnapshot _snapshot;

  VisualizerFrameSnapshot get snapshot => _snapshot;

  bool get isAudioReactive =>
      _audioService.engineState.value == AudioEngineState.playing &&
      _settings.visualizerEnabledNotifier.value;

  void updateSize(Size size) {
    if (_size == size) {
      return;
    }

    _size = size;
    _publishSnapshot();
    notifyListeners();
  }

  void _handleActivityChanged() {
    if (_isAppInBackground) return;
    
    if (isAudioReactive || _activeParticleCount > 0) {
      _startTicker();
    } else {
      _stopTicker();
      _publishSnapshot();
      notifyListeners();
    }
  }

  void _startTicker() {
    if (_tickerRunning) {
      return;
    }

    _lastElapsed = null;
    _ticker.start();
    _tickerRunning = true;
  }

  void _stopTicker() {
    if (!_tickerRunning) {
      return;
    }

    _ticker.stop();
    _tickerRunning = false;
  }

  void _handleTick(Duration elapsed) {
    final deltaSeconds = _lastElapsed == null
        ? 0.016
        : (elapsed - _lastElapsed!).inMicroseconds /
              Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    _elapsedSeconds = elapsed.inMilliseconds / 1000.0;

    // P1.2: Adaptive half-rate — skip every other frame when over budget.
    _frameCounter++;
    if (_halfRateMode && _frameCounter.isOdd) {
      return;
    }

    // Adaptive frame skip: render 1/3 frames khi energy rất thấp
    if (_smoothEnergy < 0.01 && isAudioReactive) {
      _lowEnergySkipCounter++;
      if (_lowEnergySkipCounter % 3 != 0) {
        return;
      }
    } else {
      _lowEnergySkipCounter = 0;
    }

    if (isAudioReactive) {
      _updateAudioFrame();
    }

    _updateParticles(deltaSeconds.clamp(0.001, 0.05));

    // Chỉ update stars khi đang hiển thị Starfield mode (shape == 4)
    if (isAudioReactive && _settings.visualizerShapeNotifier.value == 4) {
      _updateStars();
    }

    if (!isAudioReactive && _activeParticleCount == 0) {
      _stopTicker();
    }

    // P1.2: Measure frame time and adjust half-rate mode.
    final frameMs = deltaSeconds * 1000.0;
    if (frameMs > _frameBudgetMs) {
      _overBudgetCount++;
      if (_overBudgetCount >= 3 && !_halfRateMode) {
        _halfRateMode = true;
        AppLogger.i('visualizer.controller', 'entering half-rate mode (frame ${frameMs.toStringAsFixed(1)}ms > ${_frameBudgetMs}ms)');
      }
    } else {
      if (_overBudgetCount > 0) _overBudgetCount--;
      if (_overBudgetCount == 0 && _halfRateMode) {
        _halfRateMode = false;
        AppLogger.i('visualizer.controller', 'exiting half-rate mode');
      }
    }

    _publishSnapshot();
    notifyListeners();
  }

  void _updateAudioFrame() {
    // D2 fix: Lazy initialization of AudioData. If it was null because
    // the engine wasn't ready during constructor, try creating it now.
    if (_audioData == null) {
      if (!SoLoud.instance.isInitialized) return;
      try {
        _audioData = AudioData(GetSamplesKind.linear);
      } catch (e) {
        AppLogger.w('visualizer.controller', 'AudioData init failed', error: e);
        return;
      }
    }

    final audioData = _audioData!;

    try {
      audioData.updateSamples();
      final samples = audioData.getAudioData(alwaysReturnData: true);
      if (samples.length < fftSampleCount) {
        return;
      }

      var currentEnergy = 0.0;
      final sensitivity = _settings.sensitivityNotifier.value;
      for (var i = 0; i < fftSampleCount; i++) {
        final bandIndex = (i * 5 / fftSampleCount).floor().clamp(0, 4);
        final sample = samples[i] * _frequencyWeights[bandIndex] * sensitivity;
        _fftData[i] = sample;
        _smoothedFft[i] = _smoothedFft[i] * _fftSmoothFactor + sample * _fftNewFactor;
        if (i < 64) {
          currentEnergy += sample;
        }
      }

      currentEnergy /= _energyDivisor;
      
      // Attack nhanh (bắt beat), Release chậm (đuôi mượt)
      if (currentEnergy > _smoothEnergy) {
        _smoothEnergy = _smoothEnergy * 0.6 + currentEnergy * 0.4;
      } else {
        _smoothEnergy = _smoothEnergy * 0.88 + currentEnergy * 0.12;
      }

      if (currentEnergy > 0.03 &&
          _activeParticleCount < maxParticleCount &&
          _size.width > 0 &&
          _size.height > 0) {
        final spawnCount = (currentEnergy * 18).floor().clamp(0, 8);
        for (var i = 0; i < spawnCount; i++) {
          _spawnParticle(currentEnergy);
        }
      }

      // Detect beat using a dynamic relative threshold
      if (_beatCooldown > 0) {
        _beatCooldown--;
        _isBeat = false;
      } else {
        // A beat is detected if the current raw energy spikes significantly
        // above the smoothed average energy.
        // We use a relative multiplier (1.35x) and a tiny absolute floor (0.02)
        final dynamicThreshold = _smoothEnergy * 1.35 + 0.02;
        _isBeat = currentEnergy > dynamicThreshold;
        if (_isBeat) {
          _beatCooldown = 12; // ~200ms cooldown to avoid double-triggering
        }
      }

    } catch (e, stack) {
      AppLogger.e('visualizer.controller', 'operation failed', error: e, stack: stack);
    }
  }

  // ── Particle pool: compact in-place, zero allocation ───────────────────────
  void _updateParticles(double deltaSeconds) {
    int writeIdx = 0;
    for (int i = 0; i < _activeParticleCount; i++) {
      final p = _particlePool[i];
      p.x += p.vx;
      p.y += p.vy;
      p.life -= deltaSeconds;
      if (p.life > 0) {
        if (writeIdx != i) {
          // Swap to compact the pool
          final temp = _particlePool[writeIdx];
          _particlePool[writeIdx] = _particlePool[i];
          _particlePool[i] = temp;
        }
        writeIdx++;
      }
    }
    _activeParticleCount = writeIdx;
  }

  void _initStars() {
    if (_stars.isNotEmpty) {
      return;
    }

    for (var i = 0; i < starCount; i++) {
      _stars.add(_createStar());
    }
  }

  Star _createStar() {
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * 300;
    return Star(
      x: cos(angle) * distance,
      y: sin(angle) * distance,
      z: _random.nextDouble(),
      speed: _random.nextDouble() * 2 + 0.5,
      baseAngle: angle,
      color: HSVColor.fromAHSV(
        1.0,
        _random.nextDouble() * 60 + 200,
        0.6,
        1.0,
      ).toColor(),
    );
  }

  void _updateStars() {
    final speedMultiplier = 1.0 + _smoothEnergy * 8;
    final baseHue = (1.0 - min(_smoothEnergy * 2.5, 1.0)) * 270.0;
    final maxX = _size.width > 0 ? _size.width * 0.75 : 800.0;
    final maxY = _size.height > 0 ? _size.height * 0.75 : 600.0;

    // P1.3: Rebuild 20-slot palette only when hue drifts > 1°.
    // Each star maps into a palette slot via (index % 20).
    final needPaletteRebuild = (baseHue - _lastPaletteHue).abs() > 1.0;
    if (needPaletteRebuild) {
      _lastPaletteHue = baseHue;
      for (int p = 0; p < _starPaletteSize; p++) {
        final hue = (baseHue + p * (360.0 / _starPaletteSize)) % 360.0;
        _starColorPalette[p] = HSVColor.fromAHSV(1.0, hue, 0.7, 1.0).toColor();
      }
    }

    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      var dist = sqrt(star.x * star.x + star.y * star.y);
      if (dist < 0.1) {
        dist = 0.1;
      }

      final nx = star.x / dist;
      final ny = star.y / dist;
      star.x += nx * star.speed * speedMultiplier;
      star.y += ny * star.speed * speedMultiplier;
      star.z = (star.z + 0.005 * speedMultiplier).clamp(0.0, 1.0);

      // P1.3: Assign color from pre-computed palette — zero HSV→RGB per star.
      if (needPaletteRebuild) {
        star.color = _starColorPalette[i % _starPaletteSize];
      }

      if (star.x.abs() > maxX || star.y.abs() > maxY) {
        _stars[i] = _createStar();
      }
    }
  }

  // ── Particle spawn: reuse pool slot, no allocation ─────────────────────────
  void _spawnParticle(double energy) {
    if (_activeParticleCount >= maxParticleCount) {
      return;
    }

    final p = _particlePool[_activeParticleCount];
    p.x = _random.nextDouble() * (_size.width + 200) - 100;
    p.y = _size.height + _random.nextDouble() * 50;
    p.vx = (_random.nextDouble() - 0.5) * 2;
    p.vy = -(_random.nextDouble() * 5 + energy * 10);
    p.size = _random.nextDouble() * 3 + 1;
    p.maxLife = _random.nextDouble() * 2 + 1;
    p.life = p.maxLife;
    final baseHue = (1.0 - min(_smoothEnergy * 2.5, 1.0)) * 270.0;
    p.color = HSVColor.fromAHSV(0.8, baseHue, 0.8, 1.0).toColor();
    _activeParticleCount++;
  }

  void _publishSnapshot() {
    // P1.1: Only rebuild the particle view when the active count changes.
    // This avoids a sublist() allocation (new List + copy) every frame.
    if (_activeParticleCount != _lastPublishedParticleCount) {
      _lastPublishedParticleCount = _activeParticleCount;
      _activeParticleView = UnmodifiableListView<Particle>(
        _particlePool.sublist(0, _activeParticleCount),
      );
    }
    _snapshot = VisualizerFrameSnapshot(
      fftData: _fftView,
      particles: _activeParticleView,
      stars: _starView,
      smoothEnergy: _smoothEnergy,
      time: _elapsedSeconds,
      size: _size,
      isBeat: _isBeat,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioService.engineState.removeListener(_handleActivityChanged);
    _settings.visualizerEnabledNotifier.removeListener(_handleActivityChanged);
    _ticker.dispose();
    try {
      _audioData?.dispose();
    } catch (e, stack) {
      AppLogger.e('visualizer.controller', 'operation failed', error: e, stack: stack);
    }
    super.dispose();
  }
}
