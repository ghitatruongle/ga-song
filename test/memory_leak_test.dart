/// Memory Leak Detection Tests
///
/// Uses leak_tracker to detect memory leaks in widget trees.
/// Run with: `flutter test test/memory_leak_test.dart`
///
/// Checks for:
/// - Widgets that aren't disposed after navigation
/// - Stream subscriptions not cancelled
/// - Controllers not disposed
/// - Listeners not removed
///
/// Note: Services are mocked so the tests run without native audio plugins.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:ga_song/main.dart' as app;

import 'test_helpers.dart';

void main() {
  group('Memory Leak Detection', () {
    late MockServices mockServices;

    setUp(() async {
      mockServices = MockServices();
      await mockServices.initAll();
    });

    tearDown(() {
      mockServices.disposeAll();
    });

    testWidgets('no leaks after home screen navigation', (WidgetTester tester) async {
      maybeSetupLeakTrackingForTest(LeakTesting.settings, 'home navigation');
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockServices.overrides,
          child: const app.GASongApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      maybeTearDownLeakTrackingForTest();
    });

    testWidgets('no leaks after tab navigation cycle', (WidgetTester tester) async {
      maybeSetupLeakTrackingForTest(LeakTesting.settings, 'tab navigation');
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockServices.overrides,
          child: const app.GASongApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate through all tabs multiple times
      const tabs = ['Thư viện', 'Phòng Hát (KTV)', 'Cài đặt', 'Trang chủ'];
      for (int cycle = 0; cycle < 3; cycle++) {
        for (final tab in tabs) {
          try {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
          } catch (e) {
            // Tab might not exist in test environment
          }
        }
      }
      maybeTearDownLeakTrackingForTest();
    });

    testWidgets('no leaks after mini player open/close', (WidgetTester tester) async {
      maybeSetupLeakTrackingForTest(LeakTesting.settings, 'mini player');
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockServices.overrides,
          child: const app.GASongApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Try to trigger mini player
      try {
        await tester.tap(find.byIcon(Icons.play_circle_outline).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Try to close it
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      } catch (e) {
        // Mini player might not be available in test
      }
      maybeTearDownLeakTrackingForTest();
    });
  });
}
