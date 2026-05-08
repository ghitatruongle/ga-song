import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Debug-only frame timing logger used while profiling desktop surfaces.
class PerformanceProbe {
  PerformanceProbe._();

  static final PerformanceProbe instance = PerformanceProbe._();

  final List<FrameTiming> _timings = <FrameTiming>[];
  bool _installed = false;
  String _surface = 'unknown';

  void install() {
    assert(() {
      if (_installed) {
        return true;
      }

      _installed = true;
      WidgetsBinding.instance.addTimingsCallback(_onTimings);
      return true;
    }());
  }

  void markSurface(String surface) {
    assert(() {
      if (_surface == surface) {
        return true;
      }
      _surface = surface;
      return true;
    }());
  }

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
    if (_timings.length < 120) {
      return;
    }

    final buildTimes =
        _timings
            .map((timing) => timing.buildDuration.inMicroseconds / 1000.0)
            .toList()
          ..sort();
    final rasterTimes =
        _timings
            .map((timing) => timing.rasterDuration.inMicroseconds / 1000.0)
            .toList()
          ..sort();

    final p95Index = (buildTimes.length * 0.95).floor().clamp(
      0,
      buildTimes.length - 1,
    );

    debugPrint(
      '[perf][$_surface] '
      'frames=${_timings.length} '
      'build_p95=${buildTimes[p95Index].toStringAsFixed(2)}ms '
      'raster_p95=${rasterTimes[p95Index].toStringAsFixed(2)}ms',
    );

    _timings.clear();
  }
}
