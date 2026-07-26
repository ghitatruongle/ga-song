import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/smart_playlist_service.dart';
import '../models/song.dart';
import 'service_providers.dart';
import 'song_provider.dart';

final smartPlaylistServiceProvider = Provider<SmartPlaylistService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SmartPlaylistService(db);
});

final smartPlaylistProvider =
    FutureProvider.family<List<Song>, SmartPlaylistType>((ref, type) async {
      final service = ref.watch(smartPlaylistServiceProvider);

      // Depend on the song list stream so this refetches when database changes
      ref.watch(songListProvider);

      return service.getSmartPlaylist(type);
    });
