import 'package:flutter/foundation.dart';

import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../../models/song.dart';

/// **Deprecated** — Use the new Riverpod state providers from
/// `lib/providers/state_providers.dart` instead. This class is kept as a
/// transitional facade; new code MUST NOT depend on it.
///
/// Migration map:
/// - `viewModel.isPlaying` → `ref.watch(engineStateProvider) == AudioEngineState.playing`
/// - `viewModel.position` → `ref.watch(positionProvider)`
/// - `viewModel.duration` → `ref.watch(trackDurationProvider)`
/// - `viewModel.volume` → `ref.watch(volumeProvider)`
/// - `viewModel.playMode` → `ref.watch(playModeProvider)`
/// - `viewModel.currentSong` → combine `currentPlayingIndexProvider` with playlist
/// - Actions (`play()`, `pause()`, etc.) → call `PlaylistService` and `AudioEngineService`
///   directly via the corresponding `*ServiceProvider`.
///
/// Removal target: v3.0.0.
@Deprecated('Use state providers from lib/providers/state_providers.dart')
class PlayerViewModel extends ChangeNotifier {
  final AudioEngineService _engineService;
  final PlaylistService _playlistService;

  PlayerViewModel(this._engineService, this._playlistService) {
    _engineService.engineState.addListener(notifyListeners);
    _engineService.volumeNotifier.addListener(notifyListeners);
    _playlistService.currentIndexNotifier.addListener(notifyListeners);
    _playlistService.playModeNotifier.addListener(notifyListeners);
  }

  // ignore: deprecated_member_use_from_within_class
  AudioEngineState get engineState => _engineService.engineState.value;
  ValueNotifier<Duration> get positionNotifier => _engineService.positionNotifier;
  ValueNotifier<Duration> get durationNotifier => _engineService.durationNotifier;

  Duration get position => _engineService.positionNotifier.value;
  Duration get duration => _engineService.durationNotifier.value;
  double get volume => _engineService.volumeNotifier.value;

  bool get isPlaying => engineState == AudioEngineState.playing;
  bool get isLoading => engineState == AudioEngineState.loading;

  double get progress {
    if (duration.inMilliseconds > 0) {
      return position.inMilliseconds / duration.inMilliseconds;
    }
    return 0.0;
  }

  Song? get currentSong => _playlistService.currentSong;
  PlayMode get playMode => _playlistService.playModeNotifier.value;
  bool get hasNext => _playlistService.playlist.isNotEmpty;
  bool get hasPrevious => _playlistService.playlist.isNotEmpty;

  void play() => _playlistService.play();
  void pause() => _engineService.pause();
  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void next() => _playlistService.next();
  void previous() => _playlistService.previous();
  void seek(Duration newPosition) => _engineService.seek(newPosition);
  void togglePlayMode() => _playlistService.nextPlayMode();
  void setVolume(double volume) => _engineService.setVolume(volume);

  @override
  void dispose() {
    _engineService.engineState.removeListener(notifyListeners);
    _engineService.volumeNotifier.removeListener(notifyListeners);
    _playlistService.currentIndexNotifier.removeListener(notifyListeners);
    _playlistService.playModeNotifier.removeListener(notifyListeners);
    super.dispose();
  }
}
