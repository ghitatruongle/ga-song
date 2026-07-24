import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'logging/app_logger.dart';

/// Service that manages Picture-in-Picture mode on Android.
///
/// Uses a [MethodChannel] to communicate with native Android code.
/// On non-Android platforms, all methods are no-ops.
class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const _pipChannel = MethodChannel('com.gasong.ga_song/pip');
  static const _deepLinkChannel = MethodChannel(
    'com.gasong.ga_song/deep_link',
  );

  /// Whether the app is currently in PiP mode.
  final ValueNotifier<bool> isInPipNotifier = ValueNotifier(false);

  /// Stream of song IDs received via deep link (ga-song://play?id=xxx).
  final StreamController<int> _deepLinkController =
      StreamController<int>.broadcast();
  Stream<int> get deepLinkStream => _deepLinkController.stream;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Call once during app init to start listening for native PiP callbacks
  /// and deep link events.
  void init() {
    if (!_isAndroid) return;

    // Set up PiP callback handler
    _pipChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPiPChanged') {
        final args = call.arguments as Map;
        final isInPiP = args['isInPiP'] as bool;
        isInPipNotifier.value = isInPiP;
      }
    });

    // Set up deep link callback handler
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'playSong') {
        final songId = call.arguments as int;
        _deepLinkController.add(songId);
      }
    });
  }

  /// Returns true if PiP is supported on this device (Android 8.0+).
  Future<bool> isPipSupported() async {
    if (!_isAndroid) return false;
    try {
      final result = await _pipChannel.invokeMethod<bool>('isPiPSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests the system to enter Picture-in-Picture mode.
  Future<bool> enterPip() async {
    if (!_isAndroid) return false;
    try {
      final result = await _pipChannel.invokeMethod<bool>('enterPiP');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.w('pip.service', 'PiP error', error: e);
      return false;
    }
  }

  void dispose() {
    isInPipNotifier.dispose();
    _deepLinkController.close();
    _pipChannel.setMethodCallHandler(null);
    _deepLinkChannel.setMethodCallHandler(null);
  }
}
