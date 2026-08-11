import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/theme/theme_extensions.dart';
import 'package:ga_song/core/theme/tokens.dart';
import 'package:ga_song/ui/utils/theme_helpers.dart';

void main() {
  group('ThemeSpacing', () {
    testWidgets('ThemeSpacing.of(context).md returns AppSpacing.md', (
      final tester,
    ) async {
      late double observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppSpacingExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              observed = ThemeSpacing.of(context).md;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed, AppSpacing.md);
    });

    testWidgets('ThemeSpacing exposes every token level', (final tester) async {
      late Map<String, double> observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppSpacingExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              final s = ThemeSpacing.of(context);
              observed = {
                'xxs': s.xxs,
                'xs': s.xs,
                'sm': s.sm,
                'md': s.md,
                'lg': s.lg,
                'xl': s.xl,
                'xxl': s.xxl,
              };
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed['xxs'], AppSpacing.xxs);
      expect(observed['xs'], AppSpacing.xs);
      expect(observed['sm'], AppSpacing.sm);
      expect(observed['md'], AppSpacing.md);
      expect(observed['lg'], AppSpacing.lg);
      expect(observed['xl'], AppSpacing.xl);
      expect(observed['xxl'], AppSpacing.xxl);
    });

    testWidgets('ThemeSpacing.all() defaults to md', (final tester) async {
      late EdgeInsets observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppSpacingExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              observed = ThemeSpacing.of(context).all();
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed, const EdgeInsets.all(AppSpacing.md));
    });

    testWidgets('ThemeSpacing.all(8) returns all-8', (final tester) async {
      late EdgeInsets observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppSpacingExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              observed = ThemeSpacing.of(context).all(AppSpacing.sm);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed, const EdgeInsets.all(8));
    });
  });

  group('ThemeRadius', () {
    testWidgets('ThemeRadius.of(context).md returns AppRadius.md', (
      final tester,
    ) async {
      late double observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppRadiusExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              observed = ThemeRadius.of(context).md;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed, AppRadius.md);
    });

    testWidgets('ThemeRadius exposes every token level', (final tester) async {
      late Map<String, double> observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppRadiusExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              final r = ThemeRadius.of(context);
              observed = {'sm': r.sm, 'md': r.md, 'lg': r.lg, 'xl': r.xl};
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed['sm'], AppRadius.sm);
      expect(observed['md'], AppRadius.md);
      expect(observed['lg'], AppRadius.lg);
      expect(observed['xl'], AppRadius.xl);
    });

    testWidgets('ThemeRadius.circular() defaults to md', (final tester) async {
      late BorderRadius observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppRadiusExtension.defaults()]),
          home: Builder(
            builder: (final context) {
              observed = ThemeRadius.of(context).circular();
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed, BorderRadius.circular(AppRadius.md));
    });
  });

  group('Missing extension', () {
    test('AppSpacingExtension is null on a default ThemeData', () {
      // The null-bang in ThemeSpacing._e surfaces a TypeError when the
      // extension is missing on the active theme. This protects callers
      // from silently returning null defaults.
      expect(ThemeData().extension<AppSpacingExtension>(), isNull);
    });
  });
}
