import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

/// A widget that provides screen size information to its builder.
///
/// Use this when you need access to screen size information
/// without building separate widgets for each breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  /// Builder function that receives screen size information.
  final Widget Function(BuildContext context, ScreenSize size) builder;

  /// Creates a responsive builder.
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final context, final constraints) {
      final size = ScreenSize.fromWidth(constraints.maxWidth);
      return builder(context, size);
    },
  );
}

/// Information about the current screen size.
class ScreenSize {
  /// The current width.
  final double width;

  /// The current breakpoint type.
  final ScreenType type;

  /// Creates screen size information.
  const ScreenSize({required this.width, required this.type});

  /// Creates ScreenSize from a width value.
  factory ScreenSize.fromWidth(final double width) {
    final type = ScreenType.fromWidth(width);
    return ScreenSize(width: width, type: type);
  }

  /// Returns true if the screen is mobile.
  bool get isMobile => type == ScreenType.mobile;

  /// Returns true if the screen is tablet.
  bool get isTablet => type == ScreenType.tablet;

  /// Returns true if the screen is desktop.
  bool get isDesktop => type == ScreenType.desktop;

  /// Returns true if the screen is large desktop.
  bool get isLargeDesktop => type == ScreenType.largeDesktop;

  /// Returns the number of grid columns for this screen size.
  int get gridColumns => Breakpoints.gridColumns(width);

  /// Returns the horizontal padding for this screen size.
  double get horizontalPadding => Breakpoints.horizontalPadding(width);
}

/// Types of screen sizes.
enum ScreenType {
  /// Mobile: < 600px
  mobile,

  /// Tablet: 600px - 899px
  tablet,

  /// Desktop: 900px - 1199px
  desktop,

  /// Large Desktop: >= 1200px
  largeDesktop;

  /// Returns the screen type for the given width.
  static ScreenType fromWidth(final double width) {
    if (Breakpoints.isMobile(width)) return ScreenType.mobile;
    if (Breakpoints.isTablet(width)) return ScreenType.tablet;
    if (Breakpoints.isLargeDesktop(width)) return ScreenType.largeDesktop;
    return ScreenType.desktop;
  }
}
