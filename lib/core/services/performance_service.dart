import '../logging/app_logger.dart';
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

  /// Maximum entries retained per metric name to prevent unbounded memory growth.
  static const int _maxEntriesPerMetric = 100;

  /// Starts a timer with the given [name].
  void startTimer(final String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// Stops the timer with [name] and records the duration.
  ///
  /// Returns the elapsed duration.
  Duration stopTimer(final String name) {
    final timer = _timers.remove(name);
    if (timer == null) {
      throw StateError('Timer $name not found');
    }

    timer.stop();
    final entries = _metrics.putIfAbsent(name, () => []);
    entries.add(timer.elapsed);
    // Prune to prevent unbounded memory growth
    if (entries.length > _maxEntriesPerMetric) {
      entries.removeRange(0, entries.length - _maxEntriesPerMetric);
    }

    if (kDebugMode) {
      AppLogger.d(
        'performance.service',
        '$name took ${timer.elapsedMilliseconds}ms',
      );
    }

    return timer.elapsed;
  }

  /// Measures the duration of [operation] and records it.
  T measure<T>(final String name, final T Function() operation) {
    startTimer(name);
    try {
      return operation();
    } finally {
      stopTimer(name);
    }
  }

  /// Measures the duration of an async [operation] and records it.
  Future<T> measureAsync<T>(
    final String name,
    final Future<T> Function() operation,
  ) async {
    startTimer(name);
    try {
      return await operation();
    } finally {
      stopTimer(name);
    }
  }

  /// Gets the average duration for [name].
  Duration? getAverageTime(final String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    final totalMicros = times.fold<int>(
      0,
      (final sum, final duration) => sum + duration.inMicroseconds,
    );

    return Duration(microseconds: totalMicros ~/ times.length);
  }

  /// Gets the minimum duration for [name].
  Duration? getMinTime(final String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    return times.reduce((final a, final b) => a < b ? a : b);
  }

  /// Gets the maximum duration for [name].
  Duration? getMaxTime(final String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    return times.reduce((final a, final b) => a > b ? a : b);
  }

  /// Gets the number of measurements for [name].
  int getMeasurementCount(final String name) => _metrics[name]?.length ?? 0;

  /// Gets all metrics as a map.
  Map<String, Duration> getAllAverages() => Map.fromEntries(
    _metrics.keys.map((final name) {
      final avg = getAverageTime(name);
      return avg != null ? MapEntry(name, avg) : null;
    }).whereType<MapEntry<String, Duration>>(),
  );

  /// Gets a summary of all metrics.
  Map<String, Map<String, dynamic>> getSummary() =>
      _metrics.map((final name, final times) {
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
