import 'package:flutter/material.dart';

import '../motion/app_motion.dart';

/// Material 3 fade-through page transition (300ms, decelerate curve).
///
/// Honors [MediaQuery.disableAnimations] — falls back to an instant
/// transition (no animation) when the user has reduced motion enabled.
class MotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const MotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    return AppMotion.slideUpFade(child, animation);
  }
}
