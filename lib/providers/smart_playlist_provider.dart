import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/smart_playlist_service.dart';
import '../models/song.dart';
import 'service_providers.dart';
import 'song_provider.dart';

/// smartPlaylistServiceProvider is declared in service_providers.dart.
/// This file only contains the family provider.
final smartPlaylistProvider =
    FutureProvider.family<List<Song>, SmartPlaylistType>((
      final ref,
      final type,
    ) async {
      final service = ref.watch(smartPlaylistServiceProvider);

      // Depend on the song list stream so this refetches when database changes
      ref.watch(songListProvider);

      return service.getSmartPlaylist(type);
    });
