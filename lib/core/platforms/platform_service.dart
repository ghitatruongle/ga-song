import 'dart:io';
import 'package:flutter/foundation.dart';

import 'macos/macos_integration.dart';
import 'ios/ios_integration.dart';
import 'web/web_integration.dart';

/// Unified platform service for G.A Song.
///
/// Coordinates platform-specific features across macOS, iOS, and Web.
class PlatformService {
  static final PlatformService _instance = PlatformService._();
  static PlatformService get instance => _instance;

  PlatformService._();

  /// Current platform type.
  late PlatformType _platformType;

  /// Gets the current platform type.
  PlatformType get platformType => _platformType;

  /// Initializes platform-specific features.
  Future<void> initialize() async {
    _platformType = _detectPlatform();

    switch (_platformType) {
      case PlatformType.macos:
        await MacOSIntegration.setup();
        break;
      case PlatformType.ios:
        await IOSIntegration.setup();
        break;
      case PlatformType.web:
        await WebIntegration.setup();
        break;
      default:
        // No platform-specific setup needed
        break;
    }
  }

  PlatformType _detectPlatform() {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.unknown;
  }

  /// Updates Now Playing info for supported platforms.
  Future<void> updateNowPlaying({
    required final String title,
    required final String artist,
    final String? album,
    required final Duration position,
    required final Duration duration,
    required final bool isPlaying,
  }) async {
    switch (_platformType) {
      case PlatformType.macos:
        await MacOSIntegration.setNowPlaying(
          title: title,
          artist: artist,
          album: album,
          position: position,
          duration: duration,
          isPlaying: isPlaying,
        );
        break;
      case PlatformType.ios:
        // iOS Now Playing is handled by audio_service
        break;
      default:
        // Not supported on this platform
        break;
    }
  }

  /// Clears Now Playing info.
  Future<void> clearNowPlaying() async {
    switch (_platformType) {
      case PlatformType.macos:
        await MacOSIntegration.clearNowPlaying();
        break;
      default:
        break;
    }
  }

  /// Shows a platform notification.
  Future<void> showNotification({
    required final String title,
    required final String body,
    final String? subtitle,
  }) async {
    switch (_platformType) {
      case PlatformType.macos:
        await MacOSIntegration.showNotification(
          title: title,
          body: body,
          subtitle: subtitle,
        );
        break;
      case PlatformType.web:
        await WebIntegration.showNotification(title: title, body: body);
        break;
      default:
        // Not supported on this platform
        break;
    }
  }

  /// Updates widget data for supported platforms.
  Future<void> updateWidget({
    required final String songName,
    required final String artist,
    required final bool isPlaying,
    final String? coverArtBase64,
  }) async {
    switch (_platformType) {
      case PlatformType.ios:
        await IOSIntegration.updateWidget(
          songName: songName,
          artist: artist,
          isPlaying: isPlaying,
          coverArtBase64: coverArtBase64,
        );
        break;
      default:
        // Not supported on this platform
        break;
    }
  }

  /// Disposes platform resources.
  void dispose() {
    switch (_platformType) {
      case PlatformType.macos:
        MacOSIntegration.dispose();
        break;
      case PlatformType.ios:
        IOSIntegration.dispose();
        break;
      case PlatformType.web:
        WebIntegration.dispose();
        break;
      default:
        break;
    }
  }
}

/// Types of platforms supported by the app.
enum PlatformType {
  /// Android platform.
  android,

  /// iOS platform.
  ios,

  /// macOS platform.
  macos,

  /// Windows platform.
  windows,

  /// Linux platform.
  linux,

  /// Web platform.
  web,

  /// Unknown platform.
  unknown,
}
