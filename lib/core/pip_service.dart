import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service that manages Picture-in-Picture mode on Android.
///
/// Uses a [MethodChannel] to communicate with native Android code.
/// On non-Android platforms, all methods are no-ops.
class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const _channel = MethodChannel('com.gasong.ga_song/pip');

  /// Whether the app is currently in PiP mode.
  final ValueNotifier<bool> isInPipNotifier = ValueNotifier(false);

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Call once during app init to start listening for native PiP callbacks.
  void init() {
    if (!_isAndroid) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPiPChanged') {
        final args = call.arguments as Map;
        final isInPiP = args['isInPiP'] as bool;
        isInPipNotifier.value = isInPiP;
      }
    });
  }

  /// Returns true if PiP is supported on this device (Android 8.0+).
  Future<bool> isPipSupported() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isPiPSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests the system to enter Picture-in-Picture mode.
  Future<bool> enterPip() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('enterPiP');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PiP error: $e');
      return false;
    }
  }

  void dispose() {
    isInPipNotifier.dispose();
  }
}
