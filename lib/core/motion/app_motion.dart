import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  MotionPreferences copyWith({final bool? reduceMotion}) =>
      MotionPreferences(reduceMotion: reduceMotion ?? this.reduceMotion);

  /// Creates from MediaQuery data
  factory MotionPreferences.fromMediaQuery(final MediaQueryData data) =>
      MotionPreferences(reduceMotion: data.disableAnimations);
}

/// Riverpod provider for motion preferences
final motionPreferencesProvider = Provider<MotionPreferences>((final ref) {
  // This will be updated by the app builder
  return const MotionPreferences();
});

/// Notifier for motion preferences (allows runtime updates)
class MotionPreferencesNotifier extends Notifier<MotionPreferences> {
  @override
  MotionPreferences build() => const MotionPreferences();

  void setReduceMotion(final bool reduceMotion) {
    state = state.copyWith(reduceMotion: reduceMotion);
  }
}

final motionPreferencesNotifierProvider =
    NotifierProvider<MotionPreferencesNotifier, MotionPreferences>(
      MotionPreferencesNotifier.new,
    );

/// Static helpers for motion-aware animations.
class AppMotion {
  AppMotion._();

  /// Returns [Duration.zero] when [reduceMotion] is true, else the original
  /// duration. Use this to gate any animation before scheduling it.
  static Duration applyReduce(
    final Duration d, {
    required final bool reduceMotion,
  }) => reduceMotion ? Duration.zero : d;

  /// Returns [Duration.zero] when motion preferences indicate reduced motion.
  static Duration applyReduceProvider(final Duration d, final WidgetRef ref) {
    final prefs = ref.read(motionPreferencesNotifierProvider);
    return prefs.reduceMotion ? Duration.zero : d;
  }

  /// Fade-through transition (Material 3 style). Used as a PageRoute animation
  /// and for in-place widget swaps.
  static Widget fadeThrough(
    final Widget child,
    final Animation<double> animation,
  ) => FadeTransition(opacity: animation, child: child);

  /// Slide-up + fade entrance for bottom sheets and modals.
  static Widget slideUpFade(
    final Widget child,
    final Animation<double> animation,
  ) {
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

/// Animation utility that respects reduced motion preference
class MotionAwareAnimation {
  const MotionAwareAnimation._();

  /// Creates a TweenAnimationBuilder that respects reduced motion
  static Widget builder({
    required final Duration duration,
    required final Tween<double> tween,
    required final Widget Function(BuildContext, double, Widget?) builder,
    final Widget? child,
    final Curve curve = Curves.easeInOutCubic,
  }) => Consumer(
    builder: (final context, final ref, _) {
      final reduceMotion = ref
          .watch(motionPreferencesNotifierProvider)
          .reduceMotion;
      final effectiveDuration = reduceMotion ? Duration.zero : duration;

      return TweenAnimationBuilder<double>(
        tween: tween,
        duration: effectiveDuration,
        curve: curve,
        builder: builder,
        child: child,
      );
    },
  );

  /// Creates an AnimatedContainer that respects reduced motion
  static Widget container({
    required final Widget child,
    final Duration? duration,
    final Curve curve = Curves.easeInOutCubic,
    final Decoration? decoration,
    final EdgeInsetsGeometry? padding,
    final AlignmentGeometry? alignment,
    final Color? color,
  }) => Consumer(
    builder: (final context, final ref, _) {
      final reduceMotion = ref
          .watch(motionPreferencesNotifierProvider)
          .reduceMotion;
      final effectiveDuration = reduceMotion
          ? Duration.zero
          : (duration ?? AppDurations.medium);

      return AnimatedContainer(
        duration: effectiveDuration,
        curve: curve,
        decoration: decoration,
        padding: padding,
        alignment: alignment,
        color: color,
        child: child,
      );
    },
  );

  /// Creates an AnimatedSwitcher that respects reduced motion
  static Widget switcher({
    required final Widget child,
    final Duration? duration,
    final Curve switchInCurve = Curves.easeOutCubic,
    final Curve switchOutCurve = Curves.easeInCubic,
    final Widget Function(Widget, Animation<double>)? transitionBuilder,
  }) => Consumer(
    builder: (final context, final ref, _) {
      final reduceMotion = ref
          .watch(motionPreferencesNotifierProvider)
          .reduceMotion;
      final effectiveDuration = reduceMotion
          ? Duration.zero
          : (duration ?? AppDurations.medium);

      return AnimatedSwitcher(
        duration: effectiveDuration,
        switchInCurve: switchInCurve,
        switchOutCurve: switchOutCurve,
        transitionBuilder: transitionBuilder ?? _defaultTransitionBuilder,
        child: child,
      );
    },
  );

  static Widget _defaultTransitionBuilder(
    final Widget child,
    final Animation<double> animation,
  ) => FadeTransition(opacity: animation, child: child);

  /// Creates an AnimatedOpacity that respects reduced motion
  static Widget opacity({
    required final Widget child,
    required final double opacity,
    final Duration? duration,
    final Curve curve = Curves.easeInOutCubic,
  }) => Consumer(
    builder: (final context, final ref, _) {
      final reduceMotion = ref
          .watch(motionPreferencesNotifierProvider)
          .reduceMotion;
      final effectiveDuration = reduceMotion
          ? Duration.zero
          : (duration ?? AppDurations.medium);

      return AnimatedOpacity(
        opacity: opacity,
        duration: effectiveDuration,
        curve: curve,
        child: child,
      );
    },
  );

  /// Creates an AnimatedSlide that respects reduced motion
  static Widget slide({
    required final Widget child,
    required final Offset offset,
    final Duration? duration,
    final Curve curve = Curves.easeInOutCubic,
  }) => Consumer(
    builder: (final context, final ref, _) {
      final reduceMotion = ref
          .watch(motionPreferencesNotifierProvider)
          .reduceMotion;
      final effectiveDuration = reduceMotion
          ? Duration.zero
          : (duration ?? AppDurations.medium);

      return AnimatedSlide(
        offset: offset,
        duration: effectiveDuration,
        curve: curve,
        child: child,
      );
    },
  );
}

/// Extension for easy access to motion preferences
extension MotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  MotionPreferences get motionPreferences =>
      MotionPreferences.fromMediaQuery(MediaQuery.of(this));
}
