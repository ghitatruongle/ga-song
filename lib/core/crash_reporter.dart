import 'logging/app_logger.dart';

/// Abstract interface for crash reporting.
///
/// Implementations can send crashes to services like Sentry, Firebase Crashlytics, etc.
/// The [DebugCrashReporter] logs to console; replace with a production reporter for release builds.
abstract class CrashReporter {
  /// Initializes the crash reporter.
  Future<void> init();

  /// Reports a non-fatal error.
  void reportError(
    final Object error,
    final StackTrace stackTrace, {
    final String? context,
  });

  /// Reports a fatal crash.
  void reportFatalError(final Object error, final StackTrace stackTrace);

  /// Sets the current user identifier for crash reports.
  void setUser(final String? userId);

  /// Adds breadcrumb for debugging context.
  void addBreadcrumb(final String message, {final Map<String, dynamic>? data});

  /// Flushes any buffered reports.
  Future<void> flush();

  /// Disposes the reporter.
  void dispose();
}

/// Debug implementation that logs to console via [AppLogger].
class DebugCrashReporter implements CrashReporter {
  static const String _tag = 'crash.reporter';

  static final DebugCrashReporter _instance = DebugCrashReporter._();
  factory DebugCrashReporter() => _instance;
  DebugCrashReporter._();

  @override
  Future<void> init() async {
    AppLogger.i(_tag, 'DebugCrashReporter initialized');
  }

  @override
  void reportError(
    final Object error,
    final StackTrace stackTrace, {
    final String? context,
  }) {
    final ctx = context != null ? '[$context] ' : '';
    AppLogger.w(
      _tag,
      '${ctx}Non-fatal error reported',
      error: error,
      stack: stackTrace,
    );
  }

  @override
  void reportFatalError(final Object error, final StackTrace stackTrace) {
    AppLogger.f(_tag, 'FATAL crash reported', error: error, stack: stackTrace);
  }

  @override
  void setUser(final String? userId) {
    AppLogger.d(_tag, 'User set: $userId');
  }

  @override
  void addBreadcrumb(final String message, {final Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' $data' : '';
    AppLogger.d(_tag, 'Breadcrumb: $message$dataStr');
  }

  @override
  Future<void> flush() async {
    final pending = AppLogger.drainPendingCrashReports();
    AppLogger.d(
      _tag,
      'Flush requested (${pending.length} buffered reports drained)',
    );
  }

  @override
  void dispose() {
    AppLogger.i(_tag, 'DebugCrashReporter disposed');
  }
}
