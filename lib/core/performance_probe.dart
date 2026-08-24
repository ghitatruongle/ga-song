import 'dart:async';
import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'logging/app_logger.dart';

/// Debug-only frame timing + memory logger used while profiling desktop surfaces.
/// In debug mode, captures frame build/raster P95 times and periodic
/// snapshots of the audio source cache size. Reports every 120 frames
class PerformanceProbe {
  PerformanceProbe._();

  static final PerformanceProbe instance = PerformanceProbe._();

  final List<FrameTiming> _timings = <FrameTiming>[];
  Timer? _memoryTimer;
  bool _installed = false;
  String _surface = 'unknown';
  int _frameCount = 0;

  // ─── Memory Tracking ──────────────────────────────────────────────────────
  int _peakAudioCacheSize = 0;
  int _currentAudioCacheSize = 0;
  int _totalPreloads = 0;
  int _totalEvictions = 0;

  void recordPreload() => _totalPreloads++;
  void recordEviction() => _totalEvictions++;
  void recordCacheSize(final int size) {
    _currentAudioCacheSize = size;
    if (size > _peakAudioCacheSize) _peakAudioCacheSize = size;
  }

  void install() {
    assert(() {
      if (_installed) {
        return true;
      }

      _installed = true;
      WidgetsBinding.instance.addTimingsCallback(_onTimings);

      // Report memory/cache stats every 30 seconds
      _memoryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _reportMemoryStats();
      });
      return true;
    }());
  }

  void markSurface(final String surface) {
    assert(() {
      if (_surface == surface) {
        return true;
      }
      _surface = surface;
      return true;
    }());
  }

  void _reportMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    AppLogger.d(
      'performance.probe',
      '[perf][memory] '
          'peakCacheSize=$_peakAudioCacheSize '
          'currentCacheSize=$_currentAudioCacheSize '
          'totalPreloads=$_totalPreloads '
          'totalEvictions=$_totalEvictions '
          'imageCacheBytes=${imageCache.currentSizeBytes} '
          'imageCacheCount=${imageCache.currentSize}',
    );
  }

  /// Exports performance metrics snapshot as a map.
  Map<String, dynamic> toJson() {
    final imageCache = PaintingBinding.instance.imageCache;
    return <String, dynamic>{
      'surface': _surface,
      'frameCount': _frameCount,
      'peakAudioCacheSize': _peakAudioCacheSize,
      'currentAudioCacheSize': _currentAudioCacheSize,
      'totalPreloads': _totalPreloads,
      'totalEvictions': _totalEvictions,
      'imageCacheBytes': imageCache.currentSizeBytes,
      'imageCacheCount': imageCache.currentSize,
    };
  }

  String exportJson() => jsonEncode(toJson());

  void _onTimings(final List<FrameTiming> timings) {
    _timings.addAll(timings);
    _frameCount += timings.length;
    if (_timings.length < 120) {
      return;
    }

    final buildTimes =
        _timings
            .map((final timing) => timing.buildDuration.inMicroseconds / 1000.0)
            .toList()
          ..sort();
    final rasterTimes =
        _timings
            .map(
              (final timing) => timing.rasterDuration.inMicroseconds / 1000.0,
            )
            .toList()
          ..sort();

    final p95Index = (buildTimes.length * 0.95).floor().clamp(
      0,
      buildTimes.length - 1,
    );
    final p99Index = (buildTimes.length * 0.99).floor().clamp(
      0,
      buildTimes.length - 1,
    );

    AppLogger.d(
      'performance.probe',
      '[perf][$_surface] '
          'frames=${_timings.length} '
          'build_p95=${buildTimes[p95Index].toStringAsFixed(2)}ms '
          'build_p99=${buildTimes[p99Index].toStringAsFixed(2)}ms '
          'raster_p95=${rasterTimes[p95Index].toStringAsFixed(2)}ms '
          'total_frames=$_frameCount',
    );

    _timings.clear();
  }

  /// Call to clean up the memory timer when the probe is no longer needed.
  void dispose() {
    _memoryTimer?.cancel();
    _memoryTimer = null;
    // Unregister the frame-timing callback too — otherwise the probe keeps
    // accumulating/logging after dispose.
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
    _timings.clear();
  }
}
