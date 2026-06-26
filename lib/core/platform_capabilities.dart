import 'dart:io';
import 'package:flutter/foundation.dart';

/// Detects platform capabilities and hardware tier to tune performance settings.
///
/// Provides a single source of truth for platform-specific decisions across
/// the app — visualizer frame budget, cache sizes, blur quality, timer intervals.
class PlatformCapabilities {
  PlatformCapabilities._();
  static final PlatformCapabilities instance = PlatformCapabilities._();

  // ─── Platform shortcuts ───────────────────────────────────────────────────

  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isDesktop => isWindows || isLinux || isMacOS;
  bool get isMobile => isAndroid;

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
      final parts = version.split(RegExp(r'[ .]+'));
      for (final part in parts) {
        final num = int.tryParse(part);
        if (num != null && num > 10000) return num >= 22000;
      }
      return false;
    } catch (e) {
      debugPrint('PlatformCapabilities version error: $e');
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
    } catch (e, stack) { debugPrint('Error in platform_capabilities: $e\n$stack'); 
      return false;
    }
  }

  /// Returns true if running inside a Chrome OS / Chrome OS Flex environment.
  bool get isChromeOS {
    if (!isLinux) return false;
    try {
      return File('/etc/os-release').readAsStringSync().contains('Chrome OS') ||
          File('/run/chromeos-config').existsSync();
    } catch (e, stack) { debugPrint('Error in platform_capabilities: $e\n$stack'); 
      return false;
    }
  }

  // ─── Hardware tier ────────────────────────────────────────────────────────

  /// Estimated device tier based on platform.
  /// - [DeviceTier.high]: Desktop (Windows, Linux, macOS)
  /// - [DeviceTier.mid]: Android 10+ on recent hardware
  /// - [DeviceTier.low]: (reserved — add RAM-based detection if needed)
  DeviceTier get deviceTier {
    if (isDesktop) return DeviceTier.high;
    if (isAndroid) {
      if (Platform.numberOfProcessors <= 4) {
        return DeviceTier.low;
      }
      return DeviceTier.mid;
    }
    return DeviceTier.mid; // Default fallback
  }

  // ─── Performance tuning knobs ─────────────────────────────────────────────

  /// Position update interval for the audio progress bar.
  /// 250ms on desktop for smooth scrubbing; 500ms on Android to reduce wake-ups.
  Duration get positionTimerInterval {
    if (isAndroid) return const Duration(milliseconds: 500);
    return const Duration(milliseconds: 250);
  }

  /// Max number of audio source buffers to keep in memory.
  /// Android: 20 (tighter RAM budget); Desktop: 50.
  int get maxAudioSourceCacheEntries {
    if (isAndroid) return 20;
    return 50;
  }

  /// Max number of cover art image providers to keep in the LRU cache.
  int get maxCoverArtCacheEntries {
    if (isAndroid) return 24;
    return 60;
  }

  /// Whether to allow high-quality blur effects.
  /// Desktop always allows; Android allows but may reduce sigma.
  bool get allowHighQualityBlur => isDesktop;

  /// Suggested blur sigma for blurred backgrounds.
  double get backgroundBlurSigma {
    if (isAndroid) return 20.0; // Lighter blur on mobile
    return 30.0;
  }

  /// Max particle count for the visualizer.
  /// Android: 80 (reduce CPU + RAM); Desktop: 150.
  int get maxParticleCount {
    if (isAndroid) return 80;
    return 150;
  }

  /// Max star count for the starfield visualizer.
  /// Android: 100; Desktop: 200.
  int get maxStarCount {
    if (isAndroid) return 100;
    return 200;
  }

  /// How many audio sources to preload concurrently.
  /// Android: 1 (sequential, prevents OOM); Desktop: 3 (fast SSD).
  int get preloadConcurrency {
    if (isAndroid) return 1;
    return 3;
  }

  /// Whether the visualizer should run in adaptive frame-rate mode.
  /// Always true — but threshold differs per tier.
  bool get visualizerAdaptiveFps => true;

  /// Frame time budget in milliseconds before the visualizer drops to half-rate.
  int get visualizerFrameBudgetMs {
    switch (deviceTier) {
      case DeviceTier.high:
        return 14; // ~71fps budget — drops to 30fps if over
      case DeviceTier.mid:
        return 20; // ~50fps budget — drops to 30fps if over
      case DeviceTier.low:
        return 33; // ~30fps budget
    }
  }

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
      'desktop: $isDesktop, linux: $isLinux, chromeos: $isChromeOS)';
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
