import 'package:flutter/material.dart';

/// Extension to eliminate the repeated isDark ternary pattern across the codebase.
///
/// Before: `(Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)`
/// After:  `context.adaptive`
extension AdaptiveColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Primary adaptive text/icon color: white (dark) / black87 (light)
  Color get adaptive => isDark ? Colors.white : Colors.black87;

  /// Get contrasting color for adaptive backgrounds (black on dark mode, white on light mode)
  Color get onAdaptive => isDark ? Colors.black : Colors.white;

  /// Adaptive color with custom alpha
  Color adaptiveAlpha(final double alpha) => adaptive.withValues(alpha: alpha);

  /// Secondary adaptive: white70/black54 — for less prominent icons/text
  Color get adaptiveSecondary => isDark ? Colors.white70 : Colors.black54;

  /// Subtle adaptive: white54/black45 — for hints, placeholders
  Color get adaptiveSubtle => isDark ? Colors.white54 : Colors.black45;
}
