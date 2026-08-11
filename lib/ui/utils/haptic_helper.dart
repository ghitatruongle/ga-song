import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';
import '../../core/platform_capabilities.dart';

/// Haptic feedback intensity.
enum HapticType { light, medium }

/// Fires haptic feedback. No-op on non-Android platforms.
///
/// Wraps [HapticFeedback] so callers don't have to repeat the platform gate
/// (Android-only haptics on this project). Failures on the platform channel
/// are swallowed and logged — haptics are best-effort UX, never fatal.
Future<void> safeHaptic(final HapticType type) async {
  if (!PlatformCapabilities.instance.isAndroid) return;
  try {
    switch (type) {
      case HapticType.light:
        await HapticFeedback.lightImpact();
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
    }
  } catch (e, stack) {
    AppLogger.w(
      'haptic_helper',
      'platform-channel haptic failed',
      error: e,
      stack: stack,
    );
  }
}
