import 'dart:io';
import 'package:flutter/services.dart';

/// iOS-specific integration for G.A Song.
///
/// Provides native iOS features like widgets, Siri shortcuts,
/// and system integration.
class IOSIntegration {
  static const MethodChannel _channel = MethodChannel('gasong/ios');

  /// Whether the current platform is iOS.
  static bool get isIOS => Platform.isIOS;

  /// Initializes iOS-specific features.
  static Future<void> setup() async {
    if (!isIOS) return;

    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWidgetTapped':
        // Handle widget tap
        break;
      case 'onSiriShortcutInvoked':
        // Handle Siri shortcut
        break;
    }
  }

  /// Updates the iOS home screen widget data.
  static Future<void> updateWidget({
    required String songName,
    required String artist,
    required bool isPlaying,
    String? coverArtBase64,
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
    required String identifier,
    required String phrase,
    required String title,
    String? subtitle,
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
    required String identifier,
    Map<String, dynamic>? parameters,
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

  /// Disposes iOS resources.
  static void dispose() {
    // Cleanup if needed
  }
}
