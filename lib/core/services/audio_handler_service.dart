import 'dart:io';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:image/image.dart' as img;
import '../logging/app_logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../cover_art_repository.dart';
import '../platforms/platform_service.dart';

/// Max edge length for the notification artwork written to the temp file.
/// Downscaling avoids decoding full-resolution covers on every track change.
const int _kNotificationArtMaxEdge = 512;

class GaSongAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
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
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (state == AudioEngineState.playing)
              MediaControl.pause
            else
              MediaControl.play,
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
          speed: 1,
        ),
      );
    } catch (e) {
      AppLogger.w('audio_handler.service', 'broadcastState failed', error: e);
    }
  }

  AudioProcessingState _getProcessingState(final AudioEngineState state) {
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
      AppLogger.w('audio_handler.service', 'duration update failed', error: e);
    }
  }

  Future<void> _updateMediaItem() async {
    final song = _playlistService.currentSong;
    if (song == null) {
      try {
        mediaItem.add(null);
      } catch (e) {
        AppLogger.w(
          'audio_handler.service',
          'clear mediaItem failed',
          error: e,
        );
      }
      return;
    }
    // Generation guard: if the user switches songs while the cover-art IO
    // below is in flight, the STALE song must not overwrite the current one.
    final String songAtStart = song.fileName;
    bool isCurrent() => _playlistService.currentSong?.fileName == songAtStart;

    Uri? artUri;
    try {
      final String? resolvedPath;
      if (song.isBuiltIn) {
        resolvedPath = await CoverArtRepository.findCoverAssetPath(song);
      } else {
        resolvedPath = await CoverArtRepository.findLocalCoverPath(song);
      }

      final fileName = song.fileName.replaceAll(
        RegExp(r'\.(mp3|flac|wav|m4a)$'),
        '.png',
      );
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');

      if (resolvedPath != null &&
          (!tempFile.existsSync() || tempFile.lengthSync() == 0)) {
        if (song.isBuiltIn) {
          final data = await rootBundle.load(resolvedPath);
          await _writeScaledNotificationArt(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            tempFile,
          );
        } else {
          final imageFile = File(resolvedPath);
          if (await imageFile.exists()) {
            final bytes = await imageFile.readAsBytes();
            await _writeScaledNotificationArt(bytes, tempFile);
          }
        }
      }
      if (tempFile.existsSync()) {
        artUri = Uri.file(tempFile.path);
      }
    } catch (e) {
      AppLogger.w(
        'audio_handler.service',
        'thumbnail extract failed',
        error: e,
      );
    }

    // A different song may have started while we read the cover — don't let
    // this stale update clobber the current Now Playing entry.
    if (!isCurrent()) return;

    try {
      mediaItem.add(
        MediaItem(
          id: song.fileName,
          album: song.album ?? '',
          title: song.name,
          artist: song.artist ?? 'Unknown Artist',
          duration: _engineService.durationNotifier.value,
          artUri: artUri,
        ),
      );
      // macOS: push Now Playing info to MPNowPlayingInfoCenter so media
      // keys and the Touch Bar display the current track.
      PlatformService.instance.updateNowPlaying(
        title: song.name,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album,
        position: _engineService.positionNotifier.value,
        duration: _engineService.durationNotifier.value,
        isPlaying: _engineService.engineState.value == AudioEngineState.playing,
      );
      // iOS: sync WidgetKit home screen widget with current track info.
      PlatformService.instance.updateWidget(
        songName: song.name,
        artist: song.artist ?? 'Unknown Artist',
        isPlaying: _engineService.engineState.value == AudioEngineState.playing,
      );
    } catch (e) {
      AppLogger.w('audio_handler.service', 'mediaItem update failed', error: e);
    }
  }

  /// Decodes [bytes], downscales to at most [_kNotificationArtMaxEdge] on
  /// its longest edge, and writes a PNG to [target]. Falls back to writing
  /// the original bytes if the image package cannot decode them (never
  /// throws — notification art is best-effort).
  Future<void> _writeScaledNotificationArt(
    final Uint8List bytes,
    final File target,
  ) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        await target.writeAsBytes(bytes, flush: true);
        return;
      }
      final longest = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      final img.Image scaled = longest > _kNotificationArtMaxEdge
          ? img.copyResize(
              decoded,
              width: (decoded.width * _kNotificationArtMaxEdge / longest)
                  .round(),
              height: (decoded.height * _kNotificationArtMaxEdge / longest)
                  .round(),
              interpolation: img.Interpolation.average,
            )
          : decoded;
      await target.writeAsBytes(
        Uint8List.fromList(img.encodePng(scaled)),
        flush: true,
      );
    } catch (e, stack) {
      AppLogger.w(
        'audio_handler.service',
        'notification art downscale failed; writing original',
        error: e,
        stack: stack,
      );
      try {
        await target.writeAsBytes(bytes, flush: true);
      } catch (_) {}
    }
  }

  @override
  Future<void> play() async {
    final state = _engineService.engineState.value;
    if (state == AudioEngineState.paused) {
      await _engineService.resume();
    } else {
      // For any other state (idle, stopped, loading, error),
      // delegate to PlaylistService which handles all cases correctly.
      // This fixes Bug #9: resume() when engine is stopped/idle does nothing
      // because there is no active SoundHandle.
      await _playlistService.play();
    }
  }

  @override
  Future<void> pause() async => _engineService.pause();

  @override
  Future<void> stop() async => _engineService.stop();

  @override
  Future<void> seek(final Duration position) async =>
      _engineService.seek(position);

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

  /// Cleanup listeners — called during service teardown
  void disposeListeners() {
    _engineService.engineState.removeListener(_onEngineStateChanged);
    _playlistService.currentIndexNotifier.removeListener(_onSongChanged);
    _engineService.durationNotifier.removeListener(_onDurationChanged);
  }
}
