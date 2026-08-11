import 'web_audio_player_stub.dart'
    if (dart.library.html) 'web_audio_player_web.dart';

abstract class WebAudioPlayer {
  factory WebAudioPlayer() => getWebAudioPlayer();

  Future<void> play(final String assetPath);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(final Duration position);
  void setVolume(final double volume);
  Duration get position;
  Duration get duration;
  bool get isPlaying;
  bool get isPaused;
  Stream<void> get onEnded;
  List<double> getFftData();
  void dispose();
}
