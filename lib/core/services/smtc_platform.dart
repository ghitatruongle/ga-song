import 'dart:async';
import 'package:smtc_windows/smtc_windows.dart';

/// Abstract interface for SMTC (System Media Transport Controls) operations.
/// Allows mocking in tests without requiring native Windows APIs.
abstract class SmtcPlatform {
  Stream<PressedButton> get buttonPressStream;

  Future<void> setPlaybackStatus(PlaybackStatus status);
  Future<void> updateMetadata(MusicMetadata metadata);
  Future<void> clearMetadata();
  Future<void> setPosition(Duration position);
  Future<void> setEndTime(Duration endTime);
  Future<void> dispose();
}

/// Real implementation that wraps [SMTCWindows] from smtc_windows package.
class WindowsSmtcPlatform implements SmtcPlatform {
  final SMTCWindows _smtc;

  WindowsSmtcPlatform(this._smtc);

  static Future<WindowsSmtcPlatform> create({
    required SMTCConfig config,
  }) async {
    await SMTCWindows.initialize();
    final smtc = SMTCWindows(config: config);
    return WindowsSmtcPlatform(smtc);
  }

  @override
  Stream<PressedButton> get buttonPressStream => _smtc.buttonPressStream;

  @override
  Future<void> setPlaybackStatus(PlaybackStatus status) =>
      _smtc.setPlaybackStatus(status);

  @override
  Future<void> updateMetadata(MusicMetadata metadata) =>
      _smtc.updateMetadata(metadata);

  @override
  Future<void> clearMetadata() => _smtc.clearMetadata();

  @override
  Future<void> setPosition(Duration position) => _smtc.setPosition(position);

  @override
  Future<void> setEndTime(Duration endTime) => _smtc.setEndTime(endTime);

  @override
  Future<void> dispose() => _smtc.dispose();
}
