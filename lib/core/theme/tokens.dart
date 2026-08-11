import 'package:flutter/material.dart';

/// Design token colors — single source of truth.
///
/// These values feed Material 3 `ColorScheme.fromSeed` and any direct
/// widget references. Do not introduce `Color(0xFF...)` literals elsewhere.
///
/// The legacy palette from `app_colors.dart` was folded into this file
/// during Phase 4 (UI Polish). The single class [AppColors] is now the
/// only color entry point — both the Material 3 seed palette and the
/// legacy dark/light neutrals live here.
class AppColors {
  AppColors._();

  // ─── Material 3 Seed Colors (GA-Song signature purple) ────────────────────
  static const Color seedPrimary = Color(0xFF6750A4);
  static const Color seedSecondary = Color(0xFF625B71);
  static const Color seedTertiary = Color(0xFF7D5260);

  // ─── Accent ───────────────────────────────────────────────────────────────
  // Used for active states (waveform, selected items).
  static const Color accent = Color(0xFFD0BCFF);

  // ─── Surfaces (Material 3 seed) ───────────────────────────────────────────
  static const Color surface = Color(0xFFFFFBFE);
  static const Color error = Color(0xFFB3261E);

  // ─── Dark Theme Neutrals (legacy) ─────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurface2 = Color(0xFF2A2A2A);
  static const Color darkSurface3 = Color(0xFF333333);
  static const Color darkBorder = Color(0xFF3A3A3A);
  static const Color darkDivider = Color(0xFF2A2A2A);

  // ─── Light Theme Neutrals (legacy) ────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF5F5F5);
  static const Color lightSurface3 = Color(0xFFEEEEEE);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // ─── Text Colors (Dark Theme) ─────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% opacity
  static const Color darkTextSubtle = Color(0x80FFFFFF); // 50% opacity
  static const Color darkTextDisabled = Color(0x4DFFFFFF); // 30% opacity

  // ─── Text Colors (Light Theme) ────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xB31A1A1A); // 70% opacity
  static const Color lightTextSubtle = Color(0x801A1A1A); // 50% opacity
  static const Color lightTextDisabled = Color(0x4D1A1A1A); // 30% opacity

  // ─── Default Accent ───────────────────────────────────────────────────────
  // Used when no dynamic color is available from cover art.
  static const Color defaultAccent = Color(0xFF6366F1); // Indigo
  static const Color defaultAccentLight = Color(0xFF818CF8);
  static const Color defaultAccentDark = Color(0xFF4F46E5);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  // NOTE: The Material 3 seed `error` (above) is a tonal anchor for
  // ColorScheme.fromSeed. The legacy semantic danger color is exposed
  // as `danger` to avoid a name collision while keeping both available.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444); // legacy semantic error
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Return the theme-appropriate color for the current [BuildContext].
  ///
  /// Picks [dark] when [Theme.of].brightness is dark, otherwise [light].
  static Color adaptive(
    final BuildContext context, {
    required final Color dark,
    required final Color light,
  }) => Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Get a neutral surface color tuned for the current theme.
  ///
  /// `level` selects the elevation tier:
  ///   1 → base surface, 2 → raised, 3 → overlay.
  ///
  /// Renamed from the legacy `surface(...)` so it does not collide with
  /// the static const [surface] Material 3 seed field.
  static Color surfaceFor(final BuildContext context, {final int level = 1}) {
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

  /// Get the theme-appropriate text color with the supplied opacity.
  static Color textWithOpacity(
    final BuildContext context,
    final double opacity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? darkTextPrimary : lightTextPrimary;
    return baseColor.withValues(alpha: opacity);
  }
}

/// Spacing scale on a 4px grid.
///
/// Use these everywhere instead of inline `EdgeInsets.all(16)`. They are
/// exposed to widgets via [AppSpacingExtension] (see theme_extensions.dart).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius scale.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // Buttons, chips
  static const double md = 12; // Cards
  static const double lg = 16; // Bottom sheets
  static const double xl = 28; // Player surfaces
}

/// Material 3 elevation levels.
class AppElevation {
  AppElevation._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
}
