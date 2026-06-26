import 'package:flutter/foundation.dart';

/// Service for monitoring and recording performance metrics.
///
/// Tracks operation durations and provides statistics for optimization.
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._();
  static PerformanceService get instance => _instance;

  PerformanceService._();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Starts a timer with the given [name].
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// Stops the timer with [name] and records the duration.
  ///
  /// Returns the elapsed duration.
  Duration stopTimer(String name) {
    final timer = _timers.remove(name);
    if (timer == null) {
      throw StateError('Timer $name not found');
    }

    timer.stop();
    _metrics.putIfAbsent(name, () => []).add(timer.elapsed);

    if (kDebugMode) {
      debugPrint('Performance: $name took ${timer.elapsedMilliseconds}ms');
    }

    return timer.elapsed;
  }

  /// Measures the duration of [operation] and records it.
  T measure<T>(String name, T Function() operation) {
    startTimer(name);
    try {
      return operation();
    } finally {
      stopTimer(name);
    }
  }

  /// Measures the duration of an async [operation] and records it.
  Future<T> measureAsync<T>(String name, Future<T> Function() operation) async {
    startTimer(name);
    try {
      return await operation();
    } finally {
      stopTimer(name);
    }
  }

  /// Gets the average duration for [name].
  Duration? getAverageTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    final totalMicros = times.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );

    return Duration(microseconds: totalMicros ~/ times.length);
  }

  /// Gets the minimum duration for [name].
  Duration? getMinTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a < b ? a : b);
  }

  /// Gets the maximum duration for [name].
  Duration? getMaxTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a > b ? a : b);
  }

  /// Gets the number of measurements for [name].
  int getMeasurementCount(String name) {
    return _metrics[name]?.length ?? 0;
  }

  /// Gets all metrics as a map.
  Map<String, Duration> getAllAverages() {
    return Map.fromEntries(
      _metrics.keys
          .map((name) {
            final avg = getAverageTime(name);
            return avg != null ? MapEntry(name, avg) : null;
          })
          .whereType<MapEntry<String, Duration>>(),
    );
  }

  /// Gets a summary of all metrics.
  Map<String, Map<String, dynamic>> getSummary() {
    return _metrics.map((name, times) {
      final avg = getAverageTime(name);
      final min = getMinTime(name);
      final max = getMaxTime(name);

      return MapEntry(name, {
        'count': times.length,
        'average': avg?.inMilliseconds,
        'min': min?.inMilliseconds,
        'max': max?.inMilliseconds,
      });
    });
  }

  /// Clears all metrics.
  void clear() {
    _timers.clear();
    _metrics.clear();
  }

  @override
  String toString() {
    final buffer = StringBuffer('PerformanceService:\n');
    for (final entry in _metrics.entries) {
      final avg = getAverageTime(entry.key);
      buffer.writeln(
        '  ${entry.key}: ${entry.value.length} measurements, '
        'avg=${avg?.inMilliseconds ?? 0}ms',
      );
    }
    return buffer.toString();
  }
}
