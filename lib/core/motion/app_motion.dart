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

/// Holder for the user's motion preference.
///
/// Currently a single boolean field set explicitly by code that has read
/// the platform setting (e.g. `MediaQuery.disableAnimations` in Flutter,
/// or `Settings.Global.ANIMATOR_DURATION_SCALE` on Android). A
/// `MotionPreferences.fromMediaQuery` factory is planned for Phase 2.
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
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.decelerate,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
