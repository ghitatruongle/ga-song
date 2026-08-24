import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/theme/tokens.dart';

/// Wraps [child] in a [MaterialApp] whose [ThemeData.brightness] is [brightness]
/// so helpers like [AppColors.adaptive] can resolve a real [Theme.of].
Widget _wrap(final Widget child, final Brightness brightness) => MaterialApp(
  theme: ThemeData(brightness: brightness, useMaterial3: true),
  home: Builder(
    builder: (final context) => Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('AppColors merged from legacy app_colors.dart', () {
    test('AppColors.defaultAccent exists', () {
      expect(AppColors.defaultAccent, isA<Color>());
    });

    test('Semantic colors exist', () {
      expect(AppColors.success, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.info, isA<Color>());
      expect(AppColors.danger, isA<Color>());
    });

    test('AppColors.accent still exists (not overwritten)', () {
      expect(AppColors.accent, isA<Color>());
    });

    test('Dark theme neutral palette preserves legacy hex values', () {
      expect(AppColors.darkBackground.toARGB32(), 0xFF121212);
      expect(AppColors.darkSurface.toARGB32(), 0xFF1E1E1E);
      expect(AppColors.darkSurface2.toARGB32(), 0xFF2A2A2A);
      expect(AppColors.darkSurface3.toARGB32(), 0xFF333333);
      expect(AppColors.darkBorder.toARGB32(), 0xFF3A3A3A);
      expect(AppColors.darkDivider.toARGB32(), 0xFF2A2A2A);
    });

    test('Light theme neutral palette preserves legacy hex values', () {
      expect(AppColors.lightBackground.toARGB32(), 0xFFFAFAFA);
      expect(AppColors.lightSurface.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.lightSurface2.toARGB32(), 0xFFF5F5F5);
      expect(AppColors.lightSurface3.toARGB32(), 0xFFEEEEEE);
      expect(AppColors.lightBorder.toARGB32(), 0xFFE0E0E0);
      expect(AppColors.lightDivider.toARGB32(), 0xFFEEEEEE);
    });

    test('Text colors preserve legacy hex values', () {
      expect(AppColors.darkTextPrimary.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.darkTextSecondary.toARGB32(), 0xB3FFFFFF);
      expect(AppColors.darkTextSubtle.toARGB32(), 0x80FFFFFF);
      expect(AppColors.darkTextDisabled.toARGB32(), 0x4DFFFFFF);

      expect(AppColors.lightTextPrimary.toARGB32(), 0xFF1A1A1A);
      expect(AppColors.lightTextSecondary.toARGB32(), 0xB31A1A1A);
      expect(AppColors.lightTextSubtle.toARGB32(), 0x801A1A1A);
      expect(AppColors.lightTextDisabled.toARGB32(), 0x4D1A1A1A);
    });

    test('Default accent palette preserves legacy hex values', () {
      expect(AppColors.defaultAccent.toARGB32(), 0xFF6366F1);
      expect(AppColors.defaultAccentLight.toARGB32(), 0xFF818CF8);
      expect(AppColors.defaultAccentDark.toARGB32(), 0xFF4F46E5);
    });

    test(
      'Player bar / sidebar / song row palettes preserve legacy hex values',
      () {
        expect(AppColors.darkPlayerBar.toARGB32(), 0xFF1A1A1A);
        expect(AppColors.lightPlayerBar.toARGB32(), 0xFFFFFFFF);
        expect(AppColors.darkPlayerBarBorder.toARGB32(), 0xFF2A2A2A);
        expect(AppColors.lightPlayerBarBorder.toARGB32(), 0xFFE5E5E5);

        expect(AppColors.darkSidebar.toARGB32(), 0xFF161616);
        expect(AppColors.lightSidebar.toARGB32(), 0xFFF8F8F8);
        expect(AppColors.darkSidebarHover.toARGB32(), 0xFF222222);
        expect(AppColors.lightSidebarHover.toARGB32(), 0xFFF0F0F0);

        expect(AppColors.darkSongRowHover.toARGB32(), 0x14FFFFFF);
        expect(AppColors.lightSongRowHover.toARGB32(), 0x0A000000);
        expect(AppColors.darkSongRowActive.toARGB32(), 0x1AFFFFFF);
        expect(AppColors.lightSongRowActive.toARGB32(), 0x0D000000);
      },
    );

    test('danger keeps legacy semantic-error value', () {
      // The legacy `error` (semantic) is now exposed as `danger` because the
      // tokens file already defined `error` for the Material 3 seed scheme.
      expect(AppColors.danger.toARGB32(), 0xFFEF4444);
    });

    test('error retains the Material 3 seed value', () {
      expect(AppColors.error.toARGB32(), 0xFFB3261E);
    });
  });

  group('AppColors helpers', () {
    testWidgets('adaptive returns the dark color under a dark theme', (
      final tester,
    ) async {
      Color? resolved;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              resolved = AppColors.adaptive(
                context,
                dark: AppColors.darkSurface,
                light: AppColors.lightSurface,
              );
              return const SizedBox.shrink();
            },
          ),
          Brightness.dark,
        ),
      );
      expect(resolved, AppColors.darkSurface);
    });

    testWidgets('adaptive returns the light color under a light theme', (
      final tester,
    ) async {
      Color? resolved;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              resolved = AppColors.adaptive(
                context,
                dark: AppColors.darkSurface,
                light: AppColors.lightSurface,
              );
              return const SizedBox.shrink();
            },
          ),
          Brightness.light,
        ),
      );
      expect(resolved, AppColors.lightSurface);
    });

    testWidgets('surfaceFor picks the right tier under a dark theme', (
      final tester,
    ) async {
      Color? l1;
      Color? l2;
      Color? l3;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              l1 = AppColors.surfaceFor(context);
              l2 = AppColors.surfaceFor(context, level: 2);
              l3 = AppColors.surfaceFor(context, level: 3);
              return const SizedBox.shrink();
            },
          ),
          Brightness.dark,
        ),
      );
      expect(l1, AppColors.darkSurface);
      expect(l2, AppColors.darkSurface2);
      expect(l3, AppColors.darkSurface3);
    });

    testWidgets('surfaceFor picks the right tier under a light theme', (
      final tester,
    ) async {
      Color? l1;
      Color? l2;
      Color? l3;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              l1 = AppColors.surfaceFor(context);
              l2 = AppColors.surfaceFor(context, level: 2);
              l3 = AppColors.surfaceFor(context, level: 3);
              return const SizedBox.shrink();
            },
          ),
          Brightness.light,
        ),
      );
      expect(l1, AppColors.lightSurface);
      expect(l2, AppColors.lightSurface2);
      expect(l3, AppColors.lightSurface3);
    });

    testWidgets('surfaceFor falls back to level 1 for unknown levels', (
      final tester,
    ) async {
      Color? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              result = AppColors.surfaceFor(context, level: 99);
              return const SizedBox.shrink();
            },
          ),
          Brightness.dark,
        ),
      );
      expect(result, AppColors.darkSurface);
    });

    testWidgets('textWithOpacity applies opacity to the dark theme base', (
      final tester,
    ) async {
      Color? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              result = AppColors.textWithOpacity(context, 0.5);
              return const SizedBox.shrink();
            },
          ),
          Brightness.dark,
        ),
      );
      expect(result, AppColors.darkTextPrimary.withValues(alpha: 0.5));
    });

    testWidgets('textWithOpacity applies opacity to the light theme base', (
      final tester,
    ) async {
      Color? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (final context) {
              result = AppColors.textWithOpacity(context, 0.5);
              return const SizedBox.shrink();
            },
          ),
          Brightness.light,
        ),
      );
      expect(result, AppColors.lightTextPrimary.withValues(alpha: 0.5));
    });
  });
}
