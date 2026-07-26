import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/motion/app_motion.dart';

void main() {
  group('AppDurations', () {
    test('durational scale is monotonic', () {
      expect(
        AppDurations.micro.inMilliseconds,
        lessThan(AppDurations.short.inMilliseconds),
      );
      expect(
        AppDurations.short.inMilliseconds,
        lessThan(AppDurations.medium.inMilliseconds),
      );
      expect(
        AppDurations.medium.inMilliseconds,
        lessThan(AppDurations.long.inMilliseconds),
      );
      expect(
        AppDurations.long.inMilliseconds,
        lessThan(AppDurations.extended.inMilliseconds),
      );
    });

    test('all durations are non-negative', () {
      for (final d in [
        AppDurations.micro,
        AppDurations.short,
        AppDurations.medium,
        AppDurations.long,
        AppDurations.extended,
      ]) {
        expect(d.inMilliseconds, greaterThanOrEqualTo(0));
      }
    });
  });

  group('AppCurves', () {
    test('curves are non-null Curve instances', () {
      expect(AppCurves.standard, isA<Curve>());
      expect(AppCurves.decelerate, isA<Curve>());
      expect(AppCurves.accelerate, isA<Curve>());
      expect(AppCurves.emphasized, isA<Curve>());
    });
  });

  group('AppMotion.applyReduce', () {
    test('returns zero duration when reduceMotion is true', () {
      final d = AppMotion.applyReduce(AppDurations.medium, reduceMotion: true);
      expect(d, Duration.zero);
    });

    test('returns original duration when reduceMotion is false', () {
      final d = AppMotion.applyReduce(AppDurations.medium, reduceMotion: false);
      expect(d, AppDurations.medium);
    });
  });

  group('MotionPreferences', () {
    test('default reduceMotion is false', () {
      const prefs = MotionPreferences();
      expect(prefs.reduceMotion, isFalse);
    });

    test('copyWith toggles reduceMotion', () {
      const prefs = MotionPreferences();
      final updated = prefs.copyWith(reduceMotion: true);
      expect(updated.reduceMotion, isTrue);
    });
  });

  group('AppMotion.fadeThrough', () {
    testWidgets('builds without error given an Animation', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: AppDurations.short,
      );
      final widget = AppMotion.fadeThrough(
        const SizedBox(width: 50, height: 50),
        controller,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      controller.value = 0.5;
      await tester.pump();
      expect(find.byType(SizedBox), findsOneWidget);
      controller.dispose();
    });
  });
}
