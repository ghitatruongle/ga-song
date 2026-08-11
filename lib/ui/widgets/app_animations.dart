import 'package:flutter/material.dart';

/// Animation utilities for smooth UI transitions.
class AppAnimations {
  AppAnimations._();

  /// Standard duration for most animations.
  static const Duration fast = Duration(milliseconds: 150);

  /// Medium duration for transitions.
  static const Duration medium = Duration(milliseconds: 300);

  /// Slow duration for complex animations.
  static const Duration slow = Duration(milliseconds: 500);

  /// Standard curve for most animations.
  static const Curve standard = Curves.easeInOut;

  /// Curve for enter animations.
  static const Curve enter = Curves.easeOut;

  /// Curve for exit animations.
  static const Curve exit = Curves.easeIn;

  /// Curve for bouncy animations.
  static const Curve bouncy = Curves.elasticOut;

  /// Creates a fade transition.
  static Widget fadeTransition({
    required final Widget child,
    required final Animation<double> animation,
  }) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: standard),
    child: child,
  );

  /// Creates a slide transition from bottom.
  static Widget slideFromBottom({
    required final Widget child,
    required final Animation<double> animation,
  }) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: enter)),
    child: FadeTransition(opacity: animation, child: child),
  );

  /// Creates a scale transition.
  static Widget scaleTransition({
    required final Widget child,
    required final Animation<double> animation,
  }) => ScaleTransition(
    scale: CurvedAnimation(parent: animation, curve: standard),
    child: child,
  );

  /// Creates an animated container with smooth transitions.
  static Widget animatedContainer({
    required final Widget child,
    required final bool condition,
    final Duration? duration,
    final Curve? curve,
  }) => AnimatedContainer(
    duration: duration ?? medium,
    curve: curve ?? standard,
    child: child,
  );

  /// Creates a hero animation wrapper.
  static Widget hero({
    required final String tag,
    required final Widget child,
  }) => Hero(tag: tag, child: child);

  /// Creates an animated switcher for swapping widgets.
  static Widget animatedSwitcher({
    required final Widget child,
    final Duration? duration,
    final Widget Function(Widget, Animation<double>)? transitionBuilder,
  }) => AnimatedSwitcher(
    duration: duration ?? medium,
    transitionBuilder:
        transitionBuilder ??
        (final child, final animation) =>
            FadeTransition(opacity: animation, child: child),
    child: child,
  );
}
