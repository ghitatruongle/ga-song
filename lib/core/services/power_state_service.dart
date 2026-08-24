import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Reads power state (battery saver, charging, level) through the
/// `com.gasong.ga_song/power` MethodChannel
/// - Android: reads PowerManager.isPowerSaveMode in `MainActivity`.
/// - Windows: reads GetSystemPowerStatus + SPI_GETBATTERYSAVERSTATE in `flutter_window.cpp`.
class PowerStateService with WidgetsBindingObserver {
  PowerStateService._();
  static final PowerStateService instance = PowerStateService._();

  static const MethodChannel _channel = MethodChannel(
    'com.gasong.ga_song/power',
  );

  bool _isPowerSaving = false;
  bool _isCharging = true;
  int _batteryLevel = 100;

  Timer? _refreshTimer;

  /// Whether battery saver is currently active (Android Power Saver /
  /// Windows Battery Saver).
  bool get isPowerSaving => _isPowerSaving;

  /// Whether the device is plugged in (charging or full).
  bool get isCharging => _isCharging;

  /// Battery level in percent (0–100).
  int get batteryLevel => _batteryLevel;

  /// Platforms with a power-state channel implementation.
  static bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  /// Starts periodic refresh + refreshes when the app returns to foreground.
  void start() {
    if (!_isSupported) return;
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _refreshTimer ??= Timer.periodic(
      const Duration(minutes: 2),
      (_) => _refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  /// Force a re-read of the power state.
  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'powerState',
      );
      if (result == null) return;
      _isPowerSaving = result['isPowerSaving'] as bool? ?? _isPowerSaving;
      _isCharging = result['isCharging'] as bool? ?? _isCharging;
      _batteryLevel = result['level'] as int? ?? _batteryLevel;
    } catch (e, stack) {
      AppLogger.w(
        'power.state',
        'power state read failed',
        error: e,
        stack: stack,
      );
    }
  }

  /// Idempotent teardown (tests / app exit).
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
