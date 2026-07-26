import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../visualizer/visualizer_controller.dart';

class AmbientGlowPainter extends CustomPainter {
  AmbientGlowPainter({required this.controller, required this.color})
    : _paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150),
      super(repaint: controller);

  final VisualizerController controller;
  final Color color;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.smoothEnergy <= 0.01) {
      return;
    }

    _paint.color = color.withValues(
      alpha: (0.1 + snapshot.smoothEnergy * 0.2).clamp(0.0, 0.4),
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      300 + (snapshot.smoothEnergy * 200),
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant AmbientGlowPainter oldDelegate) {
    return oldDelegate.controller != controller || oldDelegate.color != color;
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter({required this.controller})
    : _paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0),
      super(repaint: controller);

  final VisualizerController controller;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final particles = controller.snapshot.particles;
    for (final particle in particles) {
      _paint.color = particle.color.withValues(
        alpha: (particle.life / particle.maxLife).clamp(0.0, 1.0),
      );
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class CircleVisualizerPainter extends CustomPainter {
  CircleVisualizerPainter({required this.controller})
    : _paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0),
      super(repaint: controller);

  final VisualizerController controller;
  final Paint _paint;

  // P1.4: Color LUT — 20 buckets covering intensityRatio 0..1.
  // Rebuilt only when baseHue drifts >0.5°.
  static const int _lutSize = 20;
  final List<Color> _colorLut = List<Color>.filled(
    _lutSize,
    Colors.transparent,
  );
  double _lastBaseHue = -999.0;

  void _rebuildLut(double baseHue) {
    if ((baseHue - _lastBaseHue).abs() < 0.5) return;
    _lastBaseHue = baseHue;
    for (int i = 0; i < _lutSize; i++) {
      final ratio = i / (_lutSize - 1);
      final hue = (baseHue - ratio * 60).clamp(0.0, 360.0);
      _colorLut[i] = HSVColor.fromAHSV(0.9, hue, 1.0, 1.0).toColor();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.fftData.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 100;
    const numBars = 100;
    const angleStep = (2 * pi) / numBars;
    final baseHue = (1.0 - min(snapshot.smoothEnergy * 2.5, 1.0)) * 270.0;
    const halfBars = numBars ~/ 2;

    _rebuildLut(baseHue);

    for (var i = 0; i < numBars; i++) {
      final symmetricIndex = i <= halfBars ? i : numBars - i;
      final dataIndex = (symmetricIndex * (100 / halfBars)).floor();
      final value = snapshot.fftData[dataIndex];
      final multiplier = 1.0 + (dataIndex / 50);
      final height = ((value * 350 * multiplier) + 4).clamp(4.0, 180.0);
      final intensityRatio = ((height - 4) / 176.0).clamp(0.0, 1.0);
      // P1.4: Look up from pre-computed LUT instead of HSV→RGB per bar.
      final lutIdx = (intensityRatio * (_lutSize - 1)).round().clamp(
        0,
        _lutSize - 1,
      );
      _paint.color = _colorLut[lutIdx];

      final angle = i * angleStep + (pi / 2);
      final innerPoint = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      final outerPoint = Offset(
        center.dx + cos(angle) * (radius + height),
        center.dy + sin(angle) * (radius + height),
      );
      canvas.drawLine(innerPoint, outerPoint, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CircleVisualizerPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class BarVisualizerPainter extends CustomPainter {
  BarVisualizerPainter({required this.controller})
    : _barPaint = Paint()..style = PaintingStyle.fill,
      _reflectionPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
      _highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
      super(repaint: controller);

  final VisualizerController controller;
  final Paint _barPaint;
  final Paint _reflectionPaint;
  final Paint _highlightPaint;

  // P1.4: Dual color LUTs for bar fill (0.9 alpha, 0.9 sat) and reflection (0.2 alpha, 0.8 sat).
  static const int _lutSize = 20;
  final List<Color> _barLut = List<Color>.filled(_lutSize, Colors.transparent);
  final List<Color> _refLut = List<Color>.filled(_lutSize, Colors.transparent);
  double _lastBaseHue = -999.0;
  static final Color _highlightColor = Colors.white.withValues(alpha: 0.3);

  void _rebuildLut(double baseHue) {
    if ((baseHue - _lastBaseHue).abs() < 0.5) return;
    _lastBaseHue = baseHue;
    for (int i = 0; i < _lutSize; i++) {
      final ratio = i / (_lutSize - 1);
      final hue = (baseHue - ratio * 60).clamp(0.0, 360.0);
      _barLut[i] = HSVColor.fromAHSV(0.9, hue, 0.9, 1.0).toColor();
      _refLut[i] = HSVColor.fromAHSV(0.2, hue, 0.8, 1.0).toColor();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.fftData.isEmpty) return;

    const numBars = 90;
    final barWidth = size.width / numBars;
    const gap = 4.0;
    final baseHue = (1.0 - min(snapshot.smoothEnergy * 2.5, 1.0)) * 270.0;

    _rebuildLut(baseHue);
    _highlightPaint.color = _highlightColor;

    for (var i = 0; i < numBars; i++) {
      final dataIndex = (i * (100 / numBars)).floor();
      final value = snapshot.fftData[dataIndex];
      final multiplier = 1.0 + (dataIndex / 40);
      final height = ((value * 300 * multiplier) + 4).clamp(4.0, size.height);
      final intensityRatio = ((height - 4) / size.height).clamp(0.0, 1.0);
      final lutIdx = (intensityRatio * (_lutSize - 1)).round().clamp(
        0,
        _lutSize - 1,
      );

      final reflectionRect = Rect.fromLTWH(
        i * barWidth,
        size.height,
        barWidth - gap,
        height * 0.4,
      );
      _reflectionPaint.color = _refLut[lutIdx];
      canvas.drawRRect(
        RRect.fromRectAndRadius(reflectionRect, const Radius.circular(4)),
        _reflectionPaint,
      );

      final barRect = Rect.fromLTWH(
        i * barWidth,
        size.height - height,
        barWidth - gap,
        height,
      );
      _barPaint.color = _barLut[lutIdx];
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        _barPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        _highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarVisualizerPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class WaveVisualizerPainter extends CustomPainter {
  WaveVisualizerPainter({required this.controller})
    : _layerPath = Path(),
      _edgePath = Path(),
      _fillPaint = Paint()..style = PaintingStyle.fill,
      _strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0),
      super(repaint: controller);

  final VisualizerController controller;
  final Path _layerPath;
  final Path _edgePath;
  final Paint _fillPaint;
  final Paint _strokePaint;

  // #11: Cache per-layer shaders — only recreate when size or layer color changes
  Size _cachedShaderSize = Size.zero;
  final List<Color> _cachedLayerColors = [
    Colors.transparent,
    Colors.transparent,
    Colors.transparent,
  ];
  final List<Shader?> _cachedShaders = [null, null, null];

  Shader _getLayerShader(int layer, Color layerColor, Size size) {
    final sizeChanged = size != _cachedShaderSize;
    final colorChanged = _cachedLayerColors[layer] != layerColor;
    if (sizeChanged || colorChanged || _cachedShaders[layer] == null) {
      if (sizeChanged) _cachedShaderSize = size;
      _cachedLayerColors[layer] = layerColor;
      _cachedShaders[layer] = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[layerColor, layerColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    return _cachedShaders[layer]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.fftData.isEmpty) {
      return;
    }

    const points = 80;
    final step = size.width / (points - 1);
    final baseHue = (1.0 - min(snapshot.smoothEnergy * 2.5, 1.0)) * 270.0;

    for (var layer = 2; layer >= 0; layer--) {
      _layerPath.reset();
      _edgePath.reset();

      for (var i = 0; i < points; i++) {
        final dataIndex = (i * (100 / points)).floor();
        var value = snapshot.fftData[(dataIndex + layer * 2).clamp(0, 255)];
        if (i > 0 && i < points - 1) {
          value =
              (value +
                  snapshot.fftData[(dataIndex - 1).clamp(0, 255)] +
                  snapshot.fftData[(dataIndex + 1).clamp(0, 255)]) /
              3.0;
        }

        final multiplier = 1.0 + (dataIndex / 40);
        final height = ((value * 320 * multiplier) / (layer * 0.4 + 1)).clamp(
          0.0,
          size.height,
        );
        final floatY = sin(i * 0.2 + (snapshot.smoothEnergy * 10)) * 10;
        final x = i * step;
        final y = size.height - height - floatY - (layer * 20);

        if (i == 0) {
          _layerPath
            ..moveTo(x, size.height)
            ..lineTo(x, y);
          _edgePath.moveTo(x, y);
        } else {
          _layerPath.lineTo(x, y);
          _edgePath.lineTo(x, y);
        }

        if (i == points - 1) {
          _layerPath.lineTo(x, size.height);
        }
      }
      _layerPath.close();

      final intensityRatio = (snapshot.smoothEnergy * 2.0).clamp(0.0, 1.0);
      final dynamicHue = (baseHue - (intensityRatio * 60) + (layer * 15)).clamp(
        0.0,
        360.0,
      );
      final layerColor = HSVColor.fromAHSV(
        0.8 - (layer * 0.2),
        dynamicHue,
        0.9,
        1.0,
      ).toColor();

      _fillPaint.shader = _getLayerShader(layer, layerColor, size);
      canvas.drawPath(_layerPath, _fillPaint);

      _strokePaint.color = HSVColor.fromAHSV(
        1.0,
        dynamicHue,
        0.5,
        1.0,
      ).toColor();
      canvas.drawPath(_edgePath, _strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveVisualizerPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class SpectrumTunnelPainter extends CustomPainter {
  SpectrumTunnelPainter({required this.controller})
    : _ringPath = Path(),
      _ringPaint = Paint()..style = PaintingStyle.stroke,
      _glowPaint = Paint(),
      super(repaint: controller);

  final VisualizerController controller;
  final Path _ringPath;
  final Paint _ringPaint;
  final Paint _glowPaint;

  // Cached MaskFilter objects — MaskFilter is immutable, safe to reuse
  static final List<MaskFilter> _ringBlurCache = List<MaskFilter>.generate(
    21,
    (i) => MaskFilter.blur(BlurStyle.solid, 3.0 + i * 0.3),
  );
  static final List<MaskFilter> _glowBlurCache = List<MaskFilter>.generate(
    21,
    (i) => MaskFilter.blur(BlurStyle.normal, 40.0 + i * 3.0),
  );

  // P1.4: 36-slot hue ring LUT (10° per slot) at sat=0.9, val=1.0.
  // Ring and glow colors are computed via simple index lookup.
  static final List<Color> _hueLut = List<Color>.generate(
    36,
    (i) => HSVColor.fromAHSV(1.0, i * 10.0, 0.9, 1.0).toColor(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.fftData.isEmpty) return;

    // P1.5: Early-exit when energy is near zero — skip all 20 rings × 60 segments.
    if (snapshot.smoothEnergy < 0.005) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.45;
    const numRings = 20;
    final baseHue = (1.0 - min(snapshot.smoothEnergy * 2.5, 1.0)) * 270.0;

    for (var ring = numRings - 1; ring >= 0; ring--) {
      final bandIndex = ((ring / numRings) * 80).floor().clamp(0, 255);
      final bandValue = snapshot.fftData[bandIndex];
      final depthFactor = (ring + 1) / numRings;
      final baseRadius = maxRadius * depthFactor;
      final pulseAmount = bandValue * 65 * depthFactor;
      final currentRadius = baseRadius + pulseAmount;
      final drift = (snapshot.time * 30 + ring * 15) % (maxRadius * 1.2);
      final animatedRadius = (currentRadius + drift) % (maxRadius * 1.2);
      if (animatedRadius < 10) {
        continue;
      }

      final ringHue = (baseHue + ring * 12 + snapshot.time * 20) % 360.0;
      final alpha = (1.0 - (animatedRadius / (maxRadius * 1.2))).clamp(
        0.1,
        0.8,
      );

      _ringPath.reset();
      const segments = 60;
      for (var s = 0; s <= segments; s++) {
        final angle = (s / segments) * 2 * pi;
        final wobbleIndex = ((s / segments) * 64).floor().clamp(0, 255);
        final wobble = snapshot.fftData[wobbleIndex] * 15 * depthFactor;
        final radius = animatedRadius + wobble;
        final x = center.dx + cos(angle) * radius;
        final y = center.dy + sin(angle) * radius;

        if (s == 0) {
          _ringPath.moveTo(x, y);
        } else {
          _ringPath.lineTo(x, y);
        }
      }
      _ringPath.close();

      final blurIndex = (bandValue * 20).floor().clamp(0, 20);
      // P1.4: Use hue ring LUT instead of HSVColor.toColor() per ring.
      final hueIdx = (ringHue / 10.0).floor() % 36;
      _ringPaint
        ..strokeWidth = (3.0 * (1.0 - depthFactor * 0.5)).clamp(1.0, 4.0)
        ..color = _hueLut[hueIdx].withValues(alpha: alpha)
        ..maskFilter = _ringBlurCache[blurIndex];
      canvas.drawPath(_ringPath, _ringPaint);
    }

    final glowBlurIndex = (snapshot.smoothEnergy * 20).floor().clamp(0, 20);
    final glowHueIdx =
        (((baseHue + snapshot.time * 20) % 360) / 10.0).floor() % 36;
    _glowPaint
      ..color = _hueLut[glowHueIdx].withValues(
        alpha: (0.3 + snapshot.smoothEnergy * 0.4).clamp(0.0, 0.7),
      )
      ..maskFilter = _glowBlurCache[glowBlurIndex];
    canvas.drawCircle(center, 30 + snapshot.smoothEnergy * 20, _glowPaint);
  }

  @override
  bool shouldRepaint(covariant SpectrumTunnelPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class StarfieldPainter extends CustomPainter {
  StarfieldPainter({required this.controller})
    : _trailPaintFade = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      _trailPaintBright = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      _starPaint = Paint(),
      _wavePaint = Paint()..style = PaintingStyle.fill,
      _wavePath = Path(),
      super(repaint: controller);

  final VisualizerController controller;
  // #11: Split trail into 2 paints (fade + bright) to avoid per-star
  //      LinearGradient shader allocation every frame.
  final Paint _trailPaintFade;
  final Paint _trailPaintBright;
  final Paint _starPaint;
  final Paint _wavePaint;
  final Path _wavePath;

  // B4 fix: Cache MaskFilters for stars based on starSize (0.5 to 4.0)
  // starSize is quantized to 16 steps
  static final List<MaskFilter> _starBlurCache = List<MaskFilter>.generate(
    16,
    (i) => MaskFilter.blur(BlurStyle.solid, 0.5 + i * 0.25),
  );

  // #11: Cache wave shader — recreate only when size changes
  Size _cachedWaveSize = Size.zero;
  Color _cachedWaveColor = Colors.transparent;
  Shader? _cachedWaveShader;

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;

    // P3.2.5: Prefer the typed-array snapshot produced on an isolate.
    // Falls back to the legacy `Star` list until the first isolate
    // completes.
    final typed = snapshot.starFieldSnapshot;
    if (typed != null && typed.length > 0) {
      _paintStarFieldFromSnapshot(canvas, typed);
    } else {
      _paintStarFieldFromLegacyStars(canvas, size, snapshot.stars);
    }

    if (snapshot.fftData.isNotEmpty) {
      _drawBottomWave(canvas, size, snapshot);
    }
  }

  /// P3.2.5: Typed-array fast path.
  ///
  /// Reads positions/colors/radii/zs directly from [StarFieldSnapshot]
  /// without per-iteration Offset or Paint allocations (the [Paint]
  /// instance is reused; only [Offset] is allocated per star, which is
  /// required by [Canvas.drawCircle]).
  ///
  /// Positions are already in screen-space (computed by [computeStarField]
  /// using the host viewport size), so no center-relative projection is
  /// applied here. The visual style is intentionally simpler than the
  /// legacy branch (dots with z-based size and alpha, no trails) to keep
  /// the inner loop allocation-free.
  void _paintStarFieldFromSnapshot(Canvas canvas, StarFieldSnapshot snap) {
    final positions = snap.positions;
    final colors = snap.colors;
    final radii = snap.radii;
    final zs = snap.zs;
    final n = snap.length;

    for (var i = 0; i < n; i++) {
      final x = positions[i * 2];
      final y = positions[i * 2 + 1];
      final z = zs[i];
      final radius = radii[i];

      // Higher z (closer to camera) → bigger dot and brighter alpha.
      final projectedRadius = radius * (0.5 + z * 0.5);
      final alpha = ((0.5 + z * 0.5) * 255).toInt() & 0xFF;

      // B4 fix: reuse cached MaskFilter by quantized star radius.
      final blurIdx = ((projectedRadius - 0.5) / 0.25).floor().clamp(0, 15);

      // Combine the snapshot's RGB with our z-derived alpha without
      // allocating a Color object.
      final argb = (colors[i] & 0x00FFFFFF) | (alpha << 24);
      _starPaint
        ..color = Color(argb)
        ..maskFilter = _starBlurCache[blurIdx];

      canvas.drawCircle(Offset(x, y), projectedRadius, _starPaint);
    }
  }

  /// Legacy rendering path — preserved verbatim from the pre-P3.2.5
  /// implementation. Reads [Star] objects from the main-thread list and
  /// applies center-relative perspective projection with two-segment
  /// trails. This branch is retained as a fallback during the migration
  /// window when the typed-array snapshot is not yet available.
  void _paintStarFieldFromLegacyStars(
    Canvas canvas,
    Size size,
    UnmodifiableListView<Star> stars,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final snapshot = controller.snapshot;

    for (final star in stars) {
      final projScale = (1.0 / (1.0 - star.z * 0.5)).clamp(1.0, 10.0);
      final screenX = center.dx + star.x * projScale;
      final screenY = center.dy + star.y * projScale;

      if (screenX < -20 ||
          screenX > size.width + 20 ||
          screenY < -20 ||
          screenY > size.height + 20) {
        continue;
      }

      final brightness = star.z.clamp(0.1, 1.0);
      final starSize = (1.0 + star.z * 3.0).clamp(0.5, 4.0);
      final trailLength = (star.z * 15 + snapshot.smoothEnergy * 20).clamp(
        2.0,
        40.0,
      );
      final dx = screenX - center.dx;
      final dy = screenY - center.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < 1) {
        continue;
      }

      final nx = dx / distance;
      final ny = dy / distance;
      final trailStart = Offset(
        screenX - nx * trailLength,
        screenY - ny * trailLength,
      );
      final trailEnd = Offset(screenX, screenY);

      // #11: Draw trail as two solid segments (dim → bright) instead of
      //      allocating a LinearGradient shader per star per frame.
      final midPoint = Offset(
        (trailStart.dx + trailEnd.dx) / 2,
        (trailStart.dy + trailEnd.dy) / 2,
      );
      _trailPaintFade
        ..strokeWidth = starSize * 0.6
        ..color = star.color.withValues(alpha: brightness * 0.2);
      canvas.drawLine(trailStart, midPoint, _trailPaintFade);
      _trailPaintBright
        ..strokeWidth = starSize * 0.6
        ..color = star.color.withValues(alpha: brightness * 0.8);
      canvas.drawLine(midPoint, trailEnd, _trailPaintBright);

      // B4 fix: use cached MaskFilter based on starSize instead of allocating per frame
      final blurIdx = ((starSize - 0.5) / 0.25).floor().clamp(0, 15);
      _starPaint
        ..color = star.color.withValues(alpha: brightness)
        ..maskFilter = _starBlurCache[blurIdx];
      canvas.drawCircle(trailEnd, starSize, _starPaint);
    }
  }

  void _drawBottomWave(
    Canvas canvas,
    Size size,
    VisualizerFrameSnapshot snapshot,
  ) {
    _wavePath.reset();
    const points = 60;
    final step = size.width / (points - 1);
    final waveHeight = size.height * 0.08;
    final baseY = size.height - 20;

    _wavePath.moveTo(0, size.height);
    for (var i = 0; i < points; i++) {
      final dataIndex = (i * (80 / points)).floor().clamp(0, 255);
      final value = snapshot.fftData[dataIndex];
      final x = i * step;
      final y = baseY - value * waveHeight * 3;
      _wavePath.lineTo(x, y);
    }
    _wavePath
      ..lineTo(size.width, size.height)
      ..close();

    final baseHue = (1.0 - min(snapshot.smoothEnergy * 2.5, 1.0)) * 270.0;
    final waveColor = HSVColor.fromAHSV(0.3, baseHue, 0.7, 1.0).toColor();
    final waveRect = Rect.fromLTWH(
      0,
      baseY - waveHeight * 3,
      size.width,
      waveHeight * 3 + 20,
    );
    // #11: Only recreate the wave shader when size or dominant color changes
    if (size != _cachedWaveSize ||
        waveColor != _cachedWaveColor ||
        _cachedWaveShader == null) {
      _cachedWaveSize = size;
      _cachedWaveColor = waveColor;
      _cachedWaveShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[waveColor, waveColor.withValues(alpha: 0.0)],
      ).createShader(waveRect);
    }
    _wavePaint.shader = _cachedWaveShader;

    canvas.drawPath(_wavePath, _wavePaint);
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class OscilloscopePainter extends CustomPainter {
  OscilloscopePainter({required this.controller})
    : _wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
      _glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      _gridPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
      _wavePath = Path(),
      super(repaint: controller);

  final VisualizerController controller;
  final Paint _wavePaint;
  final Paint _glowPaint;
  final Paint _gridPaint;
  final Path _wavePath;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawWaveform(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    _gridPaint.color = Colors.green.withValues(alpha: 0.1);
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (int i = 0; i <= 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.fftData.isEmpty) {
      return;
    }

    _wavePath.reset();
    final midY = size.height / 2;
    const points = 128;
    final step = size.width / (points - 1);

    for (var i = 0; i < points; i++) {
      final value = snapshot.fftData[i.clamp(0, 255)];
      final x = i * step;
      final y = midY - value * size.height * 0.4;
      if (i == 0) {
        _wavePath.moveTo(x, y);
      } else {
        _wavePath.lineTo(x, y);
      }
    }

    _glowPaint.color = Colors.greenAccent.withValues(alpha: 0.3);
    canvas.drawPath(_wavePath, _glowPaint);

    _wavePaint.color = Colors.greenAccent;
    canvas.drawPath(_wavePath, _wavePaint);
  }

  @override
  bool shouldRepaint(covariant OscilloscopePainter oldDelegate) =>
      oldDelegate.controller != controller;
}

class RadialBurstPainter extends CustomPainter {
  RadialBurstPainter({required this.controller})
    : _rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      _glowPaint = Paint(),
      super(repaint: controller);

  final VisualizerController controller;
  final Paint _rayPaint;
  final Paint _glowPaint;

  // B3 & B5 fix: Cache MaskFilters for rays and glow to avoid GC pressure
  static final List<MaskFilter> _rayBlurCache = List<MaskFilter>.generate(
    21,
    (i) => MaskFilter.blur(BlurStyle.solid, 2.0 + (i / 20.0) * 4.0),
  );

  static final List<MaskFilter> _glowBlurCache = List<MaskFilter>.generate(
    21,
    (i) => MaskFilter.blur(BlurStyle.normal, 20.0 + (i / 20.0) * 40.0),
  );

  // P1.4: 36-slot hue ring LUT (10° per slot) at sat=0.9, val=1.0.
  static final List<Color> _hueLut = List<Color>.generate(
    36,
    (i) => HSVColor.fromAHSV(1.0, i * 10.0, 0.9, 1.0).toColor(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = controller.snapshot;
    if (snapshot.fftData.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.45;
    final baseHue = (1.0 - min(snapshot.smoothEnergy * 2.5, 1.0)) * 270.0;

    final glowBlurIdx = (snapshot.smoothEnergy * 20).floor().clamp(0, 20);
    // P1.4: Use hue LUT for glow color.
    final glowHueIdx = (baseHue / 10.0).floor() % 36;
    _glowPaint
      ..color = _hueLut[glowHueIdx].withValues(
        alpha: (0.4 + snapshot.smoothEnergy * 0.5).clamp(0.0, 0.8),
      )
      ..maskFilter = _glowBlurCache[glowBlurIdx];

    canvas.drawCircle(center, 40 + snapshot.smoothEnergy * 30, _glowPaint);

    const numRays = 60;
    const angleStep = (2 * pi) / numRays;

    for (var i = 0; i < numRays; i++) {
      final dataIndex = (i * (120 / numRays)).floor();
      final value = snapshot.fftData[dataIndex];
      final rayLength = 60 + value * maxRadius * 1.5;

      final angle = i * angleStep + snapshot.time;
      final innerPoint = Offset(
        center.dx + cos(angle) * 50,
        center.dy + sin(angle) * 50,
      );
      final outerPoint = Offset(
        center.dx + cos(angle) * rayLength,
        center.dy + sin(angle) * rayLength,
      );

      final rayHue = (baseHue + i * 2) % 360.0;
      final rayBlurIdx = (value * 20).floor().clamp(0, 20);
      // P1.4: Use hue LUT for ray color.
      final rayHueIdx = (rayHue / 10.0).floor() % 36;
      _rayPaint
        ..strokeWidth = 3.0 + value * 5.0
        ..color = _hueLut[rayHueIdx].withValues(alpha: 0.8)
        ..maskFilter = _rayBlurCache[rayBlurIdx];

      canvas.drawLine(innerPoint, outerPoint, _rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadialBurstPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
