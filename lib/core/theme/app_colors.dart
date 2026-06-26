import 'package:flutter/material.dart';

/// Centralized color system for G.A - Song.
///
/// Provides neutral palette for both dark and light themes,
/// plus accent color support from cover art extraction.
class AppColors {
  AppColors._();

  // ─── Dark Theme Neutrals ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurface2 = Color(0xFF2A2A2A);
  static const Color darkSurface3 = Color(0xFF333333);
  static const Color darkBorder = Color(0xFF3A3A3A);
  static const Color darkDivider = Color(0xFF2A2A2A);

  // ─── Light Theme Neutrals ─────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF5F5F5);
  static const Color lightSurface3 = Color(0xFFEEEEEE);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // ─── Text Colors (Dark Theme) ─────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% opacity
  static const Color darkTextSubtle = Color(0x80FFFFFF);    // 50% opacity
  static const Color darkTextDisabled = Color(0x4DFFFFFF);  // 30% opacity

  // ─── Text Colors (Light Theme) ────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xB31A1A1A); // 70% opacity
  static const Color lightTextSubtle = Color(0x801A1A1A);    // 50% opacity
  static const Color lightTextDisabled = Color(0x4D1A1A1A);  // 30% opacity

  // ─── Default Accent ───────────────────────────────────────────────────────
  // Used when no dynamic color is available from cover art
  static const Color defaultAccent = Color(0xFF6366F1); // Indigo
  static const Color defaultAccentLight = Color(0xFF818CF8);
  static const Color defaultAccentDark = Color(0xFF4F46E5);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Player Bar Colors ────────────────────────────────────────────────────
  static const Color darkPlayerBar = Color(0xFF1A1A1A);
  static const Color lightPlayerBar = Color(0xFFFFFFFF);
  static const Color darkPlayerBarBorder = Color(0xFF2A2A2A);
  static const Color lightPlayerBarBorder = Color(0xFFE5E5E5);

  // ─── Sidebar Colors ───────────────────────────────────────────────────────
  static const Color darkSidebar = Color(0xFF161616);
  static const Color lightSidebar = Color(0xFFF8F8F8);
  static const Color darkSidebarHover = Color(0xFF222222);
  static const Color lightSidebarHover = Color(0xFFF0F0F0);

  // ─── Song List Colors ─────────────────────────────────────────────────────
  static const Color darkSongRowHover = Color(0x14FFFFFF); // 8% white
  static const Color lightSongRowHover = Color(0x0A000000); // 4% black
  static const Color darkSongRowActive = Color(0x1AFFFFFF); // 10% white
  static const Color lightSongRowActive = Color(0x0D000000); // 5% black

  // ─── Helper: Get theme-appropriate color ──────────────────────────────────
  static Color adaptive(BuildContext context, {
    required Color dark,
    required Color light,
  }) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ─── Helper: Get neutral surface color ────────────────────────────────────
  static Color surface(BuildContext context, {int level = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case 1:
        return isDark ? darkSurface : lightSurface;
      case 2:
        return isDark ? darkSurface2 : lightSurface2;
      case 3:
        return isDark ? darkSurface3 : lightSurface3;
      default:
        return isDark ? darkSurface : lightSurface;
    }
  }

  // ─── Helper: Get text color with opacity ──────────────────────────────────
  static Color textWithOpacity(BuildContext context, double opacity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? darkTextPrimary : lightTextPrimary;
    return baseColor.withValues(alpha: opacity);
  }
}
