import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/audio_engine_service.dart';
import '../core/audio/playlist_service.dart';
import 'service_providers.dart';

/// Notifier exposing the current [AudioEngineState] as a Riverpod state.
///
/// Subscribes to the engine's internal [ValueNotifier] and rebuilds on every
/// change. Use [engineStateProvider] in widgets that need to react to
/// playback state transitions (loading → playing → paused → stopped).
class EngineStateNotifier extends Notifier<AudioEngineState> {
  late AudioEngineService _engine;

  @override
  AudioEngineState build() {
    _engine = ref.watch(audioEngineServiceProvider);
    final notifier = _engine.engineState;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() {
    final next = _engine.engineState.value;
    if (state != next) state = next;
  }
}

final engineStateProvider =
    NotifierProvider<EngineStateNotifier, AudioEngineState>(
      EngineStateNotifier.new,
    );

/// Notifier exposing the current playback position as Riverpod state.
///
/// Subscribes to [AudioEngineService.positionNotifier] which the engine
/// updates via its position timer. Use [positionProvider] for slider/progress
/// UIs that need to follow playback.
class PositionNotifier extends Notifier<Duration> {
  late AudioEngineService _engine;

  @override
  Duration build() {
    _engine = ref.watch(audioEngineServiceProvider);
    final notifier = _engine.positionNotifier;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() => state = _engine.positionNotifier.value;
}

final positionProvider = NotifierProvider<PositionNotifier, Duration>(
  PositionNotifier.new,
);

/// Notifier exposing the current track duration as Riverpod state.
class DurationNotifier extends Notifier<Duration> {
  late AudioEngineService _engine;

  @override
  Duration build() {
    _engine = ref.watch(audioEngineServiceProvider);
    final notifier = _engine.durationNotifier;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() => state = _engine.durationNotifier.value;
}

final trackDurationProvider = NotifierProvider<DurationNotifier, Duration>(
  DurationNotifier.new,
);

/// Notifier exposing the current volume as Riverpod state.
class VolumeNotifier extends Notifier<double> {
  late AudioEngineService _engine;

  @override
  double build() {
    _engine = ref.watch(audioEngineServiceProvider);
    final notifier = _engine.volumeNotifier;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() => state = _engine.volumeNotifier.value;
}

final volumeProvider = NotifierProvider<VolumeNotifier, double>(
  VolumeNotifier.new,
);

/// Notifier exposing the current playing index in the playlist.
class CurrentPlayingIndexNotifier extends Notifier<int> {
  late PlaylistService _playlist;

  @override
  int build() {
    _playlist = ref.watch(playlistServiceProvider);
    final notifier = _playlist.currentIndexNotifier;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() => state = _playlist.currentIndexNotifier.value;
}

final currentPlayingIndexProvider =
    NotifierProvider<CurrentPlayingIndexNotifier, int>(
      CurrentPlayingIndexNotifier.new,
    );

/// Notifier exposing the current play mode.
class PlayModeNotifier extends Notifier<PlayMode> {
  late PlaylistService _playlist;

  @override
  PlayMode build() {
    _playlist = ref.watch(playlistServiceProvider);
    final notifier = _playlist.playModeNotifier;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() => state = _playlist.playModeNotifier.value;
}

final playModeProvider = NotifierProvider<PlayModeNotifier, PlayMode>(
  PlayModeNotifier.new,
);

/// Notifier exposing the sleep-timer remaining duration (null if no timer).
class SleepTimerNotifier extends Notifier<Duration?> {
  late PlaylistService _playlist;

  @override
  Duration? build() {
    _playlist = ref.watch(playlistServiceProvider);
    final notifier = _playlist.sleepTimerRemainingNotifier;
    ref.onDispose(() => notifier.removeListener(_onChange));
    notifier.addListener(_onChange);
    return notifier.value;
  }

  void _onChange() => state = _playlist.sleepTimerRemainingNotifier.value;
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, Duration?>(
  SleepTimerNotifier.new,
);
