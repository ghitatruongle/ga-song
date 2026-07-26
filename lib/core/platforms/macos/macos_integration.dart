import 'dart:io';
import 'package:flutter/services.dart';

/// macOS-specific integration for G.A Song.
///
/// Provides native macOS features like menu bar, Touch Bar,
/// and system integration.
class MacOSIntegration {
  static const MethodChannel _channel = MethodChannel('gasong/macos');

  /// Whether the current platform is macOS.
  static bool get isMacOS => Platform.isMacOS;

  /// Initializes macOS-specific features.
  static Future<void> setup() async {
    if (!isMacOS) return;

    _channel.setMethodCallHandler(_handleMethodCall);
    await _configureWindow();
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWindowFocusChanged':
        // Handle window focus changes
        break;
      case 'onSystemThemeChanged':
        // Handle system theme changes
        break;
      case 'onPowerStateChanged':
        // Handle power state changes (sleep/wake)
        break;
    }
  }

  static Future<void> _configureWindow() async {
    try {
      await _channel.invokeMethod('configureWindow', {
        'titleBarStyle': 'hidden',
        'fullSizeContentView': true,
        'transparent': true,
      });
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Updates the macOS Now Playing info.
  static Future<void> setNowPlaying({
    required String title,
    required String artist,
    required String? album,
    required Duration position,
    required Duration duration,
    required bool isPlaying,
  }) async {
    if (!isMacOS) return;

    try {
      await _channel.invokeMethod('setNowPlaying', {
        'title': title,
        'artist': artist,
        'album': album ?? '',
        'position': position.inMilliseconds,
        'duration': duration.inMilliseconds,
        'isPlaying': isPlaying,
      });
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Clears the macOS Now Playing info.
  static Future<void> clearNowPlaying() async {
    if (!isMacOS) return;

    try {
      await _channel.invokeMethod('clearNowPlaying');
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Sets the dock badge count.
  static Future<void> setDockBadge(int? count) async {
    if (!isMacOS) return;

    try {
      await _channel.invokeMethod('setDockBadge', {'count': count});
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Shows a macOS notification.
  static Future<void> showNotification({
    required String title,
    required String body,
    String? subtitle,
  }) async {
    if (!isMacOS) return;

    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'subtitle': subtitle ?? '',
      });
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Disposes macOS resources.
  static void dispose() {
    // Cleanup if needed
  }
}
