import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/services/error_handler_service.dart';
import 'package:ga_song/core/exceptions/app_exception.dart';
import 'package:ga_song/core/utils/result.dart';
import 'package:ga_song/core/crash_reporter.dart';

void main() {
  group('ErrorHandlerService', () {
    late ErrorHandlerService service;

    setUp(() {
      service = ErrorHandlerService(DebugCrashReporter());
    });

    group('handle', () {
      test('returns Success for successful operation', () {
        final result = service.handle(() => 42);

        expect(result, isA<Success<int>>());
        expect(result.data, equals(42));
      });

      test('returns Failure for AppException', () {
        final result = service.handle(() {
          throw const DatabaseException('DB error');
        });

        expect(result, isA<Failure<int>>());
        expect(result.error, equals('DB error'));
      });

      test('returns Failure for unexpected exception', () {
        final result = service.handle(() {
          throw Exception('Unexpected');
        });

        expect(result, isA<Failure<int>>());
        expect(result.error, contains('Unexpected error'));
      });

      test('preserves stack trace in Failure', () {
        final result = service.handle(() {
          throw const DatabaseException('DB error');
        });

        expect(result, isA<Failure<int>>());
        final failure = result as Failure;
        expect(failure.stackTrace, isNotNull);
      });

      test('preserves exception in Failure', () {
        final result = service.handle(() {
          throw const DatabaseException('DB error');
        });

        expect(result, isA<Failure<int>>());
        final failure = result as Failure;
        expect(failure.exception, isA<DatabaseException>());
      });
    });

    group('handleAsync', () {
      test('returns Success for successful async operation', () async {
        final result = await service.handleAsync(() async => 42);

        expect(result, isA<Success<int>>());
        expect(result.data, equals(42));
      });

      test('returns Failure for async AppException', () async {
        final result = await service.handleAsync(() async {
          throw const NetworkException('Network error');
        });

        expect(result, isA<Failure<int>>());
        expect(result.error, equals('Network error'));
      });

      test('returns Failure for unexpected async exception', () async {
        final result = await service.handleAsync(() async {
          throw Exception('Unexpected');
        });

        expect(result, isA<Failure<int>>());
        expect(result.error, contains('Unexpected error'));
      });
    });

    group('failureFromException', () {
      test('creates Failure from AppException', () {
        const exception = DatabaseException('DB error');
        final failure = ErrorHandlerService.failureFromException<int>(
          exception,
          StackTrace.current,
        );

        expect(failure, isA<Failure<int>>());
        expect(failure.error, equals('DB error'));
      });

      test('creates Failure from unexpected exception', () {
        final exception = Exception('Unexpected');
        final failure = ErrorHandlerService.failureFromException<int>(
          exception,
          StackTrace.current,
        );

        expect(failure, isA<Failure<int>>());
        expect(failure.error, contains('Unexpected error'));
      });
    });
  });
}
