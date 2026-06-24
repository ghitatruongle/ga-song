import 'package:flutter/material.dart';

/// Centralized typography system for G.A - Song.
///
/// Provides a clear hierarchy: Title > Subtitle > Body > Caption
/// with consistent letter spacing and font weights.
class AppTypography {
  AppTypography._();

  // ─── Title ────────────────────────────────────────────────────────────────
  // Used for: Page headers, main screen titles
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ─── Subtitle ─────────────────────────────────────────────────────────────
  // Used for: Section headers, dialog titles
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────
  // Used for: Default text, song names, menu items
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  // ─── Body Medium ──────────────────────────────────────────────────────────
  // Used for: Emphasized body text, active menu items
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // ─── Caption ──────────────────────────────────────────────────────────────
  // Used for: Timestamps, secondary info, hints
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.4,
  );

  // ─── Small ────────────────────────────────────────────────────────────────
  // Used for: Badges, very small labels
  static const TextStyle small = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ─── Player Title ─────────────────────────────────────────────────────────
  // Used for: Current song name in player bar
  static const TextStyle playerTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // ─── Player Artist ────────────────────────────────────────────────────────
  // Used for: Artist name in player bar
  static const TextStyle playerArtist = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // ─── Sidebar Item ─────────────────────────────────────────────────────────
  // Used for: Sidebar menu items
  static const TextStyle sidebarItem = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.4,
  );

  // ─── Sidebar Active ───────────────────────────────────────────────────────
  // Used for: Active sidebar menu item
  static const TextStyle sidebarActive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  // ─── Lyrics Current ───────────────────────────────────────────────────────
  // Used for: Current lyric line in desktop lyrics window
  static const TextStyle lyricsCurrent = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.4,
  );

  // ─── Lyrics Adjacent ──────────────────────────────────────────────────────
  // Used for: Previous/next lyric lines
  static const TextStyle lyricsAdjacent = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // ─── Helper: Apply color to TextStyle ─────────────────────────────────────
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // ─── Helper: Apply opacity to TextStyle ───────────────────────────────────
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}
