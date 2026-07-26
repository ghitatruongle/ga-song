import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('contains data', () {
        const result = Success(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.data, equals(42));
        expect(result.error, isNull);
      });

      test('supports nullable data', () {
        const result = Success<int?>(null);

        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('map transforms data', () {
        const result = Success(42);
        final mapped = result.map((data) => 'Value: $data');

        expect(mapped, isA<Success<String>>());
        expect(mapped.data, equals('Value: 42'));
      });

      test('flatMap transforms data', () {
        const result = Success(42);
        final mapped = result.flatMap((data) => Success('Value: $data'));

        expect(mapped, isA<Success<String>>());
        expect(mapped.data, equals('Value: 42'));
      });
    });

    group('Failure', () {
      test('contains error message', () {
        const result = Failure<int>('Something went wrong');

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.data, isNull);
        expect(result.error, equals('Something went wrong'));
      });

      test('map preserves error', () {
        const result = Failure<int>('Error message');
        final mapped = result.map((data) => 'Value: $data');

        expect(mapped, isA<Failure<String>>());
        expect(mapped.error, equals('Error message'));
      });

      test('flatMap preserves error', () {
        const result = Failure<int>('Error message');
        final mapped = result.flatMap((data) => Success('Value: $data'));

        expect(mapped, isA<Failure<String>>());
        expect(mapped.error, equals('Error message'));
      });

      test('toString returns error message', () {
        const result = Failure<int>('Error message');
        final str = result.toString();

        expect(str, contains('Failure'));
        expect(str, contains('Error message'));
      });
    });

    group('fold', () {
      test('calls onSuccess for Success', () {
        const result = Success(42);
        final output = result.fold(
          onSuccess: (data) => 'Got $data',
          onFailure: (message, _) => 'Error: $message',
        );

        expect(output, equals('Got 42'));
      });

      test('calls onFailure for Failure', () {
        const result = Failure<int>('Error');
        final output = result.fold(
          onSuccess: (data) => 'Got $data',
          onFailure: (message, _) => 'Error: $message',
        );

        expect(output, equals('Error: Error'));
      });
    });

    group('pattern matching', () {
      test('works with switch expressions', () {
        const Result<int> success = Success(42);
        const Result<int> failure = Failure('error');

        String message = switch (success) {
          Success(data: final d) => 'Got $d',
          Failure(message: final m) => 'Error: $m',
        };

        expect(message, equals('Got 42'));

        message = switch (failure) {
          Success(data: final d) => 'Got $d',
          Failure(message: final m) => 'Error: $m',
        };

        expect(message, equals('Error: error'));
      });
    });

    group('edge cases', () {
      test('handles stack trace correctly', () {
        final trace = StackTrace.current;
        final result = Failure<int>('Error', trace);

        expect(result.stackTrace, equals(trace));
      });

      test('handles exception correctly', () {
        final exception = Exception('Test exception');
        final result = Failure<int>('Error', null, exception);

        expect(result.exception, equals(exception));
      });
    });
  });
}
