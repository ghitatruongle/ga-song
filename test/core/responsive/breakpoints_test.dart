import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/responsive/breakpoints.dart';

void main() {
  group('Breakpoints', () {
    test('isMobile returns true for small widths', () {
      expect(Breakpoints.isMobile(0), isTrue);
      expect(Breakpoints.isMobile(300), isTrue);
      expect(Breakpoints.isMobile(599), isTrue);
    });

    test('isMobile returns false for larger widths', () {
      expect(Breakpoints.isMobile(600), isFalse);
      expect(Breakpoints.isMobile(900), isFalse);
    });

    test('isTablet returns true for tablet widths (600-1199)', () {
      expect(Breakpoints.isTablet(600), isTrue);
      expect(Breakpoints.isTablet(800), isTrue);
      expect(Breakpoints.isTablet(1199), isTrue);
    });

    test('isTablet returns false for non-tablet widths', () {
      expect(Breakpoints.isTablet(599), isFalse);
      expect(Breakpoints.isTablet(1200), isFalse);
    });

    test('isDesktop returns true for desktop widths (>=1200)', () {
      expect(Breakpoints.isDesktop(1200), isTrue);
      expect(Breakpoints.isDesktop(1500), isTrue);
      expect(Breakpoints.isDesktop(1599), isTrue);
    });

    test('isDesktop returns false for non-desktop widths', () {
      expect(Breakpoints.isDesktop(1199), isFalse);
    });

    test('isLargeDesktop returns true for large widths (>=1600)', () {
      expect(Breakpoints.isLargeDesktop(1600), isTrue);
      expect(Breakpoints.isLargeDesktop(2000), isTrue);
    });

    test('isLargeDesktop returns false for smaller widths', () {
      expect(Breakpoints.isLargeDesktop(1599), isFalse);
    });

    test('gridColumns returns correct count', () {
      expect(Breakpoints.gridColumns(300), equals(2)); // mobile
      expect(Breakpoints.gridColumns(700), equals(3)); // tablet
      expect(Breakpoints.gridColumns(1000), equals(3)); // tablet
      expect(Breakpoints.gridColumns(1400), equals(4)); // desktop
      expect(Breakpoints.gridColumns(1600), equals(5)); // large desktop
    });

    test('horizontalPadding returns correct value', () {
      expect(Breakpoints.horizontalPadding(300), equals(16)); // mobile
      expect(Breakpoints.horizontalPadding(700), equals(24)); // tablet
      expect(Breakpoints.horizontalPadding(1400), equals(32)); // desktop
    });

    test('contentMaxWidth returns correct value', () {
      expect(Breakpoints.contentMaxWidth(300), equals(300)); // mobile: full width
      expect(Breakpoints.contentMaxWidth(700), equals(720)); // tablet: 720
      expect(Breakpoints.contentMaxWidth(1400), equals(1200)); // desktop: 1200
    });
  });
}
