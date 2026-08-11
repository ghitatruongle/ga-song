import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/services/performance_service.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceService service;

    setUp(() {
      service = PerformanceService.instance;
      service.clear();
    });

    test('singleton returns same instance', () {
      final instance1 = PerformanceService.instance;
      final instance2 = PerformanceService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('startTimer and stopTimer records duration', () {
      service.startTimer('test');
      final duration = service.stopTimer('test');

      expect(duration.inMilliseconds, greaterThanOrEqualTo(0));
      expect(service.getMeasurementCount('test'), equals(1));
    });

    test('stopTimer throws for non-existent timer', () {
      expect(() => service.stopTimer('nonexistent'), throwsStateError);
    });

    test('measure records duration', () {
      final result = service.measure('test', () => 42);

      expect(result, equals(42));
      expect(service.getMeasurementCount('test'), equals(1));
    });

    test('measure records exception', () {
      expect(
        () => service.measure('test', () {
          throw Exception('test error');
        }),
        throwsException,
      );

      // Should still record the measurement
      expect(service.getMeasurementCount('test'), equals(1));
    });

    test('measureAsync records duration', () async {
      final result = await service.measureAsync('test', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      expect(result, equals(42));
      expect(service.getMeasurementCount('test'), equals(1));
    });

    test('getAverageTime returns null for no measurements', () {
      expect(service.getAverageTime('test'), isNull);
    });

    test('getAverageTime returns average', () {
      service.measure('test', () {});
      service.measure('test', () {});
      service.measure('test', () {});

      final avg = service.getAverageTime('test');
      expect(avg, isNotNull);
      expect(avg!.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('getMinTime returns minimum', () {
      service.measure('test', () {});
      service.measure('test', () {});

      final min = service.getMinTime('test');
      expect(min, isNotNull);
    });

    test('getMaxTime returns maximum', () {
      service.measure('test', () {});
      service.measure('test', () {});

      final max = service.getMaxTime('test');
      expect(max, isNotNull);
    });

    test('getAllAverages returns map of averages', () {
      service.measure('test1', () {});
      service.measure('test2', () {});

      final averages = service.getAllAverages();
      expect(averages.length, equals(2));
      expect(averages.containsKey('test1'), isTrue);
      expect(averages.containsKey('test2'), isTrue);
    });

    test('getSummary returns detailed summary', () {
      service.measure('test', () {});
      service.measure('test', () {});

      final summary = service.getSummary();
      expect(summary.length, equals(1));
      expect(summary['test'], isNotNull);
      expect(summary['test']!['count'], equals(2));
    });

    test('clear removes all metrics', () {
      service.measure('test', () {});
      service.clear();

      expect(service.getMeasurementCount('test'), equals(0));
      expect(service.getAverageTime('test'), isNull);
    });

    test('toString returns descriptive string', () {
      service.measure('test', () {});

      final str = service.toString();
      expect(str, contains('PerformanceService'));
      expect(str, contains('test'));
    });
  });
}
