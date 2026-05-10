import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';

class GaSongAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioEngineService _engineService;
  final PlaylistService _playlistService;

  /// Throttle: track last broadcast state to avoid redundant updates.
  AudioEngineState? _lastBroadcastedState;

  GaSongAudioHandler(this._engineService, this._playlistService) {
    _initListeners();
  }

  void _initListeners() {
    // Only broadcast on engine state changes (play/pause/stop/loading),
    // NOT on every position tick. Position is tracked via updatePosition.
    _engineService.engineState.addListener(_onEngineStateChanged);
    _playlistService.currentIndexNotifier.addListener(_onSongChanged);
    // Update MediaItem duration once the engine reports the actual duration
    _engineService.durationNotifier.addListener(_onDurationChanged);
  }

  void _onEngineStateChanged() {
    final state = _engineService.engineState.value;
    // Only broadcast if state actually changed (avoids redundant notifications)
    if (state == _lastBroadcastedState) return;
    _lastBroadcastedState = state;
    _broadcastState();
  }

  void _broadcastState() {
    final state = _engineService.engineState.value;
    final position = _engineService.positionNotifier.value;
    
    try {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (state == AudioEngineState.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _getProcessingState(state),
        playing: state == AudioEngineState.playing,
        updatePosition: position,
        bufferedPosition: position,
        speed: 1.0,
      ));
    } catch (e) {
      debugPrint('audio_service broadcastState error: $e');
    }
  }

  AudioProcessingState _getProcessingState(AudioEngineState state) {
    switch (state) {
      case AudioEngineState.idle:
      case AudioEngineState.stopped:
        return AudioProcessingState.idle;
      case AudioEngineState.loading:
        return AudioProcessingState.loading;
      case AudioEngineState.playing:
      case AudioEngineState.paused:
        return AudioProcessingState.ready;
      case AudioEngineState.error:
        return AudioProcessingState.error;
    }
  }

  void _onSongChanged() {
    _updateMediaItem();
  }

  void _onDurationChanged() {
    // Re-emit MediaItem with correct duration once the engine reports it
    final current = mediaItem.value;
    if (current == null) return;
    final duration = _engineService.durationNotifier.value;
    if (duration == Duration.zero) return;
    if (current.duration == duration) return;
    
    try {
      mediaItem.add(current.copyWith(duration: duration));
    } catch (e) {
      debugPrint('audio_service duration update error: $e');
    }
  }

  Future<void> _updateMediaItem() async {
    final song = _playlistService.currentSong;
    if (song == null) {
      try {
        mediaItem.add(null);
      } catch (e) {
        debugPrint('audio_service clear mediaItem error: $e');
      }
      return;
    }

    Uri? artUri;
    try {
      final fileName = song.fileName.replaceAll('.mp3', '.png');
      final assetPath = 'assets/pic/$fileName';
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      
      if (!tempFile.existsSync()) {
        final data = await rootBundle.load(assetPath);
        await tempFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
      artUri = Uri.file(tempFile.path);
    } catch (e) {
      debugPrint('Failed to extract audio_service thumbnail: $e');
    }
    
    try {
      mediaItem.add(MediaItem(
        id: song.fileName,
        album: song.album ?? '',
        title: song.name,
        artist: song.artist ?? 'Unknown Artist',
        duration: _engineService.durationNotifier.value,
        artUri: artUri,
      ));
    } catch (e) {
      debugPrint('audio_service mediaItem update error: $e');
    }
  }

  @override
  Future<void> play() async {
    final state = _engineService.engineState.value;
    if (state == AudioEngineState.paused) {
      await _engineService.resume();
    } else if (_playlistService.currentSong != null) {
      await _engineService.resume();
    } else {
      _playlistService.play();
    }
  }

  @override
  Future<void> pause() async => _engineService.pause();

  @override
  Future<void> stop() async => _engineService.stop();

  @override
  Future<void> seek(Duration position) async => _engineService.seek(position);

  @override
  Future<void> skipToNext() async => _playlistService.next();

  @override
  Future<void> skipToPrevious() async => _playlistService.previous();

  @override
  Future<void> onTaskRemoved() async {
    // When the user swipes away the app from recent tasks
    if (!playbackState.value.playing) {
      await stop();
    }
  }
}
