import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/screens/blurred_background.dart';

void main() {
  group('BlurredBackground', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlurredBackground(blurLevel: 10, child: Text('test child')),
          ),
        ),
      );

      expect(find.text('test child'), findsOneWidget);
    });

    testWidgets('applies ImageFiltered when blurLevel > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlurredBackground(
              blurLevel: 15,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('skips ImageFiltered when blurLevel is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlurredBackground(
              blurLevel: 0,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(ImageFiltered), findsNothing);
    });
  });
}
