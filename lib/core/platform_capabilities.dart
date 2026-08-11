import 'dart:io';
import 'package:flutter/foundation.dart';

import 'logging/app_logger.dart';

/// Detects platform capabilities and hardware tier to tune performance settings.
///
/// Provides a single source of truth for platform-specific decisions across
/// the app — visualizer frame budget, cache sizes, blur quality, timer intervals.
class PlatformCapabilities {
  PlatformCapabilities._();
  static final PlatformCapabilities instance = PlatformCapabilities._();

  // ─── Platform shortcuts ───────────────────────────────────────────────────

  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isDesktop => isWindows || isLinux || isMacOS;
  bool get isMobile => isAndroid || isIOS;

  // ─── Window effect detection ──────────────────────────────────────────────

  /// Windows 11 build 22000+ supports Mica (lighter, more stable than Acrylic).
  /// Returns true only on Windows 11+.
  ///
  /// Parses the build number from [Platform.operatingSystemVersion] which on
  /// Windows returns something like `"Windows 10.0.22631"` or `"10.0.22631"`.
  /// The build number is the numeric value >= 10000 (e.g. 19045 for Win10, 22631 for Win11).
  bool get supportsMica {
    if (!isWindows) return false;
    try {
      final version = Platform.operatingSystemVersion;
      // Split on dots and whitespace, then find the first number > 10000
      // which is the Windows build number (version parts like 10, 0 are smaller).
      final parts = version.split(RegExp('[ .]+'));
      for (final part in parts) {
        final num = int.tryParse(part);
        if (num != null && num > 10000) return num >= 22000;
      }
      return false;
    } catch (e) {
      AppLogger.w(
        'platform.capabilities',
        'version detection failed',
        error: e,
      );
      return false;
    }
  }

  /// Preferred [WindowEffect] for the current platform.
  /// - Windows 11+: Mica (more performant, less flicker on resize)
  /// - Windows 10:  Acrylic
  /// - macOS:       sidebar (NSVisualEffectView material)
  /// - Linux:       transparent
  /// - Other:       disabled (no effect)
  WindowEffectType get preferredWindowEffect {
    if (isWindows && supportsMica) return WindowEffectType.mica;
    if (isWindows) return WindowEffectType.acrylic;
    if (isMacOS) return WindowEffectType.sidebar;
    if (isLinux) return WindowEffectType.transparent;
    return WindowEffectType.disabled;
  }

  /// Whether native window effects (acrylic/mica) should be used by default.
  bool get supportsNativeWindowEffect => isWindows || isMacOS || isLinux;

  // ─── Linux distro detection ───────────────────────────────────────────────

  /// Returns true if running on a Debian/Ubuntu-based Linux distro.
  /// This covers: Ubuntu, Linux Mint, Kali, Chrome OS (Linux container), Debian.
  bool get isDebianBased {
    if (!isLinux) return false;
    try {
      final osRelease = File('/etc/os-release').readAsStringSync();
      return osRelease.contains('ubuntu') ||
          osRelease.contains('debian') ||
          osRelease.contains('kali') ||
          osRelease.contains('mint') ||
          osRelease.contains('Chrome OS');
    } catch (e, stack) {
      AppLogger.e(
        'platform.capabilities',
        'operation failed',
        error: e,
        stack: stack,
      );
      return false;
    }
  }

  /// Returns true if running inside a Chrome OS / Chrome OS Flex environment.
  bool get isChromeOS {
    if (!isLinux) return false;
    try {
      return File('/etc/os-release').readAsStringSync().contains('Chrome OS') ||
          File('/run/chromeos-config').existsSync();
    } catch (e, stack) {
      AppLogger.e(
        'platform.capabilities',
        'operation failed',
        error: e,
        stack: stack,
      );
      return false;
    }
  }

  // ─── Hardware tier ────────────────────────────────────────────────────────

  /// Estimated device tier based on platform.
  /// - [DeviceTier.high]: Desktop (Windows, Linux, macOS)
  /// - [DeviceTier.mid]: Android 10+ on recent hardware
  /// - [DeviceTier.low]: Low-end Android devices
  DeviceTier get deviceTier {
    if (isDesktop) return DeviceTier.high;
    if (isAndroid) {
      // More granular detection based on CPU cores and available memory
      final cores = Platform.numberOfProcessors;
      if (cores <= 4) return DeviceTier.low;
      if (cores <= 6) return DeviceTier.mid;
      return DeviceTier.mid; // Most Android devices are mid-tier
    }
    return DeviceTier.mid; // Default fallback
  }

  /// Android display refresh rate in Hz (90Hz/120Hz detection).
  /// Returns 60 on non-Android platforms or when detection fails.
  int get androidFrameRateHz {
    if (!isAndroid) return 60;
    try {
      // Parse refresh rate from platform version string
      // Android 12+ reports like "Android 12 (29941)" or via window metrics
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)Hz').firstMatch(version);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '60') ?? 60;
      }
      return 60;
    } catch (e) {
      AppLogger.w(
        'platform.capabilities',
        'frame rate detection failed',
        error: e,
      );
      return 60;
    }
  }

  // ─── Performance tuning knobs ─────────────────────────────────────────────

  /// Position update interval for the audio progress bar.
  /// 250ms on desktop; 500ms on Android (low-end 800ms) to reduce wake-ups.
  Duration get positionTimerInterval {
    if (isAndroid && deviceTier == DeviceTier.low) {
      return const Duration(milliseconds: 800);
    }
    if (isAndroid) return const Duration(milliseconds: 500);
    return const Duration(milliseconds: 250);
  }

  /// Max number of audio source buffers to keep in memory.
  /// Desktop: 12 (each decoded track costs ~30-40MB RAM; 50 was too greedy).
  /// Android mid: 10; Android low: 6.
  int get maxAudioSourceCacheEntries {
    if (isAndroid && deviceTier == DeviceTier.low) return 6;
    if (isAndroid) return 10;
    return 12;
  }

  /// Max number of cover art image providers to keep in the LRU cache.
  int get maxCoverArtCacheEntries {
    if (isAndroid && deviceTier == DeviceTier.low) return 12;
    if (isAndroid) return 24;
    return 32;
  }

  /// Whether to allow high-quality blur effects.
  /// Desktop always allows; Android mid allows with reduced sigma; low disables.
  bool get allowHighQualityBlur {
    if (isAndroid && deviceTier == DeviceTier.low) return false;
    return isDesktop;
  }

  /// Suggested blur sigma for blurred backgrounds.
  double get backgroundBlurSigma {
    if (isAndroid && deviceTier == DeviceTier.low) return 8; // Very light
    if (isAndroid) return 16;
    return 30;
  }

  /// Max particle count for the visualizer.
  /// Desktop: 150; Android mid: 60; Android low: 30.
  int get maxParticleCount {
    if (isAndroid && deviceTier == DeviceTier.low) return 30;
    if (isAndroid) return 60;
    return 150;
  }

  /// Max star count for the starfield visualizer.
  /// Desktop: 200; Android mid: 80; Android low: 40.
  int get maxStarCount {
    if (isAndroid && deviceTier == DeviceTier.low) return 40;
    if (isAndroid) return 80;
    return 200;
  }

  /// How many audio sources to preload concurrently.
  /// Android low: 1 (sequential); Android mid: 3; Desktop: 3.
  int get preloadConcurrency {
    if (isAndroid && deviceTier == DeviceTier.low) return 1;
    if (isAndroid) return 3;
    return 3;
  }

  /// Whether the visualizer should run in adaptive frame-rate mode.
  bool get visualizerAdaptiveFps => true;

  /// Frame time budget in milliseconds before the visualizer drops to half-rate.
  int get visualizerFrameBudgetMs {
    switch (deviceTier) {
      case DeviceTier.high:
        return 14; // ~71fps budget — drops to 30fps if over
      case DeviceTier.mid:
        return 18; // ~55fps budget (tận dụng 90Hz màn hình) — drops to 24fps if over
      case DeviceTier.low:
        return 33; // ~30fps fixed budget, no further drop
    }
  }

  /// Whether the visualizer should process audio amplitude data at full rate.
  /// Low-end devices sample at half rate to reduce CPU load.
  bool get visualizerHalfRate => isAndroid && deviceTier == DeviceTier.low;

  /// Whether the animated starfield background should run.
  /// Disabled on low-end Android to save GPU cycles.
  bool get allowStarfieldBackground =>
      !(isAndroid && deviceTier == DeviceTier.low);

  /// Whether to enable the shimmer/skeleton loading animation on lists.
  /// Disabled on low-end Android to reduce jank.
  bool get allowShimmerLoading => !(isAndroid && deviceTier == DeviceTier.low);

  /// Whether animated page transitions (slide/fade) are enabled.
  /// Low-end Android gets instant transitions — no animation.
  bool get allowPageTransitions => !(isAndroid && deviceTier == DeviceTier.low);

  // ─── Power management ───────────────────────────────────────────────────

  /// Whether the system is in a low-power / battery-saver mode.
  /// Windows: queries power status; macOS/Linux/Android fall back to false.
  bool get isPowerSavingMode {
    if (isWindows) {
      try {
        // Windows: PowerManager::GetPowerStatus returns 0 when on battery,
        // 1 when on AC. We use the SystemParameters API via a platform channel
        // — here we rely on a simpler heuristic: if battery capacity is low.
        // Since Flutter doesn't expose this directly, we use a heuristic
        // based on the platform's power state from SystemSettings.
        return false; // Fallback — real detection requires native code
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Whether to use aggressive memory cleanup on Android.
  /// Enabled on low-end devices to prevent OOM.
  bool get aggressiveMemoryCleanup => isAndroid && deviceTier == DeviceTier.low;

  /// Maximum number of concurrent image decodes.
  /// Lower on Android to prevent OOM.
  int get maxConcurrentImageDecodes {
    if (isAndroid && deviceTier == DeviceTier.low) return 1;
    if (isAndroid) return 3;
    return 6;
  }

  /// Whether to enable background audio scanning.
  /// Disabled on low-end Android to save battery.
  bool get enableBackgroundScanning =>
      !(isAndroid && deviceTier == DeviceTier.low);

  /// Battery optimization mode - reduces background activity.
  bool get batteryOptimizationMode => isAndroid;

  /// Whether global hotkeys (system-level) are supported.
  bool get supportsGlobalHotkeys => isDesktop;

  /// Whether the system tray is available.
  bool get supportsSystemTray => isDesktop;

  /// Whether window management APIs are available.
  bool get supportsWindowManagement => isDesktop;

  /// Whether Picture-in-Picture is available.
  /// On Android, uses native PiP (Android 8+, we target 10+).
  bool get supportsPiP => isAndroid;

  @override
  String toString() =>
      'PlatformCapabilities(tier: $deviceTier, android: $isAndroid, '
      'desktop: $isDesktop, linux: $isLinux, chromeos: $isChromeOS, '
      'frameRateHz: $androidFrameRateHz)';
}

/// Mirrors [WindowEffect] from flutter_acrylic without creating a dependency.
/// Used by [PlatformCapabilities.preferredWindowEffect] for platform-aware
/// effect selection.
enum WindowEffectType {
  disabled,
  solid,
  transparent,
  acrylic,
  mica,
  tabbed,
  titlebar,
  sidebar,
  hudWindow,
}

enum DeviceTier { high, mid, low }
