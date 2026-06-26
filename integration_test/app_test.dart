/// Integration test for G.A - Song main flow.
///
/// Runs on a real device or emulator to verify the full app startup,
/// navigation, and basic playlist interaction.
///
/// ## Running
/// ```bash
/// flutter test integration_test/app_test.dart
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ga_song/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration', () {
    testWidgets('full startup and navigation flow', (tester) async {
      // Note: This test requires a running emulator/device.
      // On headless CI, use `flutter test integration_test --device-id=web`
      // or ensure a virtual display is available for desktop.

      await tester.pumpWidget(const app.GASongApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify the app renders the home screen
      expect(find.text('G.A'), findsOneWidget);

      // Navigate to the library tab via sidebar
      await tester.tap(find.text('Thư viện'));
      await tester.pumpAndSettle();

      // Navigate to KTV tab
      await tester.tap(find.text('Phòng Hát (KTV)'));
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
    });
  });
}
