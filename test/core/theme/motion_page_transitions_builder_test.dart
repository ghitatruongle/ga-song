import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/theme/motion_page_transitions_builder.dart';

void main() {
  test('MotionPageTransitionsBuilder instantiates without error', () {
    const builder = MotionPageTransitionsBuilder();
    expect(builder, isNotNull);
  });

  testWidgets('buildTransitions returns child when disableAnimations is true',
      (tester) async {
    const builder = MotionPageTransitionsBuilder();
    const child = Text('child');
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            final route = PageRouteBuilder(
              pageBuilder: (_, _, _) => const SizedBox(),
            );
            final widget = builder.buildTransitions(
              route,
              context,
              const AlwaysStoppedAnimation<double>(0),
              const AlwaysStoppedAnimation<double>(0),
              child,
            );
            expect(widget, same(child));
            return const SizedBox();
          },
        ),
      ),
    ));
  });

  testWidgets('buildTransitions returns a Widget when animations enabled',
      (tester) async {
    const builder = MotionPageTransitionsBuilder();
    const child = Text('child');
    Widget? produced;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          final route = PageRouteBuilder(
            pageBuilder: (_, _, _) => const SizedBox(),
          );
          produced = builder.buildTransitions(
            route,
            context,
            const AlwaysStoppedAnimation<double>(0.5),
            const AlwaysStoppedAnimation<double>(0),
            child,
          );
          return const SizedBox();
        },
      ),
    ));
    expect(produced, isA<Widget>());
  });
}
