/// Responsive breakpoints for different screen sizes.
///
/// Use these constants to build responsive layouts that adapt
/// to mobile, tablet, and desktop screens.
class Breakpoints {
  Breakpoints._();

  /// Mobile: < 600px
  static const double mobile = 600;

  /// Tablet: 600px - 899px
  static const double tablet = 900;

  /// Desktop: 900px - 1199px
  static const double desktop = 1200;

  /// Large Desktop: >= 1200px
  static const double largeDesktop = 1600;

  /// Returns true if width is mobile size.
  static bool isMobile(double width) => width < mobile;

  /// Returns true if width is tablet size.
  static bool isTablet(double width) => width >= mobile && width < desktop;

  /// Returns true if width is desktop size.
  static bool isDesktop(double width) => width >= desktop;

  /// Returns true if width is large desktop size.
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  /// Returns the number of grid columns for the given width.
  static int gridColumns(double width) {
    if (isMobile(width)) return 2;
    if (isTablet(width)) return 3;
    if (isLargeDesktop(width)) return 5;
    return 4; // desktop
  }

  /// Returns the horizontal padding for the given width.
  static double horizontalPadding(double width) {
    if (isMobile(width)) return 16;
    if (isTablet(width)) return 24;
    return 32;
  }

  /// Returns the content max width for readability.
  static double contentMaxWidth(double width) {
    if (isMobile(width)) return width;
    if (isTablet(width)) return 720;
    return 1200;
  }
}
