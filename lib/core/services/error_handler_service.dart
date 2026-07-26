import '../logging/app_logger.dart';
import 'package:flutter/foundation.dart';

import '../exceptions/app_exception.dart';
import '../utils/result.dart';
import '../crash_reporter.dart';

/// Centralized error handling service.
///
/// Provides methods to handle errors consistently across the app,
/// including logging, reporting, and converting exceptions to [Result].
class ErrorHandlerService {
  final CrashReporter _crashReporter;

  ErrorHandlerService(this._crashReporter);

  /// Handles a synchronous operation and returns a [Result].
  ///
  /// Catches [AppException] and unexpected exceptions, logs them,
  /// and returns a [Failure] with the error message.
  Result<T> handle<T>(T Function() operation, {String? context}) {
    try {
      final result = operation();
      return Success(result);
    } on AppException catch (e, stack) {
      _reportError(e, stack, context: context);
      return Failure(e.message, stack, e);
    } catch (e, stack) {
      _reportError(e, stack, context: context);
      return Failure('Unexpected error: $e', stack, e);
    }
  }

  /// Handles an asynchronous operation and returns a [Result].
  ///
  /// Catches [AppException] and unexpected exceptions, logs them,
  /// and returns a [Failure] with the error message.
  Future<Result<T>> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } on AppException catch (e, stack) {
      _reportError(e, stack, context: context);
      return Failure(e.message, stack, e);
    } catch (e, stack) {
      _reportError(e, stack, context: context);
      return Failure('Unexpected error: $e', stack, e);
    }
  }

  /// Handles a stream operation and returns a [Result] for each event.
  ///
  /// Catches [AppException] and unexpected exceptions, logs them,
  /// and yields [Failure] for error events.
  Stream<Result<T>> handleStream<T>(
    Stream<T> stream, {
    String? context,
  }) async* {
    await for (final event in stream) {
      yield Success(event);
    }
  }

  /// Reports an error to the crash reporter and debug console.
  void _reportError(Object error, StackTrace stackTrace, {String? context}) {
    // Log to debug console
    if (kDebugMode) {
      AppLogger.w(
        'error_handler.service',
        'Error${context != null ? ' in $context' : ''}',
        error: error,
      );
      AppLogger.d('error_handler.service', 'stack', error: stackTrace);
    }

    // Report to crash reporter
    _crashReporter.reportError(error, stackTrace, context: context);
  }

  /// Creates a [Failure] from an exception.
  ///
  /// Use this when you want to convert an exception to a [Failure]
  /// without catching it.
  static Failure<T> failureFromException<T>(
    Object exception,
    StackTrace stackTrace, {
    String? context,
  }) {
    final message = exception is AppException
        ? exception.message
        : 'Unexpected error: $exception';

    return Failure(message, stackTrace, exception);
  }
}
