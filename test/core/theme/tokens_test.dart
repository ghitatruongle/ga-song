import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:ga_song/core/theme/tokens.dart';

void main() {
  group('AppColors', () {
    test('seed colors are non-null', () {
      expect(AppColors.seedPrimary, isA<Color>());
      expect(AppColors.seedSecondary, isA<Color>());
      expect(AppColors.seedTertiary, isA<Color>());
    });

    test('signature colors are stable (visual identity)', () {
      // Locked hex values — changing breaks brand identity
      expect(AppColors.seedPrimary.toARGB32(), 0xFF6750A4);
      expect(AppColors.accent.toARGB32(), 0xFFD0BCFF);
    });
  });

  group('AppSpacing', () {
    test('4px grid is preserved', () {
      expect(AppSpacing.xxs, 2.0);
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
    });
  });

  group('AppRadius', () {
    test('scale is monotonic', () {
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
    });
  });

  group('AppElevation', () {
    test('levels are non-negative', () {
      expect(AppElevation.level0, greaterThanOrEqualTo(0.0));
      expect(AppElevation.level1, greaterThanOrEqualTo(0.0));
      expect(AppElevation.level2, greaterThanOrEqualTo(0.0));
      expect(AppElevation.level3, greaterThanOrEqualTo(0.0));
    });
  });
}
