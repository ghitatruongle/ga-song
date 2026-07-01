import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    final lines = <String>[];
    void capture(String line) => lines.add(line);

    setUp(() {
      lines.clear();
      AppLogger.init(minLevel: LogLevel.debug, sink: capture);
    });

    test('debug message is captured at LogLevel.debug', () {
      AppLogger.d('test', 'hello');
      expect(lines, hasLength(1));
      expect(lines.first, contains('[D]'));
      expect(lines.first, contains('test'));
      expect(lines.first, contains('hello'));
    });

    test('info message is captured', () {
      AppLogger.i('test', 'starting up');
      expect(lines.first, contains('[I]'));
    });

    test('warn message is captured', () {
      AppLogger.w('test', 'deprecation', error: StateError('old'));
      expect(lines.first, contains('[W]'));
      expect(lines.first, contains('deprecation'));
      expect(lines.first, contains('Bad state'));
    });

    test('error message includes stack trace when provided', () {
      AppLogger.e('test', 'failed', error: 'boom', stack: StackTrace.current);
      expect(lines.first, contains('[E]'));
      expect(lines.first, contains('failed'));
    });

    test('fatal message is captured', () {
      AppLogger.f('test', 'crash');
      expect(lines.first, contains('[F]'));
    });

    test('messages below minLevel are filtered out', () {
      AppLogger.init(minLevel: LogLevel.warn, sink: capture);
      lines.clear();
      AppLogger.d('test', 'hidden');
      AppLogger.i('test', 'hidden');
      AppLogger.w('test', 'visible');
      expect(lines, hasLength(1));
      expect(lines.first, contains('[W]'));
    });

    test('init can swap sink', () {
      final other = <String>[];
      AppLogger.init(minLevel: LogLevel.debug, sink: other.add);
      AppLogger.i('test', 'redirected');
      expect(other, hasLength(1));
      expect(lines, isEmpty);
    });
  });
}
