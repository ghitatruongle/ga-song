# Phase 1: UI Minimalist + Desktop Lyrics

**Date:** 2026-06-24  
**Author:** ZCode  
**Status:** Approved  
**Scope:** UI/UX overhaul + Desktop floating lyrics window

---

## 1. Overview

Phase 1 focuses on two major improvements:
1. **UI Minimalist Overhaul** - Simplify the interface to a clean, Foobar2000-inspired aesthetic
2. **Desktop Lyrics Window** - Floating always-on-top lyrics display for desktop platforms

---

## 2. UI Minimalist Overhaul

### 2.1 Typography System

Create a centralized typography system with clear hierarchy:

| Style | Size | Weight | Letter Spacing | Usage |
|-------|------|--------|----------------|-------|
| Title | 28px | w700 | -0.5 | Page headers |
| Subtitle | 18px | w600 | -0.3 | Section headers |
| Body | 14px | w400 | 0.15 | Default text |
| Caption | 12px | w400 | 0.4 | Secondary info, timestamps |

**Implementation:**
- New file: `lib/core/theme/app_typography.dart`
- Use system fonts (Segoe UI on Windows, SF Pro on macOS, Roboto on Android/Linux)
- Optional: Add `google_fonts` package for Inter font

### 2.2 Color System

**Neutral Palette:**
```
Dark Mode:
  Background: #121212
  Surface:    #1E1E1E
  Surface2:   #2A2A2A
  Text:       #FFFFFF
  TextSecondary: rgba(255,255,255,0.7)
  TextSubtle:    rgba(255,255,255,0.5)

Light Mode:
  Background: #FAFAFA
  Surface:    #FFFFFF
  Surface2:   #F5F5F5
  Text:       #1A1A1A
  TextSecondary: rgba(0,0,0,0.7)
  TextSubtle:    rgba(0,0,0,0.5)
```

**Accent Color:**
- Keep dynamic color extraction from cover art
- Use as primary accent for active states, progress bars, highlights

**Implementation:**
- New file: `lib/core/theme/app_colors.dart`
- Update `theme_utils.dart` extensions

### 2.3 Sidebar Refinement

**Changes:**
- Collapsible: icon-only (64px) ↔ full (240px)
- Replace avatar section with small app logo
- Menu items: icon + text, subtle hover highlight
- Active indicator: thin accent line on left (3px), no background fill
- Add separators between sections (Home, Library, Tools, Settings)

**Files to modify:**
- `lib/ui/widgets/sidebar.dart`

### 2.4 Bottom Player Bar Simplification

**Current:**
- `borderRadius: 20`, boxShadow, blur background
- Height: 84px

**New:**
- `borderRadius: 12`, no boxShadow, solid surface color
- Height: 64-72px
- Progress bar: thin line (2px) on top of bar, accent color
- Cleaner layout with better spacing

**Files to modify:**
- `lib/ui/widgets/bottom_player_bar.dart`
- `lib/ui/widgets/player_bar/progress_bar.dart`

### 2.5 Song List Refinement

**Changes:**
- Row height: 56px (from 72px)
- Remove hover background fill, show play icon on hover only
- Add index number on left (1, 2, 3...)
- Duration on right, opacity 0.6
- Divider: 1px, opacity 0.08

**Files to modify:**
- `lib/ui/widgets/song_tiles.dart`

### 2.6 Animations & Transitions

| Action | Duration | Easing |
|--------|----------|--------|
| Tab switch | 200ms | ease-out |
| Song change (cover art) | 300ms | ease-in-out |
| Hover effects | 150ms | ease |
| Sidebar collapse | 250ms | ease-in-out |

---

## 3. Desktop Lyrics Window

### 3.1 Architecture

```
┌─────────────────────────────────────────────┐
│  DesktopLyricsService                       │
│  ├─ Window lifecycle management             │
│  ├─ Position/size persistence               │
│  └─ Settings sync                           │
├─────────────────────────────────────────────┤
│  DesktopLyricsScreen                        │
│  ├─ Transparent background                  │
│  ├─ Current line: large, accent, bold       │
│  ├─ Previous/next: smaller, subtle          │
│  └─ Smooth scroll animation                 │
├─────────────────────────────────────────────┤
│  LyricProvider (existing)                   │
│  └─ Provides current lyric line             │
└─────────────────────────────────────────────┘
```

### 3.2 Features

**Window Properties:**
- Always-on-top
- Transparent background
- Click-through option (toggle)
- Draggable (when not click-through)
- Remembers last position and size
- Auto-hide when no lyrics available

**Display:**
- Current line: 24-32px, accent color, bold
- Previous lines: 16-20px, subtle color, fade out
- Next lines: 16-20px, subtle color
- Smooth scroll to current line (300ms animation)

**Controls (on hover or right-click context menu):**
- Font size slider: 16-48px
- Color picker: accent / custom
- Opacity slider: 0.3-1.0
- Lock position toggle
- Click-through toggle
- Close button

**Platform Support:**
- Windows: Use `window_manager` for always-on-top, transparent
- Linux: Use `window_manager` with GTK transparency
- macOS: Use `window_manager` with NSWindow

### 3.3 Implementation

**New Files:**
- `lib/core/services/desktop_lyrics_service.dart` - Window manager
- `lib/ui/screens/desktop_lyrics_screen.dart` - Lyrics display UI

**Modified Files:**
- `lib/core/settings_manager.dart` - Add lyrics window settings
- `lib/main.dart` - Initialize desktop lyrics service

**Settings to Add:**
```dart
ValueNotifier<bool> desktopLyricsEnabledNotifier = ValueNotifier(false);
ValueNotifier<double> desktopLyricsFontSizeNotifier = ValueNotifier(24.0);
ValueNotifier<Color> desktopLyricsColorNotifier = ValueNotifier(Colors.white);
ValueNotifier<double> desktopLyricsOpacityNotifier = ValueNotifier(0.9);
ValueNotifier<bool> desktopLyricsClickThroughNotifier = ValueNotifier(false);
ValueNotifier<Offset> desktopLyricsPositionNotifier = ValueNotifier(Offset(100, 100));
ValueNotifier<Size> desktopLyricsSizeNotifier = ValueNotifier(Size(400, 200));
```

---

## 4. File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `lib/core/theme/app_theme.dart` | **New** | Centralized theme data |
| `lib/core/theme/app_typography.dart` | **New** | Typography system |
| `lib/core/theme/app_colors.dart` | **New** | Color palette |
| `lib/ui/widgets/sidebar.dart` | **Edit** | Collapse, simplify |
| `lib/ui/widgets/bottom_player_bar.dart` | **Edit** | Simplify design |
| `lib/ui/widgets/player_bar/progress_bar.dart` | **Edit** | Thin progress line |
| `lib/ui/widgets/song_tiles.dart` | **Edit** | Compact rows |
| `lib/ui/widgets/main_content.dart` | **Edit** | Adjust padding |
| `lib/core/services/desktop_lyrics_service.dart` | **New** | Lyrics window manager |
| `lib/ui/screens/desktop_lyrics_screen.dart` | **New** | Lyrics window UI |
| `lib/core/settings_manager.dart` | **Edit** | Add lyrics window settings |
| `lib/main.dart` | **Edit** | Initialize lyrics service |

---

## 5. Success Criteria

- [ ] UI feels cleaner and more modern
- [ ] Sidebar collapses smoothly
- [ ] Player bar is more compact
- [ ] Song list rows are tighter
- [ ] Desktop lyrics window works on Windows
- [ ] Lyrics sync correctly with playback
- [ ] Settings persist across app restarts
- [ ] No performance regression

---

## 6. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Window transparency not working on some systems | Fallback to semi-transparent background |
| Performance impact from lyrics window | Use RepaintBoundary, minimize rebuilds |
| Breaking existing UI with theme changes | Incremental rollout, test each component |

---

## 7. Timeline

- **Day 1-2:** Typography + Color system
- **Day 3-4:** Sidebar refinement
- **Day 5-6:** Player bar + Song list
- **Day 7-8:** Desktop lyrics service
- **Day 9-10:** Desktop lyrics UI + testing
