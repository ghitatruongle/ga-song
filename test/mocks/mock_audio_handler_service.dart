/// Mock implementation of [GaSongAudioHandler] for testing.
/// Provides controlled audio handler behavior without platform dependencies.
library;

import 'dart:async';
import 'package:ga_song/core/services/audio_handler_service.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:audio_service/audio_service.dart';

class MockAudioHandlerService extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  final AudioEngineService engineService;
  final PlaylistService playlistService;

  bool initialized = false;

  // Track calls for verification
  int initCallCount = 0;
  int updateMediaItemCallCount = 0;
  int updateQueueCallCount = 0;
  int updatePlaybackStateCallCount = 0;
  int disposeCallCount = 0;

  MockAudioHandlerService(this.engineService, this.playlistService);

  Future<void> init() async {
    initCallCount++;
    initialized = true;
  }

  /// Mock-only: simulates a media item update.
  Future<void> updateMediaItemMock() async {
    updateMediaItemCallCount++;
  }

  /// Mock-only: simulates a queue update.
  Future<void> updateQueueMock() async {
    updateQueueCallCount++;
  }

  /// Mock-only: simulates a playback state update.
  Future<void> updatePlaybackState() async {
    updatePlaybackStateCallCount++;
  }

  void dispose() {
    disposeCallCount++;
    initialized = false;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
