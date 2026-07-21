import 'package:flutter/widgets.dart';

/// Returns true if the user has not requested reduced motion.
///
/// Use to gate any motion/animation in the app:
/// ```dart
/// if (animationsEnabled(context)) {
///   // do animated thing
/// }
/// ```
bool animationsEnabled(BuildContext context) {
  return !MediaQuery.of(context).disableAnimations;
}
