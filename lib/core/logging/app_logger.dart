import 'package:flutter/foundation.dart';

/// Log severity levels, ordered from least to most severe.
enum LogLevel { debug, info, warn, error, fatal }

/// Static logger facade with level filtering and pluggable sink.
///
/// Initialize once in `main()` before any other service starts:
///
/// ```dart
/// AppLogger.init(
///   minLevel: kDebugMode ? LogLevel.debug : LogLevel.warn,
///   mirrorToCrashReporter: !kDebugMode,
/// );
/// ```
class AppLogger {
  static LogLevel _minLevel = LogLevel.debug;
  static void Function(String line)? _sink;
  static void Function(String tag, String message, {Object? error, StackTrace? stack})? _crashHook;

  /// Configures the global logger. Call once at app startup.
  static void init({
    LogLevel minLevel = LogLevel.debug,
    void Function(String line)? sink,
    bool mirrorToCrashReporter = false,
  }) {
    _minLevel = minLevel;
    _sink = sink ?? (kDebugMode ? _debugPrintSink : _noopSink);
    if (mirrorToCrashReporter) {
      _crashHook = (tag, msg, {error, stack}) {
        // Delegated to DebugCrashReporter by main.dart after init.
        _pendingCrashReports.add((tag: tag, msg: msg, error: error, stack: stack));
      };
    }
  }

  static final List<({String tag, String msg, Object? error, StackTrace? stack})>
      _pendingCrashReports = [];

  /// Drains any reports buffered before main.dart wired the crash reporter.
  /// Called by main.dart after DebugCrashReporter.init().
  static List<({String tag, String msg, Object? error, StackTrace? stack})>
      drainPendingCrashReports() {
    final out = List.of(_pendingCrashReports);
    _pendingCrashReports.clear();
    return out;
  }

  static void d(String tag, String message, {Object? error, StackTrace? stack}) =>
      _log(LogLevel.debug, tag, message, error: error, stack: stack);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message, {Object? error, StackTrace? stack}) =>
      _log(LogLevel.warn, tag, message, error: error, stack: stack);

  static void e(String tag, String message, {Object? error, StackTrace? stack}) =>
      _log(LogLevel.error, tag, message, error: error, stack: stack);

  static void f(String tag, String message, {Object? error, StackTrace? stack}) {
    _log(LogLevel.fatal, tag, message, error: error, stack: stack);
    _crashHook?.call(tag, message, error: error, stack: stack);
  }

  static void _log(LogLevel level, String tag, String message,
      {Object? error, StackTrace? stack}) {
    if (level.index < _minLevel.index) return;
    final levelStr = _levelTag(level);
    final buffer = StringBuffer('$levelStr [$tag] $message');
    if (error != null) buffer.write(' | error=$error');
    if (stack != null) buffer.write('\n$stack');
    _sink?.call(buffer.toString());
  }

  static String _levelTag(LogLevel level) => switch (level) {
        LogLevel.debug => '[D]',
        LogLevel.info => '[I]',
        LogLevel.warn => '[W]',
        LogLevel.error => '[E]',
        LogLevel.fatal => '[F]',
      };

  static void _debugPrintSink(String line) {
    // ignore: avoid_print
    debugPrint(line);
  }

  static void _noopSink(String line) {
    // intentional no-op for release
  }
}
