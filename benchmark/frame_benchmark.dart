/// Frame Time Benchmark for G.A - Song
///
/// Measures frame rendering performance during typical user interactions.
/// Run with: `dart run benchmark/frame_benchmark.dart`
///
/// Output: JSON with frame timing statistics
/// - avg_frame_ms: Average frame time
/// - p50_frame_ms: Median frame time
/// - p90_frame_ms: 90th percentile
/// - p99_frame_ms: 99th percentile (target < 16ms for 60fps)
/// - jank_count: Frames > 16ms
/// - severe_jank_count: Frames > 32ms

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ga_song/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Frame Time Benchmark', () {
    testWidgets('measure frame performance during navigation', (WidgetTester tester) async {
      // Setup app
      await tester.pumpWidget(const app.GASongApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final frameTimes = <int>[];
      final frameCallbackCompleter = Completer<void>();

      // Register frame callback to measure frame times
      WidgetsBinding.instance.addPersistentFrameCallback((Duration timestamp) {
        frameTimes.add(timestamp.inMicroseconds);
      });

      // Simulate user interactions
      await _simulateInteractions(tester);

      // Wait a bit more to collect idle frames
      await tester.pump(const Duration(seconds: 2));

      // Remove callback
      WidgetsBinding.instance.addPersistentFrameCallback((Duration timestamp) {
        // No-op, just to remove previous callback
        if (frameCallbackCompleter.isCompleted) return;
      });

      // Calculate frame deltas
      if (frameTimes.length < 2) {
        print('Not enough frames collected');
        exit(1);
      }

      final frameDeltas = <int>[];
      for (int i = 1; i < frameTimes.length; i++) {
        final delta = frameTimes[i] - frameTimes[i - 1];
        if (delta > 0 && delta < 100000) { // Filter outliers (>100ms)
          frameDeltas.add(delta);
        }
      }

      frameDeltas.sort();
      final count = frameDeltas.length;
      final sum = frameDeltas.fold<int>(0, (a, b) => a + b);
      final avg = sum / count;
      final p50 = frameDeltas[(count * 0.5).floor()];
      final p90 = frameDeltas[(count * 0.9).floor()];
      final p99 = frameDeltas[(count * 0.99).floor()];
      final jankCount = frameDeltas.where((d) => d > 16000).length; // > 16ms
      const severeJankThreshold = 32000; // > 32ms
      final severeJankCount = frameDeltas.where((d) => d > severeJankThreshold).length;

      final results = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'flutter_version': '3.32.0',
        'total_frames': count,
        'avg_frame_us': avg.round(),
        'avg_frame_ms': (avg / 1000).toStringAsFixed(2),
        'p50_frame_us': p50,
        'p50_frame_ms': (p50 / 1000).toStringAsFixed(2),
        'p90_frame_us': p90,
        'p90_frame_ms': (p90 / 1000).toStringAsFixed(2),
        'p99_frame_us': p99,
        'p99_frame_ms': (p99 / 1000).toStringAsFixed(2),
        'jank_count': jankCount,
        'jank_percent': ((jankCount / count) * 100).toStringAsFixed(2),
        'severe_jank_count': severeJankCount,
        'severe_jank_percent': ((severeJankCount / count) * 100).toStringAsFixed(2),
        'target_p99_16ms': p99 <= 16000,
        'target_jank_5pct': (jankCount / count) <= 0.05,
      };

      // Write results
      final resultsDir = Directory('benchmark/results');
      if (!resultsDir.existsSync()) {
        resultsDir.createSync(recursive: true);
      }
      final resultsFile = File('benchmark/results/frame_benchmark_${DateTime.now().millisecondsSinceEpoch}.json');
      resultsFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(results));

      print('=== FRAME TIME BENCHMARK RESULTS ===');
      print('Total frames: $count');
      print('Avg: ${results['avg_frame_ms']}ms');
      print('P50: ${results['p50_frame_ms']}ms');
      print('P90: ${results['p90_frame_ms']}ms');
      print('P99: ${results['p99_frame_ms']}ms');
      print('Jank (>16ms): $jankCount (${results['jank_percent']}%)');
      print('Severe Jank (>32ms): $severeJankCount (${results['severe_jank_percent']}%)');
      print('Target P99 < 16ms: ${(results['target_p99_16ms'] as bool) ? "PASS" : "FAIL"}');
      print('Target Jank < 5%: ${(results['target_jank_5pct'] as bool) ? "PASS" : "FAIL"}');
      print('Results saved to: ${resultsFile.path}');

      // Exit with appropriate code for CI
      if (!(results['target_p99_16ms'] as bool) || !(results['target_jank_5pct'] as bool)) {
        exit(1);
      }
    });
  });
}

Future<void> _simulateInteractions(WidgetTester tester) async {
  // Navigate through tabs
  final tabs = ['Thư viện', 'Phòng Hát (KTV)', 'Cài đặt', 'Trang chủ'];
  
  for (final tab in tabs) {
    try {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    } catch (e) {
      // Tab might not exist, continue
    }
  }

  // Scroll in library
  try {
    await tester.tap(find.text('Thư viện'));
    await tester.pumpAndSettle();
    
    // Simulate scroll
    for (int i = 0; i < 10; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 16));
    }
  } catch (e) {
    // Continue
  }

  // Open now playing
  try {
    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  } catch (e) {
    // Continue
  }
}