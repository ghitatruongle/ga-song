import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

/// A widget that builds different layouts based on screen size.
///
/// Use this to create responsive UIs that adapt to mobile, tablet, and desktop.
class ResponsiveLayout extends StatelessWidget {
  /// Widget to show on mobile screens (< 600px).
  final Widget mobile;

  /// Widget to show on tablet screens (600px - 899px).
  /// If null, falls back to [mobile].
  final Widget? tablet;

  /// Widget to show on desktop screens (>= 900px).
  final Widget desktop;

  /// Creates a responsive layout.
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final context, final constraints) {
      if (Breakpoints.isMobile(constraints.maxWidth)) {
        return mobile;
      } else if (Breakpoints.isTablet(constraints.maxWidth)) {
        return tablet ?? mobile;
      } else {
        return desktop;
      }
    },
  );
}
