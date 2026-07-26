import '../logging/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smtc_windows/smtc_windows.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import 'smtc_platform.dart';
import '../cover_art_repository.dart';

class SmtcService {
  final AudioEngineService _engineService;
  final PlaylistService _playlistService;

  SmtcPlatform? _smtc;
  StreamSubscription<PressedButton>? _buttonSubscription;

  /// Throttle position updates to avoid excessive FFI calls.
  /// Windows SMTC doesn't need 250ms precision — 1s is sufficient.
  Duration _lastReportedPosition = Duration.zero;

  /// Track last thumbnail path to cleanup when song changes
  String? _lastThumbnailPath;

  SmtcService(this._engineService, this._playlistService);

  /// Optionally inject an [SmtcPlatform] instance for testing.
  Future<void> init({SmtcPlatform? smtc}) async {
    if (kIsWeb || !Platform.isWindows) return;
    if (_smtc != null) return; // Idempotency check

    try {
      smtc ??= await WindowsSmtcPlatform.create(
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      );
      _smtc = smtc;

      // Listen to SMTC buttons
      _buttonSubscription = _smtc!.buttonPressStream.listen((event) {
        switch (event) {
          case PressedButton.play:
            _playlistService.play();
            break;
          case PressedButton.pause:
            _engineService.pause();
            break;
          case PressedButton.next:
            _playlistService.next();
            break;
          case PressedButton.previous:
            _playlistService.previous();
            break;
          case PressedButton.stop:
            _engineService.stop();
            break;
          default:
            break;
        }
      });

      // Listen to engine state to update SMTC status
      _engineService.engineState.addListener(_onEngineStateChanged);

      // Listen to playlist changes to update metadata
      _playlistService.currentIndexNotifier.addListener(
        _onPlaylistIndexChanged,
      );

      // Update timeline
      _engineService.positionNotifier.addListener(_onPositionChanged);
      _engineService.durationNotifier.addListener(_onDurationChanged);
    } catch (e) {
      AppLogger.e('smtc.service', 'SMTC init failed', error: e);
    }
  }

  void _onEngineStateChanged() {
    if (_smtc == null) return;
    try {
      final state = _engineService.engineState.value;
      switch (state) {
        case AudioEngineState.playing:
          _smtc!.setPlaybackStatus(PlaybackStatus.playing);
          break;
        case AudioEngineState.paused:
          _smtc!.setPlaybackStatus(PlaybackStatus.paused);
          break;
        case AudioEngineState.stopped:
        case AudioEngineState.error:
          _smtc!.setPlaybackStatus(PlaybackStatus.stopped);
          break;
        default:
          break;
      }
    } catch (e) {
      AppLogger.w('smtc.service', 'SMTC state update failed', error: e);
    }
  }

  void _onPlaylistIndexChanged() {
    if (_smtc == null) return;
    _updatePlaylistMetadata();
  }

  Future<void> _updatePlaylistMetadata() async {
    final song = _playlistService.currentSong;
    if (song != null) {
      String? thumbnailPath;

      // Try to extract cover art to a temp file for SMTC
      try {
        // Get the correct cover art path from sourcePath
        final String? resolvedPath;
        if (song.isBuiltIn) {
          resolvedPath = await CoverArtRepository.findCoverAssetPath(song);
        } else {
          resolvedPath = CoverArtRepository.findLocalCoverPath(song);
        }

        final fileName = song.fileName.replaceAll(
          RegExp(r'\.(mp3|flac|wav|m4a)$'),
          '.png',
        );
        final tempFile = File('${Directory.systemTemp.path}\\$fileName');

        // Cleanup old thumbnail khi chuyển bài
        if (_lastThumbnailPath != null) {
          try {
            final oldFile = File(_lastThumbnailPath!);
            if (oldFile.existsSync()) {
              // Try to delete, but don't block if file is in use
              oldFile.deleteSync();
            }
          } catch (e) {
            // File might be in use by Windows, ignore and continue
            AppLogger.w('smtc.service', 'delete thumbnail failed', error: e);
          }
          _lastThumbnailPath = null;
        }

        if (resolvedPath != null && !tempFile.existsSync()) {
          if (song.isBuiltIn) {
            final data = await rootBundle.load(resolvedPath);
            await tempFile.writeAsBytes(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              flush: true,
            );
          } else {
            // For local files, check if image exists and copy it
            final imageFile = File(resolvedPath);
            if (await imageFile.exists()) {
              await imageFile.copy(tempFile.path);
            } else {
              // No thumbnail
              thumbnailPath = null;
            }
          }
        }
        if (tempFile.existsSync()) {
          thumbnailPath = tempFile.path;
          _lastThumbnailPath = thumbnailPath;
        }
      } catch (e) {
        // Thumbnail is optional - continue without it
        AppLogger.d('smtc.service', 'thumbnail not available', error: e);
      }

      try {
        _smtc!.updateMetadata(
          MusicMetadata(
            title: song.name,
            artist: song.artist ?? 'Unknown Artist',
            thumbnail: thumbnailPath,
          ),
        );
        _lastReportedPosition = Duration.zero;
        _onDurationChanged();
      } catch (e) {
        AppLogger.w('smtc.service', 'metadata update failed', error: e);
      }
    } else {
      try {
        _smtc!.clearMetadata();
      } catch (e) {
        AppLogger.w('smtc.service', 'clearMetadata failed', error: e);
      }
    }
  }

  void _onPositionChanged() {
    if (_smtc == null) return;
    final pos = _engineService.positionNotifier.value;
    // Throttle: only update SMTC when position changes by ≥1 second
    final diff = (pos - _lastReportedPosition).abs();
    if (diff.inMilliseconds < 900) return;
    _lastReportedPosition = pos;
    try {
      _smtc!.setPosition(pos);
    } catch (e) {
      AppLogger.w('smtc.service', 'position update failed', error: e);
    }
  }

  void _onDurationChanged() {
    if (_smtc == null) return;
    try {
      final duration = _engineService.durationNotifier.value;
      _smtc!.setEndTime(duration);
    } catch (e) {
      AppLogger.w('smtc.service', 'duration update failed', error: e);
    }
  }

  void dispose() {
    // Only remove listeners if SMTC was successfully initialized
    // (init() adds these listeners only after _smtc is set)
    if (_smtc != null) {
      try {
        _buttonSubscription?.cancel();
      } catch (e) {
        AppLogger.w('smtc.service', 'dispose failed', error: e);
      }
      try {
        _engineService.engineState.removeListener(_onEngineStateChanged);
        _playlistService.currentIndexNotifier.removeListener(
          _onPlaylistIndexChanged,
        );
        _engineService.positionNotifier.removeListener(_onPositionChanged);
        _engineService.durationNotifier.removeListener(_onDurationChanged);
      } catch (e, stack) {
        AppLogger.e('smtc.service', 'operation failed', error: e, stack: stack);
      }
      try {
        _smtc?.dispose();
      } catch (e) {
        AppLogger.w('smtc.service', 'dispose failed', error: e);
      }
    }
  }
}
