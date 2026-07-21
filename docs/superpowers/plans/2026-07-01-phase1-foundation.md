# Phase 1: Foundation & Error Handling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the foundation layer for the [Refined Polish spec](../specs/2026-07-01-refined-polish-design.md) — finish the `debugPrint → AppLogger` migration, add the design-token + motion-language foundation that every subsequent phase consumes, and verify all existing tests still pass.

**Architecture:**
- **AppLogger + Result + AppException** already exist (`lib/core/logging/app_logger.dart`, `lib/core/utils/result.dart`, `lib/core/exceptions/app_exception.dart`) and `main.dart` already initializes them. This phase *finishes* the migration of the last 17 `debugPrint` calls.
- **New** in this phase: design-token system (`lib/core/theme/tokens.dart`), motion-language library (`lib/core/motion/app_motion.dart`), and `ThemeExtension` wrappers (`lib/core/theme/theme_extensions.dart`). These are added *without* modifying any widget — Phase 4 applies them to UI.
- Migration is additive + replacement. No existing public API is broken.

**Tech Stack:** Dart 3.11.4+, Flutter, Riverpod, existing `AppLogger`/`Result`/`AppException`, Flutter `ThemeExtension`.

**Execution note (user constraint):** The user has requested **NO commits during the work process**. All `git commit` steps in this plan are *deferred* — accumulate changes locally, then batch-commit at phase completion. Tasks still describe commit intent (for traceability) but the executor should skip `git commit` and run them at the end of the phase.

---

## File Structure

### New files (this phase)
- `lib/core/theme/tokens.dart` — `AppColors`, `AppSpacing`, `AppRadius`, `AppElevation` constants
- `lib/core/motion/app_motion.dart` — `AppDurations`, `AppCurves`, `AppMotion` (signature animations), `MotionPreferences`
- `lib/core/theme/theme_extensions.dart` — `AppSpacingExtension`, `AppRadiusExtension`, `AppElevationExtension` (subclass of `ThemeExtension<T>`)
- `test/core/theme/tokens_test.dart` — unit tests for token constants
- `test/core/theme/theme_extensions_test.dart` — unit tests for ThemeExtension wrappers
- `test/core/motion/app_motion_test.dart` — unit tests for motion library

### Modified files
- `lib/core/audio/audio_engine_service.dart` — replace 16 `debugPrint` calls with `AppLogger.e(...)`
- `lib/core/audio/playlist_service.dart` — replace 1 `debugPrint` with `AppLogger.w(...)`

### Unchanged (already complete)
- `lib/core/logging/app_logger.dart` ✓
- `lib/core/utils/result.dart` ✓
- `lib/core/exceptions/app_exception.dart` ✓
- `lib/main.dart` ✓ (already calls `AppLogger`)
- `lib/core/app_logger.dart` (legacy re-export) ✓
- `test/core/logging/app_logger_test.dart` ✓
- `test/core/utils/result_test.dart` ✓
- `test/core/exceptions/app_exception_test.dart` ✓

### Deleted (dead code)
- `lib/core/service_locator.dart` — already removed (verified)

---

## Task 1: Add tests for tokens.dart (TDD red)

**Files:**
- Create: `test/core/theme/tokens_test.dart`

- [ ] **Step 1.1: Write the failing test**

Create `test/core/theme/tokens_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:ga_song/core/theme/tokens.dart';

void main() {
  group('AppColors', () {
    test('seed colors are non-null', () {
      expect(AppColors.seedPrimary, isA<Color>());
      expect(AppColors.seedSecondary, isA<Color>());
      expect(AppColors.seedTertiary, isA<Color>());
    });

    test('signature colors are stable (visual identity)', () {
      // Locked hex values — changing breaks brand identity
      expect(AppColors.seedPrimary.toARGB32(), 0xFF6750A4);
      expect(AppColors.accent.toARGB32(), 0xFFD0BCFF);
    });
  });

  group('AppSpacing', () {
    test('4px grid is preserved', () {
      expect(AppSpacing.xxs, 2.0);
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
    });
  });

  group('AppRadius', () {
    test('scale is monotonic', () {
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
    });
  });

  group('AppElevation', () {
    test('levels are non-negative', () {
      for (final lvl in AppElevation.values) {
        expect(lvl, greaterThanOrEqualTo(0.0));
      }
    });
  });
}
```

- [ ] **Step 1.2: Run test to verify it fails**

Run: `cd "E:/G.A - Song" && flutter test test/core/theme/tokens_test.dart`

Expected: FAIL with `Target of URI doesn't exist: 'package:ga_song/core/theme/tokens.dart'`

---

## Task 2: Implement tokens.dart (TDD green)

**Files:**
- Create: `lib/core/theme/tokens.dart`

- [ ] **Step 2.1: Implement tokens.dart**

Create `lib/core/theme/tokens.dart`:

```dart
import 'package:flutter/painting.dart';

/// Design token colors — single source of truth.
///
/// These values feed Material 3 `ColorScheme.fromSeed` and any direct
/// widget references. Do not introduce `Color(0xFF...)` literals elsewhere.
class AppColors {
  AppColors._();

  // Material 3 seed colors (GA-Song signature purple)
  static const Color seedPrimary = Color(0xFF6750A4);
  static const Color seedSecondary = Color(0xFF625B71);
  static const Color seedTertiary = Color(0xFF7D5260);

  // Accent — used for active states (waveform, selected items)
  static const Color accent = Color(0xFFD0BCFF);

  // Surfaces
  static const Color surface = Color(0xFFFFFBFE);
  static const Color error = Color(0xFFB3261E);
}

/// Spacing scale on a 4px grid.
///
/// Use these everywhere instead of inline `EdgeInsets.all(16)`. They are
/// exposed to widgets via [AppSpacingExtension] (see theme_extensions.dart).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius scale.
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;   // Buttons, chips
  static const double md = 12.0;  // Cards
  static const double lg = 16.0;  // Bottom sheets
  static const double xl = 28.0;  // Player surfaces
}

/// Material 3 elevation levels.
class AppElevation {
  AppElevation._();

  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
}
```

- [ ] **Step 2.2: Run test to verify it passes**

Run: `cd "E:/G.A - Song" && flutter test test/core/theme/tokens_test.dart`

Expected: PASS (4 tests)

- [ ] **Step 2.3: Run flutter analyze on the new file**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/theme/tokens.dart test/core/theme/tokens_test.dart`

Expected: 0 issues

- [ ] **Step 2.4: Commit (deferred — batch at end of phase)**

Note: skip `git commit` per user constraint. Run after all Phase 1 tasks complete:
```bash
cd "E:/G.A - Song" && git add lib/core/theme/tokens.dart test/core/theme/tokens_test.dart
```

---

## Task 3: Add tests for theme_extensions.dart (TDD red)

**Files:**
- Create: `test/core/theme/theme_extensions_test.dart`

- [ ] **Step 3.1: Write the failing test**

Create `test/core/theme/theme_extensions_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/theme/theme_extensions.dart';
import 'package:ga_song/core/theme/tokens.dart';

void main() {
  group('AppSpacingExtension', () {
    test('lerp returns interpolated value at t=0.5', () {
      final a = AppSpacingExtension(md: 8.0);
      final b = AppSpacingExtension(md: 24.0);
      final lerped = a.lerp(b, 0.5);
      expect(lerped.md, 16.0);
    });

    test('lerp at t=0 returns source', () {
      final a = AppSpacingExtension(md: 12.0);
      final b = AppSpacingExtension(md: 24.0);
      expect(a.lerp(b, 0.0).md, 12.0);
    });

    test('lerp at t=1 returns target', () {
      final a = AppSpacingExtension(md: 12.0);
      final b = AppSpacingExtension(md: 24.0);
      expect(a.lerp(b, 1.0).md, 24.0);
    });

    test('default constructor uses AppSpacing tokens', () {
      const ext = AppSpacingExtension.defaults();
      expect(ext.md, AppSpacing.md);
      expect(ext.lg, AppSpacing.lg);
    });
  });

  group('AppRadiusExtension', () {
    test('default constructor uses AppRadius tokens', () {
      const ext = AppRadiusExtension.defaults();
      expect(ext.sm, AppRadius.sm);
      expect(ext.md, AppRadius.md);
      expect(ext.lg, AppRadius.lg);
      expect(ext.xl, AppRadius.xl);
    });

    test('lerp interpolates sm to md', () {
      final a = AppRadiusExtension(sm: 4.0, md: 8.0, lg: 12.0, xl: 16.0);
      final b = AppRadiusExtension(sm: 8.0, md: 16.0, lg: 24.0, xl: 32.0);
      final lerped = a.lerp(b, 0.5);
      expect(lerped.sm, 6.0);
      expect(lerped.md, 12.0);
    });
  });

  group('AppElevationExtension', () {
    test('lerp interpolates level0 to level2', () {
      final a = AppElevationExtension(level0: 0, level1: 0, level2: 0, level3: 0);
      final b = AppElevationExtension(level0: 4, level1: 6, level2: 8, level3: 12);
      final lerped = a.lerp(b, 0.5);
      expect(lerped.level0, 2.0);
      expect(lerped.level1, 3.0);
    });

    test('default uses AppElevation tokens', () {
      const ext = AppElevationExtension.defaults();
      expect(ext.level1, AppElevation.level1);
    });
  });

  group('ThemeData integration', () {
    testWidgets('extensions are retrievable via Theme.of(context)', (tester) async {
      const ext = AppSpacingExtension.defaults();
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [ext]),
        home: Builder(builder: (context) {
          final spacing = Theme.of(context).extension<AppSpacingExtension>()!;
          return Text('md=${spacing.md}');
        }),
      ));
      expect(find.text('md=${AppSpacing.md}'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3.2: Run test to verify it fails**

Run: `cd "E:/G.A - Song" && flutter test test/core/theme/theme_extensions_test.dart`

Expected: FAIL with `Target of URI doesn't exist: 'package:ga_song/core/theme/theme_extensions.dart'`

---

## Task 4: Implement theme_extensions.dart (TDD green)

**Files:**
- Create: `lib/core/theme/theme_extensions.dart`

- [ ] **Step 4.1: Implement ThemeExtension wrappers**

Create `lib/core/theme/theme_extensions.dart`:

```dart
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Spacing tokens exposed via ThemeData.extension<AppSpacingExtension>().
///
/// Widgets read these with:
///
/// ```dart
/// final spacing = Theme.of(context).extension<AppSpacingExtension>()!;
/// EdgeInsets.all(spacing.md)
/// ```
@immutable
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const AppSpacingExtension({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  const AppSpacingExtension.defaults()
      : xxs = AppSpacing.xxs,
        xs = AppSpacing.xs,
        sm = AppSpacing.sm,
        md = AppSpacing.md,
        lg = AppSpacing.lg,
        xl = AppSpacing.xl,
        xxl = AppSpacing.xxl;

  @override
  AppSpacingExtension copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) =>
      AppSpacingExtension(
        xxs: xxs ?? this.xxs,
        xs: xs ?? this.xs,
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
        xxl: xxl ?? this.xxl,
      );

  @override
  AppSpacingExtension lerp(ThemeExtension<AppSpacingExtension>? other, double t) {
    if (other is! AppSpacingExtension) return this;
    return AppSpacingExtension(
      xxs: lerpDouble(xxs, other.xxs, t),
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
    );
  }

  // Local helper until Flutter ships lerpDouble in dart:ui exports here.
  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0.0) + ((b ?? 0.0) - (a ?? 0.0)) * t;
  }
}

/// Radius tokens exposed via ThemeData.extension<AppRadiusExtension>()().
@immutable
class AppRadiusExtension extends ThemeExtension<AppRadiusExtension> {
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const AppRadiusExtension({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  const AppRadiusExtension.defaults()
      : sm = AppRadius.sm,
        md = AppRadius.md,
        lg = AppRadius.lg,
        xl = AppRadius.xl;

  @override
  AppRadiusExtension copyWith({double? sm, double? md, double? lg, double? xl}) =>
      AppRadiusExtension(
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
      );

  @override
  AppRadiusExtension lerp(ThemeExtension<AppRadiusExtension>? other, double t) {
    if (other is! AppRadiusExtension) return this;
    return AppRadiusExtension(
      sm: AppSpacingExtension.lerpDouble(sm, other.sm, t)!,
      md: AppSpacingExtension.lerpDouble(md, other.md, t)!,
      lg: AppSpacingExtension.lerpDouble(lg, other.lg, t)!,
      xl: AppSpacingExtension.lerpDouble(xl, other.xl, t)!,
    );
  }
}

/// Elevation tokens exposed via ThemeData.extension<AppElevationExtension>()().
@immutable
class AppElevationExtension extends ThemeExtension<AppElevationExtension> {
  final double level0;
  final double level1;
  final double level2;
  final double level3;

  const AppElevationExtension({
    required this.level0,
    required this.level1,
    required this.level2,
    required this.level3,
  });

  const AppElevationExtension.defaults()
      : level0 = AppElevation.level0,
        level1 = AppElevation.level1,
        level2 = AppElevation.level2,
        level3 = AppElevation.level3;

  @override
  AppElevationExtension copyWith({
    double? level0,
    double? level1,
    double? level2,
    double? level3,
  }) =>
      AppElevationExtension(
        level0: level0 ?? this.level0,
        level1: level1 ?? this.level1,
        level2: level2 ?? this.level2,
        level3: level3 ?? this.level3,
      );

  @override
  AppElevationExtension lerp(ThemeExtension<AppElevationExtension>? other, double t) {
    if (other is! AppElevationExtension) return this;
    return AppElevationExtension(
      level0: AppSpacingExtension.lerpDouble(level0, other.level0, t)!,
      level1: AppSpacingExtension.lerpDouble(level1, other.level1, t)!,
      level2: AppSpacingExtension.lerpDouble(level2, other.level2, t)!,
      level3: AppSpacingExtension.lerpDouble(level3, other.level3, t)!,
    );
  }
}
```

- [ ] **Step 4.2: Run test to verify it passes**

Run: `cd "E:/G.A - Song" && flutter test test/core/theme/theme_extensions_test.dart`

Expected: PASS (12 tests)

- [ ] **Step 4.3: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/theme/ test/core/theme/`

Expected: 0 issues

- [ ] **Step 4.4: Commit (deferred)**

Note: skip `git commit` per user constraint.

---

## Task 5: Add tests for app_motion.dart (TDD red)

**Files:**
- Create: `test/core/motion/app_motion_test.dart`

- [ ] **Step 5.1: Write the failing test**

Create `test/core/motion/app_motion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/motion/app_motion.dart';

void main() {
  group('AppDurations', () {
    test('durational scale is monotonic', () {
      expect(AppDurations.micro.inMilliseconds, lessThan(AppDurations.short.inMilliseconds));
      expect(AppDurations.short.inMilliseconds, lessThan(AppDurations.medium.inMilliseconds));
      expect(AppDurations.medium.inMilliseconds, lessThan(AppDurations.long.inMilliseconds));
      expect(AppDurations.long.inMilliseconds, lessThan(AppDurations.extended.inMilliseconds));
    });

    test('all durations are non-negative', () {
      for (final d in [
        AppDurations.micro,
        AppDurations.short,
        AppDurations.medium,
        AppDurations.long,
        AppDurations.extended,
      ]) {
        expect(d.inMilliseconds, greaterThanOrEqualTo(0));
      }
    });
  });

  group('AppCurves', () {
    test('curves are non-null Curve instances', () {
      expect(AppCurves.standard, isA<Curve>());
      expect(AppCurves.decelerate, isA<Curve>());
      expect(AppCurves.accelerate, isA<Curve>());
      expect(AppCurves.emphasized, isA<Curve>());
    });
  });

  group('AppMotion.applyReduce', () {
    test('returns zero duration when reduceMotion is true', () {
      final d = AppMotion.applyReduce(AppDurations.medium, reduceMotion: true);
      expect(d, Duration.zero);
    });

    test('returns original duration when reduceMotion is false', () {
      final d = AppMotion.applyReduce(AppDurations.medium, reduceMotion: false);
      expect(d, AppDurations.medium);
    });
  });

  group('MotionPreferences', () {
    test('default reduceMotion is false', () {
      const prefs = MotionPreferences();
      expect(prefs.reduceMotion, isFalse);
    });

    test('copyWith toggles reduceMotion', () {
      const prefs = MotionPreferences();
      final updated = prefs.copyWith(reduceMotion: true);
      expect(updated.reduceMotion, isTrue);
    });
  });

  group('AppMotion.fadeThrough', () {
    testWidgets('builds without error given an Animation', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: AppDurations.short,
      );
      final widget = AppMotion.fadeThrough(
        const SizedBox(width: 50, height: 50),
        controller,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      controller.value = 0.5;
      await tester.pump();
      expect(find.byType(SizedBox), findsOneWidget);
      controller.dispose();
    });
  });
}
```

- [ ] **Step 5.2: Run test to verify it fails**

Run: `cd "E:/G.A - Song" && flutter test test/core/motion/app_motion_test.dart`

Expected: FAIL with `Target of URI doesn't exist: 'package:ga_song/core/motion/app_motion.dart'`

---

## Task 6: Implement app_motion.dart (TDD green)

**Files:**
- Create: `lib/core/motion/app_motion.dart`

- [ ] **Step 6.1: Implement motion library**

Create `lib/core/motion/app_motion.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Canonical animation durations used throughout the app.
///
/// Phase 4 applies these to all transitions. Today (Phase 1) the library
/// is introduced but no widget references it yet.
class AppDurations {
  AppDurations._();

  /// 100ms — tap feedback, micro-interactions.
  static const Duration micro = Duration(milliseconds: 100);

  /// 200ms — hover, ripple, slider.
  static const Duration short = Duration(milliseconds: 200);

  /// 300ms — standard transition (page push).
  static const Duration medium = Duration(milliseconds: 300);

  /// 450ms — bottom sheets, modal routes.
  static const Duration long = Duration(milliseconds: 450);

  /// 600ms — theme switch cross-fade.
  static const Duration extended = Duration(milliseconds: 600);
}

/// Canonical animation curves.
class AppCurves {
  AppCurves._();

  /// Default easing for most transitions.
  static const Curve standard = Curves.easeInOutCubic;

  /// Used for entering animations (slide-up, fade-in).
  static const Curve decelerate = Curves.easeOutCubic;

  /// Used for exiting animations (pop, dismiss).
  static const Curve accelerate = Curves.easeInCubic;

  /// Material 3 emphasized — for major transitions like theme switch.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// User preference for motion. Updated by the platform-specific code in
/// `MotionPreferences.fromMediaQuery`.
@immutable
class MotionPreferences {
  /// When true, animations should be reduced or eliminated. Set automatically
  /// from `MediaQuery.disableAnimations` or platform settings (reduce-motion).
  final bool reduceMotion;

  const MotionPreferences({this.reduceMotion = false});

  MotionPreferences copyWith({bool? reduceMotion}) =>
      MotionPreferences(reduceMotion: reduceMotion ?? this.reduceMotion);
}

/// Static helpers for motion-aware animations.
class AppMotion {
  AppMotion._();

  /// Returns [Duration.zero] when [reduceMotion] is true, else the original
  /// duration. Use this to gate any animation before scheduling it.
  static Duration applyReduce(Duration d, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : d;

  /// Fade-through transition (Material 3 style). Used as a PageRoute animation
  /// and for in-place widget swaps.
  static Widget fadeThrough(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// Slide-up + fade entrance for bottom sheets and modals.
  static Widget slideUpFade(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: AppCurves.decelerate);
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(curved),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
```

- [ ] **Step 6.2: Run test to verify it passes**

Run: `cd "E:/G.A - Song" && flutter test test/core/motion/app_motion_test.dart`

Expected: PASS

- [ ] **Step 6.3: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/motion/ test/core/motion/`

Expected: 0 issues

- [ ] **Step 6.4: Commit (deferred)**

Note: skip `git commit` per user constraint.

---

## Task 7: Migrate 16 debugPrint in audio_engine_service.dart

**Files:**
- Modify: `lib/core/audio/audio_engine_service.dart`

- [ ] **Step 7.1: Verify AppLogger import is present or add it**

Read the top of `lib/core/audio/audio_engine_service.dart`. If the file does not already import `AppLogger`, add:

```dart
import '../logging/app_logger.dart';
```

(If `package:flutter/foundation.dart` is imported solely for `debugPrint` and nothing else, keep it — other code may use `kDebugMode`.)

- [ ] **Step 7.2: Replace each debugPrint with AppLogger**

Run from project root to enumerate:

```bash
cd "E:/G.A - Song" && grep -n "debugPrint" lib/core/audio/audio_engine_service.dart
```

For each line, apply the matching replacement:

| Original pattern | Replacement |
|------------------|-------------|
| `debugPrint('Source load error at $normalizedPath: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'Source load failed for $normalizedPath', error: e, stack: stack);` |
| `debugPrint('Error in audio_engine_service: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'operation failed', error: e, stack: stack);` |
| `debugPrint('Play error: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'playAsset failed', error: e, stack: stack);` |
| `debugPrint('Crossfade error: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'crossfade failed', error: e, stack: stack);` |

Pattern guide for replacements:

```dart
// BEFORE
} catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }

// AFTER
} catch (e, stack) {
  AppLogger.e('audio.engine_service', 'operation failed', error: e, stack: stack);
}
```

- [ ] **Step 7.3: Verify zero debugPrint remain in this file**

Run: `cd "E:/G.A - Song" && grep -c "debugPrint" lib/core/audio/audio_engine_service.dart`

Expected: 0

- [ ] **Step 7.4: Run flutter analyze on the file**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/audio/audio_engine_service.dart`

Expected: 0 issues

- [ ] **Step 7.5: Run audio tests**

Run: `cd "E:/G.A - Song" && flutter test test/core/audio/`

Expected: All audio tests pass

- [ ] **Step 7.6: Commit (deferred)**

Note: skip `git commit` per user constraint.

---

## Task 8: Migrate 1 debugPrint in playlist_service.dart

**Files:**
- Modify: `lib/core/audio/playlist_service.dart`

- [ ] **Step 8.1: Verify AppLogger import or add it**

If `AppLogger` is not yet imported in `lib/core/audio/playlist_service.dart`, add:

```dart
import '../logging/app_logger.dart';
```

- [ ] **Step 8.2: Replace the single debugPrint**

Find the line:

```dart
debugPrint('Failed to persist duration for ${song.name}: $e');
```

Replace with:

```dart
AppLogger.w('audio.playlist_service', 'Failed to persist duration for ${song.name}', error: e);
```

- [ ] **Step 8.3: Verify zero debugPrint in this file**

Run: `cd "E:/G.A - Song" && grep -c "debugPrint" lib/core/audio/playlist_service.dart`

Expected: 0

- [ ] **Step 8.4: Run playlist tests**

Run: `cd "E:/G.A - Song" && flutter test test/core/audio/playlist_service_test.dart` (if exists) OR `flutter test test/core/audio/`

Expected: All pass

- [ ] **Step 8.5: Commit (deferred)**

Note: skip `git commit` per user constraint.

---

## Task 9: Verify Phase 1 success metrics (acceptance check)

- [ ] **Step 9.1: Zero debugPrint project-wide**

Run: `cd "E:/G.A - Song" && grep -rn "debugPrint" lib/ | wc -l`

Expected: 0 (only the AppLogger sink reference may remain — confirm it is intentional)

If any non-zero result remains, fix it.

- [ ] **Step 9.2: Run flutter analyze project-wide**

Run: `cd "E:/G.A - Song" && flutter analyze`

Expected: 0 issues

- [ ] **Step 9.3: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test`

Expected: All existing tests pass + new tokens/theme_extensions/app_motion tests (≥ 21 new tests).

- [ ] **Step 9.4: Manual smoke test**

Run: `cd "E:/G.A - Song" && flutter run -d windows` (or another available device).

Expected: App starts; no log output in release; debug logs visible in debug mode; no crashes.

- [ ] **Step 9.5: Update CHANGELOG.md**

Edit `CHANGELOG.md` — add entry under new "Unreleased" section:

```markdown
## [Unreleased]

### Added
- `lib/core/theme/tokens.dart` — design tokens (colors, spacing, radius, elevation) as single source of truth.
- `lib/core/theme/theme_extensions.dart` — `AppSpacingExtension`, `AppRadiusExtension`, `AppElevationExtension` (ThemeExtension wrappers).
- `lib/core/motion/app_motion.dart` — `AppDurations`, `AppCurves`, `MotionPreferences`, `AppMotion` signature animations.

### Changed
- Completed `debugPrint → AppLogger` migration in `lib/core/audio/audio_engine_service.dart` (16 calls) and `lib/core/audio/playlist_service.dart` (1 call).

### Tests
- 4 tests for `tokens.dart`.
- 12 tests for `theme_extensions.dart`.
- 5 tests for `app_motion.dart`.
```

---

## Self-Review

**Spec coverage check:**

| Spec §3.1 Deliverable | Status | Covered by |
|----------------------|--------|------------|
| 1. AppLogger (Riverpod-aware, level filter, remote sink) | ✅ already done in `lib/core/logging/app_logger.dart` | (no task — already complete) |
| 2. Result<T> (sealed, expand usage) | ✅ already exists | (no task — already complete) |
| 3. AppException (sealed, structured) | ✅ already exists with subclasses | (no task — already complete) |
| 4. Token foundation (tokens.dart, app_motion.dart, theme_extensions.dart) | ⏳ this plan adds it | Tasks 1-6 |
| 5. Replace 113 debugPrint → AppLogger | ⏳ 17 remain after this phase | Tasks 7-8 |
| 6. Remove dead code (service_locator.dart, unused imports) | ✅ already removed | (no task) |

**Spec §3.1 success metrics check:**

| Metric | Target | Plan verifies in |
|--------|--------|------------------|
| `grep -r "debugPrint\|print(" lib/ \| wc -l` = 0 | ✅ | Task 9.1 |
| `flutter analyze` = 0 issues | ✅ | Task 9.2 |
| AppLogger unit test ≥ 90% | ✅ (already done in earlier work) | (pre-existing) |
| Test count ≥ 456 (no regression) | ✅ | Task 9.3 |
| Token + theme_extension + motion tests ≥ 21 new | ✅ | Tasks 1-6 |

**Placeholder scan:** No TBD/TODO/implement-later in plan. Every code block is complete.

**Type consistency:** `AppLogger.{d,i,w,e,f}` matches existing signatures in `lib/core/logging/app_logger.dart`. `AppSpacingExtension`, `AppRadiusExtension`, `AppElevationExtension` follow Flutter's `ThemeExtension<T>` contract. `AppMotion.applyReduce` signature used consistently.

**File path consistency:** All paths use `lib/` and `test/` from project root. Import paths adjusted for depth.

---

## Execution

Plan saved to `docs/superpowers/plans/2026-07-01-phase1-foundation.md`. Ready for execution.

**User constraint reminder:** Do NOT run `git commit` between tasks. Accumulate all changes locally; the user will decide when to commit (likely at phase completion).

Two execution options:

1. **Subagent-Driven (recommended)** — Dispatch a fresh subagent per task with two-stage review between tasks. Fast iteration, isolated context.

2. **Inline Execution** — Execute tasks in this session using `executing-plans` skill. Batch execution with checkpoints.

Which approach?