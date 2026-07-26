import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/song.dart';

// Provides the current song based on the currentIndexNotifier
final currentSongProvider = Provider<Song?>((ref) {
  final playlistService = ref.watch(playlistServiceProvider);
  ref.watch(currentPlayingIndexProvider);
  return playlistService.currentSong;
});

/// Exposes the dominant color of the currently playing song
final currentSongDominantColorProvider = FutureProvider<Color?>((ref) async {
  final currentSong = ref.watch(currentSongProvider);

  if (currentSong == null) return null;

  final coverArtRepo = ref.watch(coverArtRepositoryProvider);
  return await coverArtRepo.resolveDominantColor(currentSong);
});
