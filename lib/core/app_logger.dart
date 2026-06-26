import 'package:flutter/foundation.dart';

/// Log levels for structured logging.
enum LogLevel { debug, info, warning, error }

/// Structured logger for the application.
///
/// Replaces scattered `debugPrint` calls with contextual, level-aware logging.
/// In debug mode, logs are printed to the console. In release mode, logs are
/// buffered and can be flushed to a crash reporting service.
///
/// Usage:
/// ```dart
/// final log = AppLogger('AudioEngine');
/// log.info('Playback started');
/// log.error('Failed to load source', error, stackTrace);
/// ```
class AppLogger {
  AppLogger(this.tag);

  /// Service/component tag for log messages.
  final String tag;

  /// Global minimum log level. Messages below this level are ignored.
  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Buffer for release-mode logs (for crash reporting).
  static final List<String> _buffer = [];
  static const int _maxBufferSize = 100;

  /// Logs a debug message (only in debug mode).
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Logs an informational message.
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Logs a warning message.
  void warning(String message, [Object? error]) {
    final msg = error != null ? '$message: $error' : message;
    _log(LogLevel.warning, msg);
  }

  /// Logs an error with optional stack trace.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    var msg = message;
    if (error != null) msg += '\n  Error: $error';
    if (stackTrace != null && kDebugMode) {
      msg += '\n  Stack: $stackTrace';
    }
    _log(LogLevel.error, msg);
  }

  void _log(LogLevel level, String message) {
    if (level.index < minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final levelStr = level.name.toUpperCase().padRight(7);
    final formatted = '$timestamp $levelStr [$tag] $message';

    if (kDebugMode) {
      debugPrint(formatted);
    } else {
      // Buffer for crash reporting
      _buffer.add(formatted);
      if (_buffer.length > _maxBufferSize) {
        _buffer.removeAt(0);
      }
    }
  }

  /// Returns a copy of the log buffer (for crash reporting).
  static List<String> getBuffer() => List.unmodifiable(_buffer);

  /// Clears the log buffer.
  static void clearBuffer() => _buffer.clear();
}
