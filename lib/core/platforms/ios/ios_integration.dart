import 'dart:io';
import 'package:flutter/services.dart';

/// iOS-specific integration for G.A Song
/// Provides native iOS features like widgets, Siri shortcuts,
/// and system integration.
class IOSIntegration {
  static const MethodChannel _channel = MethodChannel('gasong/ios');

  /// Whether the current platform is iOS.
  static bool get isIOS => Platform.isIOS;

  /// Cached Low Power Mode state. Read by `PlatformCapabilities.isPowerSavingMode`.
  static bool _lowPowerMode = false;
  static bool get isLowPowerMode => _lowPowerMode;

  /// Called when iOS Low Power Mode toggles.
  static void Function(bool enabled)? onLowPowerModeChanged;

  /// Called when the OS delivers a memory warning.
  static void Function()? onMemoryWarning;

  /// Initializes iOS-specific features.
  static Future<void> setup() async {
    if (!isIOS) return;

    _channel.setMethodCallHandler(_handleMethodCall);
    // Seed the low-power cache — the native push at launch can race the
    // Flutter handler registration.
    _lowPowerMode = await _queryLowPowerMode();
  }

  static Future<dynamic> _handleMethodCall(final MethodCall call) async {
    switch (call.method) {
      case 'onWidgetTapped':
        // Handle widget tap
        break;
      case 'onSiriShortcutInvoked':
        // Handle Siri shortcut
        break;
      case 'onLowPowerModeChanged':
        final enabled = call.arguments as bool? ?? false;
        _lowPowerMode = enabled;
        onLowPowerModeChanged?.call(enabled);
        break;
      case 'onMemoryWarning':
        onMemoryWarning?.call();
        break;
    }
  }

  /// Pull-based Low Power Mode query (seeds the cache at startup).
  static Future<bool> _queryLowPowerMode() async {
    if (!isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isLowPowerMode') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Updates the iOS home screen widget data.
  static Future<void> updateWidget({
    required final String songName,
    required final String artist,
    required final bool isPlaying,
    final String? coverArtBase64,
  }) async {
    if (!isIOS) return;

    try {
      await _channel.invokeMethod('updateWidget', {
        'songName': songName,
        'artist': artist,
        'isPlaying': isPlaying,
        'coverArt': coverArtBase64,
      });
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Registers a Siri shortcut for quick actions.
  static Future<void> registerSiriShortcut({
    required final String identifier,
    required final String phrase,
    required final String title,
    final String? subtitle,
  }) async {
    if (!isIOS) return;

    try {
      await _channel.invokeMethod('registerSiriShortcut', {
        'identifier': identifier,
        'phrase': phrase,
        'title': title,
        'subtitle': subtitle ?? '',
      });
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Donates a Siri shortcut invocation.
  static Future<void> donateSiriShortcut({
    required final String identifier,
    final Map<String, dynamic>? parameters,
  }) async {
    if (!isIOS) return;

    try {
      await _channel.invokeMethod('donateSiriShortcut', {
        'identifier': identifier,
        'parameters': parameters ?? {},
      });
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Enables AirPlay routing.
  static Future<void> enableAirPlay() async {
    if (!isIOS) return;

    try {
      await _channel.invokeMethod('enableAirPlay');
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Disables AirPlay routing.
  static Future<void> disableAirPlay() async {
    if (!isIOS) return;

    try {
      await _channel.invokeMethod('disableAirPlay');
    } catch (e) {
      // Ignore if not supported
    }
  }

  /// Checks if AirPlay is available.
  static Future<bool> isAirPlayAvailable() async {
    if (!isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isAirPlayAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Shows a local notification on iOS.
  static Future<void> showNotification({
    required final String title,
    required final String body,
    final String? subtitle,
  }) async {
    if (!isIOS) return;

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

  /// Disposes iOS resources.
  static void dispose() {
    // Cleanup if needed
  }
}
