/// Startup Benchmark for G.A - Song
///
/// Measures cold start time from process launch to first frame rendered.
/// Run with: `dart run benchmark/startup_benchmark.dart`
///
/// Output: JSON with timing breakdown
/// - engine_init_ms: Flutter engine initialization
/// - services_init_ms: Service initialization (settings, DB, audio)
/// - first_frame_ms: Time to first frame
/// - interactive_ms: Time to interactive (user can interact)
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ga_song/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Startup Benchmark', () {
    testWidgets('measure cold start time', (final WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Measure engine initialization
      final engineInitStopwatch = Stopwatch()..start();
      await tester.pumpWidget(const app.GASongApp());
      engineInitStopwatch.stop();

      // Measure first frame
      final firstFrameStopwatch = Stopwatch()..start();
      await tester.pump();
      firstFrameStopwatch.stop();

      // Measure interactive (wait for all async init to complete)
      final interactiveStopwatch = Stopwatch()..start();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      interactiveStopwatch.stop();

      stopwatch.stop();

      final results = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'flutter_version': '3.32.0',
        'total_ms': stopwatch.elapsedMilliseconds,
        'engine_init_ms': engineInitStopwatch.elapsedMilliseconds,
        'first_frame_ms': firstFrameStopwatch.elapsedMilliseconds,
        'interactive_ms': interactiveStopwatch.elapsedMilliseconds,
        'passed': stopwatch.elapsedMilliseconds < 2000, // Target: < 2s
      };

      // Write results
      final resultsDir = Directory('benchmark/results');
      if (!resultsDir.existsSync()) {
        resultsDir.createSync(recursive: true);
      }
      final resultsFile = File('benchmark/results/startup_benchmark_${DateTime.now().millisecondsSinceEpoch}.json');
      resultsFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));

      print('=== STARTUP BENCHMARK RESULTS ===');
      print('Total: ${results['total_ms']}ms');
      print('Engine Init: ${results['engine_init_ms']}ms');
      print('First Frame: ${results['first_frame_ms']}ms');
      print('Interactive: ${results['interactive_ms']}ms');
      print('Target (< 2000ms): ${(results['passed'] as bool) ? "PASS" : "FAIL"}');
      print('Results saved to: ${resultsFile.path}');

      // Exit with appropriate code for CI
      if (!(results['passed'] as bool)) {
        exit(1);
      }
    });
  });
}