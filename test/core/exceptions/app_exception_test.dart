import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/exceptions/app_exception.dart';

void main() {
  group('AppException', () {
    test('DatabaseException contains message', () {
      const exception = DatabaseException('Database error');

      expect(exception.message, equals('Database error'));
      expect(exception.toString(), contains('DatabaseException'));
      expect(exception.toString(), contains('Database error'));
    });

    test('DatabaseException preserves stack trace', () {
      final trace = StackTrace.current;
      final exception = DatabaseException('Error', trace);

      expect(exception.stackTrace, equals(trace));
    });

    test('AudioEngineException contains message', () {
      const exception = AudioEngineException('Audio error');

      expect(exception.message, equals('Audio error'));
      expect(exception.toString(), contains('AudioEngineException'));
    });

    test('NetworkException contains message and status code', () {
      const exception = NetworkException('Not found', null, 404);

      expect(exception.message, equals('Not found'));
      expect(exception.statusCode, equals(404));
    });

    test('NetworkException works without status code', () {
      const exception = NetworkException('Connection failed');

      expect(exception.message, equals('Connection failed'));
      expect(exception.statusCode, isNull);
    });

    test('FileException contains message and path', () {
      const exception = FileException('File not found', null, '/path/to/file');

      expect(exception.message, equals('File not found'));
      expect(exception.path, equals('/path/to/file'));
    });

    test('FileException works without path', () {
      const exception = FileException('IO error');

      expect(exception.message, equals('IO error'));
      expect(exception.path, isNull);
    });

    test('CacheException contains message', () {
      const exception = CacheException('Cache corrupted');

      expect(exception.message, equals('Cache corrupted'));
      expect(exception.toString(), contains('CacheException'));
    });

    test('SettingsException contains message', () {
      const exception = SettingsException('Invalid setting');

      expect(exception.message, equals('Invalid setting'));
      expect(exception.toString(), contains('SettingsException'));
    });

    test('ParseException contains message and input', () {
      const exception = ParseException('Invalid JSON', null, '{"bad": true}');

      expect(exception.message, equals('Invalid JSON'));
      expect(exception.input, equals('{"bad": true}'));
    });

    test('ParseException works without input', () {
      const exception = ParseException('Parse error');

      expect(exception.message, equals('Parse error'));
      expect(exception.input, isNull);
    });

    test('PlatformException contains message and platform', () {
      const exception = PlatformException('Not supported', null, 'android');

      expect(exception.message, equals('Not supported'));
      expect(exception.platform, equals('android'));
    });

    test('PlatformException works without platform', () {
      const exception = PlatformException('Channel error');

      expect(exception.message, equals('Channel error'));
      expect(exception.platform, isNull);
    });
  });
}
