import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/utils/animation_utils.dart';

void main() {
  testWidgets('animationsEnabled returns true by default', (
    final tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (final context) {
            expect(animationsEnabled(context), isTrue);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets(
    'animationsEnabled returns false when disableAnimations is true',
    (final tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (final context) {
                expect(animationsEnabled(context), isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    },
  );
}
