import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/utils/animation_utils.dart';

void main() {
  testWidgets('animationsEnabled returns true by default', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        expect(animationsEnabled(context), isTrue);
        return const SizedBox();
      }),
    ));
  });

  testWidgets('animationsEnabled returns false when disableAnimations is true',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          expect(animationsEnabled(context), isFalse);
          return const SizedBox();
        }),
      ),
    ));
  });
}
