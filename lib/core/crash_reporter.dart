import 'app_logger.dart';

/// Abstract interface for crash reporting.
///
/// Implementations can send crashes to services like Sentry, Firebase Crashlytics, etc.
/// The [DebugCrashReporter] logs to console; replace with a production reporter for release builds.
abstract class CrashReporter {
  /// Initializes the crash reporter.
  Future<void> init();

  /// Reports a non-fatal error.
  void reportError(Object error, StackTrace stackTrace, {String? context});

  /// Reports a fatal crash.
  void reportFatalError(Object error, StackTrace stackTrace);

  /// Sets the current user identifier for crash reports.
  void setUser(String? userId);

  /// Adds breadcrumb for debugging context.
  void addBreadcrumb(String message, {Map<String, dynamic>? data});

  /// Flushes any buffered reports.
  Future<void> flush();

  /// Disposes the reporter.
  void dispose();
}

/// Debug implementation that logs to console and buffers in [AppLogger].
class DebugCrashReporter implements CrashReporter {
  static final DebugCrashReporter _instance = DebugCrashReporter._();
  factory DebugCrashReporter() => _instance;
  DebugCrashReporter._();

  final _log = AppLogger('CrashReporter');

  @override
  Future<void> init() async {
    _log.info('DebugCrashReporter initialized');
  }

  @override
  void reportError(Object error, StackTrace stackTrace, {String? context}) {
    final ctx = context != null ? '[$context] ' : '';
    _log.warning('${ctx}Non-fatal error reported', error);
  }

  @override
  void reportFatalError(Object error, StackTrace stackTrace) {
    _log.error('FATAL crash reported', error, stackTrace);
  }

  @override
  void setUser(String? userId) {
    _log.debug('User set: $userId');
  }

  @override
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' $data' : '';
    _log.debug('Breadcrumb: $message$dataStr');
  }

  @override
  Future<void> flush() async {
    _log.debug('Flush requested (${AppLogger.getBuffer().length} buffered logs)');
  }

  @override
  void dispose() {
    _log.info('DebugCrashReporter disposed');
  }
}
