# Phase 4: UI Polish & Motion Language Design

**Date:** 2026-07-08
**Author:** ZCode (brainstorming session)
**Status:** Approved
**Scope:** UI Polish & Motion Language (per Refined Polish spec §3.4)
**Supersedes:** None (Phase 4 spec is fresh)

---

## 1. Overview

This spec covers Phase 4 of the Refined Polish initiative. It activates the foundation tokens/motion/theme files (orphaned since Phase 1), resolves the latent `AppColors` collision, and applies the motion language to user-facing interactions. The result is a UI that feels deliberate and refined — every interaction has appropriate visual/haptic feedback.

### 1.1 Four Pillars (recap from Refined Polish spec)

- **Beautiful** ⭐ — Material 3 ColorScheme complete, spacing/radius consistent, motion language
- **Feel** ⭐ — haptic + sound + visual feedback at every interaction point
- **Smooth** — motion uses correct duration, no jank on animation
- **Quality** — no `Color(0xFF...)` magic numbers in widget code

### 1.2 User Decisions (brainstorm 2026-07-08)

| Decision | Choice | Rationale |
|---|---|---|
| AppColors collision | **Fold legacy** `app_colors.dart` → `tokens.dart` | Single source of truth per spec §2.3; no class name duplication |
| Page transition scope | **Global** via `pageTransitionsTheme` | Consistent UX; no per-screen overrides needed |
| Haptic + sound | **Conservative** — play/pause/EQ haptic, sound opt-in | Safer UX, no annoyance; opt-in lets users enable |
| Bottom player bar scroll | **Deferred** | Complex; not in current spec scope |
| Per-song accent extraction | **Deferred** (Phase 7+) | Out of scope |

### 1.3 Non-Goals

- No platform-specific code changes (macOS/iOS stay at "partial")
- No new dependencies (use Flutter built-ins: `AnimatedSwitcher`, `AnimatedTheme`, `AnimatedContainer`, `HapticFeedback`, `SystemSound`)
- No breaking changes to user data (DB schema, SharedPreferences)

---

## 2. Current State Analysis (before this phase)

### 2.1 Strengths

- `tokens.dart` (Phase 1) provides 43 design-token constants + Freezed `SettingsState` wrapper
- `theme_extensions.dart` (Phase 1) provides `ThemeExtension<T>` wrappers (with `divisions` + `label` support added in Phase 3)
- `app_motion.dart` (Phase 1) provides `AppDurations`, `AppCurves`, `AppMotion` helpers
- Riverpod-based state flow (Phase 2) means widgets can `ref.watch` settings cleanly
- Performance budget (Phase 3) keeps motion from dropping frames

### 2.2 Issues Identified

| Category | Specific Issues |
|---|---|
| **Foundation files orphaned** | `tokens.dart`, `theme_extensions.dart`, `app_motion.dart` exist but no widget reads them — still hardcoded `Color(0xFF...)` / `EdgeInsets.all(16)` / `BorderRadius.circular(8)` |
| **AppColors name collision** | Two classes named `AppColors` exist: one in `tokens.dart` (Phase 1, 6 fields) and one in `app_colors.dart` (pre-existing, 38+ fields). Dormant today but will activate when `app_theme.dart` imports `tokens.dart` |
| **Hardcoded colors** | 36 `Color(0xFF...)` literals across `lib/ui/` (home_screen, mini_player, online_screen, audio_effects_dialog, bottom_player_bar, equalizer_widget, library_stats_widget, duplicate_detector_widget, custom_hotkeys_dialog, audio_device_selector) |
| **No global page transition** | Zero `PageRoute` references in `lib/ui/` — navigation uses default Material transitions |
| **No haptic feedback** | Zero `HapticFeedback` calls in `lib/` |
| **Theme switch abrupt** | `ThemeMode` switching (59 references) likely has no animation between light/dark |
| **EQ slider no visual feedback** | EQ band slider `onChanged` triggers audio effect but no visual pulse |
| **Lyric transition abrupt** | LyricView shows current line; no fade between transitions |

### 2.3 Success Metrics (per spec §3.4)

- `grep -r "Color(0x" lib/ui/ | wc -l` = 0
- `flutter test test/ui/widgets/equalizer_widget.dart`: slider visual feedback measurable
- Theme switch animation = 600ms ± 50ms (DevTools)
- Lyric transition ≥ 58 FPS across 1 album playback

---

## 3. Phase Plan (9 tasks)

| # | Task | Duration | Primary Outcome |
|---|------|----------|-----------------|
| 1 | Fold legacy `app_colors.dart` → `tokens.dart` | 0.5 days | Single source of truth; resolves Phase 1 collision |
| 2 | Token migration in top 10 screens | 1.5 days | Zero hardcoded `Color(0x...)` / `EdgeInsets.all(N)` / `BorderRadius.circular(N)` |
| 3 | Global page transition via `pageTransitionsTheme` | 0.5 days | Consistent fade-through + slide 5% on all routes |
| 4 | Theme switch cross-fade | 0.5 days | 600ms cross-fade light↔dark |
| 5 | Haptic feedback (Android) | 0.5 days | Haptic on play/pause/next/prev/EQ |
| 6 | Sound feedback opt-in | 0.5 days | New `soundFeedbackEnabled` setting + opt-in implementation |
| 7 | Card hover/press animation | 0.5 days | 200ms scale animation on cards |
| 8 | EQ slider waveform pulse | 0.5 days | Animated glow on EQ thumbs during change |
| 9 | Lyric transition cross-fade | 0.5 days | `AnimatedSwitcher` 300ms between lyric lines |

**Total:** ~5 days wall-clock (some tasks parallelizable)

---

## 4. Task 1 — Fold legacy `app_colors.dart` → `tokens.dart`

### 4.1 Problem

`lib/core/theme/app_colors.dart` (97 lines) pre-existed Phase 1 and defines a class `AppColors` with ~38 fields covering dark theme neutrals, light theme neutrals, semantic colors, etc. Phase 1 added `lib/core/theme/tokens.dart` with its own class `AppColors` (6 fields: seed colors + accent + surface + error). The collision is dormant because no file imports both.

### 4.2 Solution

**Merge `app_colors.dart`'s fields into `tokens.dart`'s `AppColors` class, then delete `app_colors.dart`.**

Step 1: Read both files completely. Identify all 38+ legacy fields.

Step 2: Categorize legacy fields:

- **Keep as-is**: semantic colors (success, warning, info, danger), brand accent variants
- **Deprecate**: dark-specific neutrals (`darkBackground`, `darkSurface`, etc.) — these belong in `ThemeData.colorScheme` not in `tokens.dart`
- **Promote to ThemeExtension**: surface tones that vary by light/dark — handled by Material 3 `ColorScheme`, not raw `AppColors` constants

Step 3: Add kept fields to `tokens.dart`'s `AppColors` class. Maintain alphabetical ordering of fields.

Step 4: Update `lib/core/theme/app_theme.dart` to use the merged `AppColors` instead of the deleted one. This is the main caller with ~30 references like `AppColors.darkBackground`, `AppColors.darkSurface`, etc. Most of these will need to be replaced with `Theme.of(context).colorScheme.X` since they were dark-theme-specific.

Step 5: Delete `lib/core/theme/app_colors.dart`.

Step 6: Update any other callers (search via `grep -rn "core/theme/app_colors" lib/`). Expected: 1-3 files.

### 4.3 Migration table (legacy → target)

| Legacy field (app_colors.dart) | Target |
|---|---|
| `defaultAccent = Color(0xFF6366F1)` | Move to `tokens.AppColors.accent` (overwrite existing 0xFFD0BCFF) |
| `darkBackground`, `darkSurface`, `darkSurface2`, `darkSurface3` | `Theme.of(context).colorScheme.surface` / `surfaceContainerHighest` |
| `darkTextPrimary`, `darkTextSecondary` | `Theme.of(context).colorScheme.onSurface` / `onSurfaceVariant` |
| `darkDivider`, `darkBorder` | `Theme.of(context).dividerColor` / `outlineVariant` |
| `lightBackground`, `lightSurface`, etc. | Same Material 3 mappings (light scheme) |
| Semantic colors (success, warning, info, danger) | Keep as `AppColors.success/warning/info/danger` constants |

### 4.4 Behavior preservation

- App must continue to render correctly after the migration
- `flutter test` must pass (no behavior changes)
- `flutter analyze` must remain clean

---

## 5. Task 2 — Token migration in top 10 screens

### 5.1 Problem

Widgets use hardcoded literals:
- 36 `Color(0xFF...)` for colors (should use `Theme.of(context).colorScheme.X` or `AppColors.X`)
- ~50+ `EdgeInsets.all(N)` for spacing (should use `AppSpacingExtension.X` via `Theme.of(context).extension!`)
- ~30+ `BorderRadius.circular(N)` for radii (should use `AppRadiusExtension.X`)
- ~10 `Duration(milliseconds: N)` for animation durations (should use `AppDurations.X`)

### 5.2 Solution

**Top 10 screens to migrate** (by hardcoded-literal density):
1. `lib/ui/screens/home_screen.dart` (most literals)
2. `lib/ui/screens/mini_player_screen.dart`
3. `lib/ui/widgets/equalizer_widget.dart`
4. `lib/ui/widgets/audio_effects_dialog.dart`
5. `lib/ui/widgets/bottom_player_bar.dart`
6. `lib/ui/widgets/duplicate_detector_widget.dart`
7. `lib/ui/widgets/library_stats_widget.dart`
8. `lib/ui/widgets/custom_hotkeys_dialog.dart`
9. `lib/ui/widgets/audio_device_selector.dart`
10. `lib/ui/screens/online_screen.dart`

For each screen, do a mechanical find-and-replace:

| Original | Replace with |
|---|---|
| `Color(0xFFXXXXXX)` (semantic) | `Theme.of(context).colorScheme.X` where X = primary/secondary/tertiary/error/surface/onSurface/onPrimary/etc. |
| `Color(0xFFXXXXXX)` (brand) | `AppColors.X` (from merged tokens.dart) |
| `EdgeInsets.all(N)` | `EdgeInsets.all(Theme.of(context).extension<AppSpacingExtension>()!.X)` |
| `BorderRadius.circular(N)` | `BorderRadius.circular(Theme.of(context).extension<AppRadiusExtension>()!.X)` |
| `Duration(milliseconds: N)` | `AppDurations.X` |

### 5.3 Helper for readability

Add a small `lib/ui/utils/theme_helpers.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:ga_song/core/theme/theme_extensions.dart';

/// Shortcut for Theme.of(context).extension<AppSpacingExtension>()!.md etc.
class ThemeSpacing {
  ThemeSpacing._(this.context);
  factory ThemeSpacing.of(BuildContext context) =>
      ThemeSpacing._(context);
  final BuildContext context;

  AppSpacingExtension get _e => Theme.of(context).extension<AppSpacingExtension>()!;

  double get xxs => _e.xxs;
  double get xs => _e.xs;
  double get sm => _e.sm;
  double get md => _e.md;
  double get lg => _e.lg;
  double get xl => _e.xl;
  double get xxl => _e.xxl;

  EdgeInsets all([double? value]) => EdgeInsets.all(value ?? md);
}

class ThemeRadius { /* similar */ }
```

Usage: `EdgeInsets.all(ThemeSpacing.of(context).md)`.

### 5.4 Behavior preservation

- All visible rendering must be identical after migration (just routed through tokens)
- `flutter test` must pass
- `flutter analyze` must remain clean
- Performance: token lookups are O(1) via Theme.of(context) — no measurable regression

---

## 6. Task 3 — Global page transition via `pageTransitionsTheme`

### 6.1 Problem

Zero `PageRoute` references in `lib/ui/` — all navigation uses default Material transitions (platform-default slide-on-iOS, fade-on-Android). The motion language exists (`AppMotion.fadeThrough`, `AppMotion.slideUpFade`) but isn't wired.

### 6.2 Solution

Override `pageTransitionsTheme` in `ThemeData` inside `lib/core/theme/app_theme.dart`:

```dart
ThemeData(
  // ... existing fields ...
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _MotionPageTransitionsBuilder(),
      TargetPlatform.iOS: _MotionPageTransitionsBuilder(),
      TargetPlatform.macOS: _MotionPageTransitionsBuilder(),
      TargetPlatform.windows: _MotionPageTransitionsBuilder(),
      TargetPlatform.linux: _MotionPageTransitionsBuilder(),
    },
  ),
)
```

`_MotionPageTransitionsBuilder` extends `PageTransitionsBuilder` and uses `AppMotion.fadeThrough` + slide 5% with `AppDurations.medium` (300ms) and `AppCurves.decelerate`.

### 6.3 Files modified

- `lib/core/theme/app_theme.dart` — add `pageTransitionsTheme`
- New: `lib/core/theme/motion_page_transitions_builder.dart` — custom builder
- New: `test/core/theme/motion_page_transitions_builder_test.dart` — verify build pattern

### 6.4 Honor `disableAnimations`

Check `MediaQuery.disableAnimations` at build time; if true, fall back to default `ZoomPageTransitionsBuilder` (no animation).

---

## 7. Task 4 — Theme switch cross-fade

### 7.1 Problem

`ThemeMode` switches between system/light/dark (59 references in `lib/`). Currently the switch is abrupt — `MaterialApp.theme` and `MaterialApp.darkTheme` are set, but there's no animation between them.

### 7.2 Solution

Wrap the theme switches in `AnimatedTheme`:

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ref.watch(settingsNotifierProvider.select((s) => s.themeMode)),
  builder: (context, child) => AnimatedTheme(
    data: Theme.of(context),
    duration: AppDurations.extended, // 600ms
    curve: AppCurves.emphasized,
    child: child!,
  ),
)
```

Or use Flutter's built-in `ThemeMode` animation via `MaterialApp.builder` returning `Theme(data: ..., child: AnimatedTheme(...))`.

### 7.3 Behavior

- Light → Dark: 600ms eased cross-fade between `lightTheme` and `darkTheme`
- Honor `MediaQuery.disableAnimations`: if true, skip animation
- Performance: 600ms is a long animation; if it drops frames on low-end devices, honor disable flag

---

## 8. Task 5 — Haptic feedback (Android)

### 8.1 Problem

Zero `HapticFeedback` calls in `lib/`. User interactions feel mechanical — no tactile response on play/pause/next/prev/EQ change.

### 8.2 Solution

Add `HapticFeedback.lightImpact()` calls at the following interaction points:

| Interaction | Trigger | Implementation |
|---|---|---|
| Play/pause tap | `_playPause()` in mini_player, bottom_player_bar | `HapticFeedback.lightImpact()` BEFORE state change |
| Next/prev tap | `_next()` / `_previous()` | `HapticFeedback.lightImpact()` BEFORE action |
| EQ slider drag end | `onChangeEnd` on each `_buildBandSlider` | `HapticFeedback.lightImpact()` after debounce settles |
| Seek slider drag end | `onChangeEnd` on mini_player seek slider | `HapticFeedback.lightImpact()` |

Gated on Android only via existing `PlatformCapabilities.isAndroid` check.

### 8.3 Files modified

- `lib/ui/screens/mini_player_screen.dart` — play/pause, next/prev, seek
- `lib/ui/widgets/bottom_player_bar.dart` — play/pause, next/prev
- `lib/ui/widgets/equalizer_widget.dart` — band sliders (onChangeEnd)
- `lib/ui/widgets/audio_effects_dialog.dart` — apply buttons
- New: `lib/ui/utils/haptic_helper.dart` — gated `safeHaptic()` function

### 8.4 New helper

```dart
// lib/ui/utils/haptic_helper.dart
import 'package:flutter/services.dart';
import 'package:ga_song/core/platform_capabilities.dart';

/// Only fires on Android. No-op elsewhere (desktop has no haptic motor).
Future<void> safeHaptic(HapticType type) async {
  if (!PlatformCapabilities.instance.isAndroid) return;
  switch (type) {
    case HapticType.light:
      await HapticFeedback.lightImpact();
    case HapticType.medium:
      await HapticFeedback.mediumImpact();
  }
}

enum HapticType { light, medium }
```

---

## 9. Task 6 — Sound feedback opt-in

### 9.1 Problem

No audio confirmation feedback for actions like next/prev. Phones with silent switches respect user intent — opt-in is the right pattern.

### 9.2 Solution

Add new field to `SettingsState` (Freezed):

```dart
@Default(false) bool soundFeedbackEnabled,
```

When enabled:
- Play `SystemSoundType.click` (built-in to Flutter, no extra dependency) on next/prev tap
- Or use `flutter_soloud`'s built-in `playAsset` with a short click audio file (if `SystemSound` feels too generic)

When disabled (default): no sound.

### 9.3 Settings UI

Add a switch in the existing Settings widget — `soundFeedbackEnabled` toggle, with description "Phát âm thanh khi chuyển bài (chỉ áp dụng trên điện thoại)".

### 9.4 Files modified

- `lib/core/settings/settings_state.dart` — add field
- `lib/core/settings/settings_notifier.dart` — add setter
- `lib/ui/widgets/settings_widget.dart` — add UI
- `lib/ui/screens/mini_player_screen.dart` — wire `safeHaptic`-equivalent for sound on next/prev
- `lib/ui/widgets/bottom_player_bar.dart` — same

### 9.5 Implementation note

If we use `SystemSound.play(SystemSoundType.click)`, no asset needed. If we want a custom click sound, we'd need to add an audio asset and use SoLoud to play it — adds complexity. Default to `SystemSound`.

---

## 10. Task 7 — Card hover/press animation

### 10.1 Problem

Cards (e.g., album tile, song tile) use static `InkWell` without animation. Hover/press feels mechanical.

### 10.2 Solution

Wrap card-tap targets in `AnimatedContainer`:

```dart
AnimatedContainer(
  duration: AppDurations.short, // 200ms
  curve: AppCurves.decelerate,
  transform: Matrix4.identity()
    ..scale(_isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0)),
  child: InkWell(
    onTap: ...,
    onHover: (h) => setState(() => _isHovered = h),
    onHighlightChanged: (p) => setState(() => _isPressed = p),
    child: ...,
  ),
)
```

### 10.3 Affected widgets

- `lib/ui/widgets/album_grid_widget.dart` (album tiles)
- `lib/ui/widgets/song_tiles.dart` (song rows)
- `lib/ui/widgets/main_content_states.dart` (state cards)
- `lib/ui/widgets/duplicate_detector_widget.dart` (duplicate cards)

### 10.4 Behavior preservation

- Tap response identical (InkWell splash still works)
- Animation only on hover/press states
- `flutter test` must pass — tests may need to await animation before checking state

---

## 11. Task 8 — EQ slider waveform pulse

### 11.1 Problem

EQ band slider's `onChanged` triggers `_effectService.applyAllEqualizer()` but provides no immediate visual feedback. User can't tell that their drag is "doing something" until they release.

### 11.2 Solution

Wrap the EQ band slider thumb in `AnimatedContainer` that pulses glow on value change:

```dart
AnimatedContainer(
  duration: AppDurations.short, // 200ms
  curve: AppCurves.decelerate,
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: textColor.withValues(alpha: _isDragging ? 0.6 : 0.0),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  ),
  child: SliderTheme(...),
)
```

State `_isDragging` toggled in `onChangeStart` / `onChangeEnd`.

### 11.3 Behavior

- On `onChangeStart`: glow appears (alpha 0 → 0.6)
- On `onChangeEnd`: glow fades (alpha 0.6 → 0)
- Visual feedback synchronized with audio effect application (which is debounced via `DebouncedSlider` from Phase 3)

### 11.4 Files modified

- `lib/ui/widgets/equalizer_widget.dart` — wrap band sliders

---

## 12. Task 9 — Lyric transition cross-fade

### 12.1 Problem

LyricView shows current line; switching to next line is abrupt.

### 12.2 Solution

Wrap current line display in `AnimatedSwitcher`:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300), // or AppDurations.medium
  switchInCurve: Curves.easeOut,
  switchOutCurve: Curves.easeIn,
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: child,
  ),
  child: KeyedSubtree(
    key: ValueKey(currentLine.startMs), // unique per line
    child: LyricLineWidget(currentLine),
  ),
)
```

### 12.3 Files modified

- `lib/ui/widgets/lyric_view.dart`

### 12.4 Behavior preservation

- Lyric content identical
- Smooth 300ms fade between lines
- Honors `MediaQuery.disableAnimations`

---

## 13. Spec Cross-Cutting Concerns

### 13.1 Honoring `MediaQuery.disableAnimations`

All motion added in this phase must honor `MediaQuery.disableAnimations`:
- Page transitions: fall back to no animation
- Theme switch: skip animation
- Card hover/press: skip scale animation
- Lyric transition: skip fade
- EQ pulse: skip glow

Helper:

```dart
// lib/ui/utils/animation_utils.dart
import 'package:flutter/widgets.dart';

bool animationsEnabled(BuildContext context) {
  return !MediaQuery.of(context).disableAnimations;
}
```

### 13.2 Performance budget

Per Phase 3 budget:
- 60 FPS target during all animations
- No animation should drop >5% frames
- If motion drops frames on low-end Android, honor `disableAnimations` to opt out

### 13.3 Settings propagation

- Theme mode: existing `settingsNotifierProvider.select((s) => s.themeMode)` works
- Sound feedback: new `settingsNotifierProvider.select((s) => s.soundFeedbackEnabled)` to be added in Task 6

### 13.4 Backward compatibility

- No breaking changes to user data (DB schema unchanged)
- No breaking changes to `SettingsState` (only additive field for sound)
- All new code is additive; existing widgets are modified but still render correctly

---

## 14. Self-Review

### 14.1 Spec coverage check (Refined Polish spec §3.4)

| Spec deliverable | Task | Status |
|---|---|---|
| 1. Replace hardcoded colors/spacing in top 10 screens → ThemeExtension | Task 2 | ✅ |
| 2. PageRoute dùng MotionPageRoute | Task 3 | ✅ |
| 3. Card hover/press animation | Task 7 | ✅ |
| 4. Bottom player bar smooth show/hide on scroll | **DEFERRED** | ⚠️ Out of scope this phase |
| 5. EQ slider real-time visual feedback | Task 8 | ✅ |
| 6. Lyric transition cross-fade | Task 9 | ✅ |
| 7. Theme switch ColorScheme cross-fade | Task 4 | ✅ |
| 8. Material 3 ColorScheme complete (30+ tokens) | Task 2 (covered) | ✅ (uses tokens/AppColors + colorScheme) |
| 9. Haptic feedback Android | Task 5 | ✅ (Conservative scope) |
| 10. Sound feedback opt-in | Task 6 | ✅ |

### 14.2 Spec §3.4 success metrics

| Metric | Target | Verified in |
|---|---|---|
| `grep -r "Color(0x" lib/ui/ | wc -l` = 0 | Task 2 verification |
| Slider visual feedback measurable | EQ pulse in Task 8 | Manual smoke |
| Theme switch 600ms ± 50ms | Task 4 | DevTools |
| Lyric transition ≥ 58 FPS | Task 9 | Manual smoke |

### 14.3 Spec §3.4 risks

| Risk | Mitigation |
|---|---|
| Motion drops frames on low-end Android | Honor `MediaQuery.disableAnimations`; budget check via Phase 3 metrics |
| Token migration too aggressive | Top 10 screens only; bottom_player_bar + audio_effects remain legacy |
| AppColors folding breaks `app_theme.dart` | Task 1 explicitly migrates app_theme.dart's ~30 callers |
| Sound feedback opt-in confusion | Default false + clear settings UI label |

### 14.4 Placeholder scan

No TBD/TODO/fill-in-details in this spec. Every task has concrete code patterns.

### 14.5 Type consistency

- `AppColors.X` (tokens.dart, after folding)
- `Theme.of(context).extension<AppSpacingExtension>()!.X`
- `AppDurations.X`, `AppCurves.X`
- All freezed-compatible (SettingsState gains `soundFeedbackEnabled: bool`)

### 14.6 File path consistency

All paths relative to project root.

---

## 15. Execution Order

Per spec §1.2, strict sequential (Approach A from brainstorm). Order:

1. Task 1 — Fold legacy (resolves Phase 1 collision; unblocks all other tasks)
2. Task 2 — Token migration (depends on Task 1's merged tokens.dart)
3. Task 3 — Page transition (independent)
4. Task 4 — Theme switch cross-fade (independent)
5. Task 5 — Haptic feedback (independent)
6. Task 6 — Sound feedback opt-in (independent)
7. Task 7 — Card hover/press (independent)
8. Task 8 — EQ slider waveform pulse (independent)
9. Task 9 — Lyric transition (independent)

Tasks 3-9 are parallelizable after Task 2 completes. Recommend subagent-driven with 1 task at a time.

---

## 16. Execution

Plan: ~5 days wall-clock. ~9 implementation tasks. Subagent-driven recommended.

**NO COMMITS during work** (user constraint). All changes local until user commits.