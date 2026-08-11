import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

/// Sugar for `Theme.of(context).extension<AppSpacingExtension>()!.md` etc.
///
/// Use these helpers instead of writing the verbose ThemeExtension lookup
/// at every callsite. They are null-safe by contract — the helpers throw
/// if the extension has not been registered on the active [ThemeData],
/// which surfaces configuration bugs early.
class ThemeSpacing {
  ThemeSpacing._(this.context);
  factory ThemeSpacing.of(final BuildContext context) =>
      ThemeSpacing._(context);
  final BuildContext context;

  AppSpacingExtension get _e =>
      Theme.of(context).extension<AppSpacingExtension>()!;

  double get xxs => _e.xxs;
  double get xs => _e.xs;
  double get sm => _e.sm;
  double get md => _e.md;
  double get lg => _e.lg;
  double get xl => _e.xl;
  double get xxl => _e.xxl;

  /// Returns [EdgeInsets.all] with the supplied token (or `md` by default).
  EdgeInsets all([final double? value]) => EdgeInsets.all(value ?? md);

  /// Returns symmetric padding using the spacing tokens.
  ///
  /// Both [horizontal] and [vertical] default to `md`. Pass `0` to opt
  /// out of the default — note that `0` is the only way to express
  /// "intentional zero" without going through the token (use `xxs`
  /// if you actually want the smallest spacing).
  EdgeInsets symmetric({
    final double horizontal = 0,
    final double vertical = 0,
  }) => EdgeInsets.symmetric(
    horizontal: horizontal == 0 ? md : horizontal,
    vertical: vertical == 0 ? md : vertical,
  );

  /// Returns symmetric padding using `xs` (4) for vertical and `md` (16)
  /// for horizontal — the most common inset pattern in the app.
  EdgeInsets get insetH => EdgeInsets.symmetric(horizontal: md, vertical: xs);

  /// Returns symmetric padding using `md` (16) for vertical and `md` (16)
  /// for horizontal — common card / dialog padding.
  EdgeInsets get cardPadding =>
      EdgeInsets.symmetric(horizontal: md, vertical: md);
}

/// Sugar for `Theme.of(context).extension<AppRadiusExtension>()!.md` etc.
class ThemeRadius {
  ThemeRadius._(this.context);
  factory ThemeRadius.of(final BuildContext context) => ThemeRadius._(context);
  final BuildContext context;

  AppRadiusExtension get _e =>
      Theme.of(context).extension<AppRadiusExtension>()!;

  double get sm => _e.sm;
  double get md => _e.md;
  double get lg => _e.lg;
  double get xl => _e.xl;

  /// Returns [BorderRadius.circular] with the supplied token (or `md`).
  BorderRadius circular([final double? value]) =>
      BorderRadius.circular(value ?? md);
}
