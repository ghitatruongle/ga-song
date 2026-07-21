import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Spacing tokens exposed via `ThemeData.extension<AppSpacingExtension>()`.
///
/// Widgets read these with:
///
/// ```dart
/// final spacing = Theme.of(context).extension<AppSpacingExtension>()!;
/// EdgeInsets.all(spacing.md)
/// ```
@immutable
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const AppSpacingExtension({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  const AppSpacingExtension.defaults()
      : xxs = AppSpacing.xxs,
        xs = AppSpacing.xs,
        sm = AppSpacing.sm,
        md = AppSpacing.md,
        lg = AppSpacing.lg,
        xl = AppSpacing.xl,
        xxl = AppSpacing.xxl;

  @override
  AppSpacingExtension copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) =>
      AppSpacingExtension(
        xxs: xxs ?? this.xxs,
        xs: xs ?? this.xs,
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
        xxl: xxl ?? this.xxl,
      );

  @override
  AppSpacingExtension lerp(ThemeExtension<AppSpacingExtension>? other, double t) {
    if (other is! AppSpacingExtension) return this;
    return AppSpacingExtension(
      xxs: lerpDouble(xxs, other.xxs, t)!,
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }

}

/// Radius tokens exposed via `ThemeData.extension<AppRadiusExtension>()`.
@immutable
class AppRadiusExtension extends ThemeExtension<AppRadiusExtension> {
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const AppRadiusExtension({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  const AppRadiusExtension.defaults()
      : sm = AppRadius.sm,
        md = AppRadius.md,
        lg = AppRadius.lg,
        xl = AppRadius.xl;

  @override
  AppRadiusExtension copyWith({double? sm, double? md, double? lg, double? xl}) =>
      AppRadiusExtension(
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
      );

  @override
  AppRadiusExtension lerp(ThemeExtension<AppRadiusExtension>? other, double t) {
    if (other is! AppRadiusExtension) return this;
    return AppRadiusExtension(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}

/// Elevation tokens exposed via `ThemeData.extension<AppElevationExtension>()`.
@immutable
class AppElevationExtension extends ThemeExtension<AppElevationExtension> {
  final double level0;
  final double level1;
  final double level2;
  final double level3;

  const AppElevationExtension({
    required this.level0,
    required this.level1,
    required this.level2,
    required this.level3,
  });

  const AppElevationExtension.defaults()
      : level0 = AppElevation.level0,
        level1 = AppElevation.level1,
        level2 = AppElevation.level2,
        level3 = AppElevation.level3;

  @override
  AppElevationExtension copyWith({
    double? level0,
    double? level1,
    double? level2,
    double? level3,
  }) =>
      AppElevationExtension(
        level0: level0 ?? this.level0,
        level1: level1 ?? this.level1,
        level2: level2 ?? this.level2,
        level3: level3 ?? this.level3,
      );

  @override
  AppElevationExtension lerp(ThemeExtension<AppElevationExtension>? other, double t) {
    if (other is! AppElevationExtension) return this;
    return AppElevationExtension(
      level0: lerpDouble(level0, other.level0, t)!,
      level1: lerpDouble(level1, other.level1, t)!,
      level2: lerpDouble(level2, other.level2, t)!,
      level3: lerpDouble(level3, other.level3, t)!,
    );
  }
}