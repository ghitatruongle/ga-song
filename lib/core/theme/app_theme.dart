import 'package:flutter/material.dart';
import 'motion_page_transitions_builder.dart';
import 'tokens.dart';
import 'app_typography.dart';

/// Centralized theme configuration for G.A - Song.
///
/// Provides both light and dark themes with consistent styling
/// across all components. Supports dynamic accent color from cover art.
class AppTheme {
  AppTheme._();

  // ─── Accent Color (Dynamic) ───────────────────────────────────────────────
  // This is set by CoverArtRepository when extracting dominant color
  static Color _accentColor = AppColors.defaultAccent;
  static Color get accentColor => _accentColor;

  /// Update the accent color (called when cover art changes)
  static void setAccentColor(Color color) {
    _accentColor = color;
  }

  // ─── Global page transition ──────────────────────────────────────────────
  // Routes every `MaterialPageRoute` through [MotionPageTransitionsBuilder]
  // (fade-through + slide 5%, 300ms, decelerate). Honors
  // `MediaQuery.disableAnimations`.
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: MotionPageTransitionsBuilder(),
      TargetPlatform.iOS: MotionPageTransitionsBuilder(),
      TargetPlatform.macOS: MotionPageTransitionsBuilder(),
      TargetPlatform.windows: MotionPageTransitionsBuilder(),
      TargetPlatform.linux: MotionPageTransitionsBuilder(),
      TargetPlatform.fuchsia: MotionPageTransitionsBuilder(),
    },
  );

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: _pageTransitionsTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: _accentColor,
        secondary: _accentColor,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.subtitle,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextPrimary,
        size: 20,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.title,
        titleLarge: AppTypography.subtitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.small,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _accentColor,
        inactiveTrackColor: AppColors.darkSurface3,
        thumbColor: _accentColor,
        overlayColor: _accentColor.withValues(alpha: 0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSurface3,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTypography.caption.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface2,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        textStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        titleTextStyle: AppTypography.subtitle.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface3,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface2,
        selectedColor: _accentColor.withValues(alpha: 0.2),
        labelStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.darkTextSubtle),
      ),
    );
  }

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: _pageTransitionsTheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: _accentColor,
        secondary: _accentColor,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.subtitle,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextPrimary,
        size: 20,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.title,
        titleLarge: AppTypography.subtitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.small,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _accentColor,
        inactiveTrackColor: AppColors.lightSurface3,
        thumbColor: _accentColor,
        overlayColor: _accentColor.withValues(alpha: 0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightSurface3,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTypography.caption.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        textStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        titleTextStyle: AppTypography.subtitle.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightSurface3,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface2,
        selectedColor: _accentColor.withValues(alpha: 0.2),
        labelStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextSubtle,
        ),
      ),
    );
  }
}
