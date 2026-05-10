import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smtc_windows/smtc_windows.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';

class SmtcService {
  final AudioEngineService _engineService;
  final PlaylistService _playlistService;
  
  SMTCWindows? _smtc;

  /// Throttle position updates to avoid excessive FFI calls.
  /// Windows SMTC doesn't need 250ms precision — 1s is sufficient.
  Duration _lastReportedPosition = Duration.zero;

  SmtcService(this._engineService, this._playlistService);

  Future<void> init() async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      _smtc = SMTCWindows(
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

      // Listen to SMTC buttons
      _smtc!.buttonPressStream.listen((event) {
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
      _playlistService.currentIndexNotifier.addListener(_onPlaylistIndexChanged);
      
      // Update timeline
      _engineService.positionNotifier.addListener(_onPositionChanged);
      _engineService.durationNotifier.addListener(_onDurationChanged);

    } catch (e) {
      debugPrint('Failed to initialize SMTC: $e');
    }
  }

  void _onEngineStateChanged() {
    if (_smtc == null) return;
    try {
      final state = _engineService.engineState.value;
      switch (state) {
        case AudioEngineState.playing:
          _smtc!.setPlaybackStatus(PlaybackStatus.Playing);
          break;
        case AudioEngineState.paused:
          _smtc!.setPlaybackStatus(PlaybackStatus.Paused);
          break;
        case AudioEngineState.stopped:
        case AudioEngineState.error:
          _smtc!.setPlaybackStatus(PlaybackStatus.Stopped);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('SMTC state update error: $e');
    }
  }

  void _onPlaylistIndexChanged() async {
    if (_smtc == null) return;
    final song = _playlistService.currentSong;
    if (song != null) {
      String? thumbnailPath;
      
      // Try to extract cover art to a temp file for SMTC
      try {
        final fileName = song.fileName.replaceAll('.mp3', '.png');
        final assetPath = 'assets/pic/$fileName';
        final tempFile = File('${Directory.systemTemp.path}\\$fileName');
        
        if (!tempFile.existsSync()) {
          final data = await rootBundle.load(assetPath);
          await tempFile.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }
        thumbnailPath = tempFile.path;
      } catch (e) {
        debugPrint('Failed to extract SMTC thumbnail: $e');
      }

      try {
        _smtc!.updateMetadata(MusicMetadata(
          title: song.name,
          artist: song.artist ?? 'Unknown Artist',
          thumbnail: thumbnailPath,
        ));
        _lastReportedPosition = Duration.zero;
        _onDurationChanged();
      } catch (e) {
        debugPrint('SMTC metadata update error: $e');
      }
    } else {
      try {
        _smtc!.clearMetadata();
      } catch (e) {
        debugPrint('SMTC clearMetadata error: $e');
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
      debugPrint('SMTC position update error: $e');
    }
  }
  
  void _onDurationChanged() {
    if (_smtc == null) return;
    try {
      final duration = _engineService.durationNotifier.value;
      _smtc!.setEndTime(duration);
    } catch (e) {
      debugPrint('SMTC duration update error: $e');
    }
  }

  void dispose() {
    _engineService.engineState.removeListener(_onEngineStateChanged);
    _playlistService.currentIndexNotifier.removeListener(_onPlaylistIndexChanged);
    _engineService.positionNotifier.removeListener(_onPositionChanged);
    _engineService.durationNotifier.removeListener(_onDurationChanged);
    _smtc?.dispose();
  }
}
