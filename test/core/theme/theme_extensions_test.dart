import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/theme/theme_extensions.dart';
import 'package:ga_song/core/theme/tokens.dart';

void main() {
  group('AppSpacingExtension', () {
    // Helper: build an AppSpacingExtension with the given md and zero for
    // all other fields. The lerp tests only assert on `md`, so other
    // field values are arbitrary — they just need to compile.
    AppSpacingExtension withMd(double md) =>
        AppSpacingExtension(xxs: 0, xs: 0, sm: 0, md: md, lg: 0, xl: 0, xxl: 0);

    test('lerp returns interpolated value at t=0.5', () {
      final a = withMd(8.0);
      final b = withMd(24.0);
      final lerped = a.lerp(b, 0.5);
      expect(lerped.md, 16.0);
    });

    test('lerp at t=0 returns source', () {
      final a = withMd(12.0);
      final b = withMd(24.0);
      expect(a.lerp(b, 0.0).md, 12.0);
    });

    test('lerp at t=1 returns target', () {
      final a = withMd(12.0);
      final b = withMd(24.0);
      expect(a.lerp(b, 1.0).md, 24.0);
    });

    test('default constructor uses AppSpacing tokens', () {
      const ext = AppSpacingExtension.defaults();
      expect(ext.md, AppSpacing.md);
      expect(ext.lg, AppSpacing.lg);
    });
  });

  group('AppRadiusExtension', () {
    test('default constructor uses AppRadius tokens', () {
      const ext = AppRadiusExtension.defaults();
      expect(ext.sm, AppRadius.sm);
      expect(ext.md, AppRadius.md);
      expect(ext.lg, AppRadius.lg);
      expect(ext.xl, AppRadius.xl);
    });

    test('lerp interpolates sm to md', () {
      const a = AppRadiusExtension(sm: 4.0, md: 8.0, lg: 12.0, xl: 16.0);
      const b = AppRadiusExtension(sm: 8.0, md: 16.0, lg: 24.0, xl: 32.0);
      final lerped = a.lerp(b, 0.5);
      expect(lerped.sm, 6.0);
      expect(lerped.md, 12.0);
    });
  });

  group('AppElevationExtension', () {
    test('lerp interpolates level0 to level2', () {
      const a = AppElevationExtension(
        level0: 0,
        level1: 0,
        level2: 0,
        level3: 0,
      );
      const b = AppElevationExtension(
        level0: 4,
        level1: 6,
        level2: 8,
        level3: 12,
      );
      final lerped = a.lerp(b, 0.5);
      expect(lerped.level0, 2.0);
      expect(lerped.level1, 3.0);
    });

    test('default uses AppElevation tokens', () {
      const ext = AppElevationExtension.defaults();
      expect(ext.level1, AppElevation.level1);
    });
  });

  group('ThemeData integration', () {
    testWidgets('extensions are retrievable via Theme.of(context)', (
      tester,
    ) async {
      const ext = AppSpacingExtension.defaults();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [ext]),
          home: Builder(
            builder: (context) {
              final spacing = Theme.of(
                context,
              ).extension<AppSpacingExtension>()!;
              return Text('md=${spacing.md}');
            },
          ),
        ),
      );
      expect(find.text('md=${AppSpacing.md}'), findsOneWidget);
    });
  });
}
