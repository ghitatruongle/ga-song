import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/theme_utils.dart';

void main() {
  group('AdaptiveColors extension', () {
    testWidgets('light mode returns black87 for adaptive', (
      final tester,
    ) async {
      late Color captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final context) {
              captured = context.adaptive;
              return const SizedBox();
            },
          ),
          theme: ThemeData.light(),
          themeMode: ThemeMode.light,
        ),
      );
      expect(captured, Colors.black87);
    });

    testWidgets('dark mode returns white for adaptive', (final tester) async {
      late Color captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final context) {
              captured = context.adaptive;
              return const SizedBox();
            },
          ),
          theme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
        ),
      );
      expect(captured, Colors.white);
    });

    testWidgets('onAdaptive inverts adaptive', (final tester) async {
      late Color adaptiveLight;
      late Color onAdaptiveLight;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final context) {
              adaptiveLight = context.adaptive;
              onAdaptiveLight = context.onAdaptive;
              return const SizedBox();
            },
          ),
          themeMode: ThemeMode.light,
        ),
      );
      expect(adaptiveLight, Colors.black87);
      expect(onAdaptiveLight, Colors.white);
    });

    testWidgets('adaptiveSecondary in dark mode returns white70', (
      final tester,
    ) async {
      late Color captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final context) {
              captured = context.adaptiveSecondary;
              return const SizedBox();
            },
          ),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
        ),
      );
      expect(captured, Colors.white70);
    });
  });
}
