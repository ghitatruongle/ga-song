import '../../models/song.dart';
import 'db_service_wrapper.dart';

/// Types of smart playlists that are auto-generated from the library.
enum SmartPlaylistType {
  mostPlayed,
  recentlyPlayed,
  favorites,
  recentlyAdded,
  discovery,
}

/// Service that generates smart playlists from the database.
///
/// Smart playlists are auto-generated based on song metadata and
/// listening history. They are not stored as regular playlists but
/// queried on demand.
class SmartPlaylistService {
  final DatabaseServiceWrapper _databaseService;

  SmartPlaylistService(this._databaseService);

  /// Get songs for a specific smart playlist type
  Future<List<Song>> getSmartPlaylist(final SmartPlaylistType type) async {
    switch (type) {
      case SmartPlaylistType.mostPlayed:
        return _databaseService.getMostPlayedSongs();
      case SmartPlaylistType.recentlyPlayed:
        return _databaseService.getRecentlyPlayedSongs();
      case SmartPlaylistType.favorites:
        return _databaseService.getFavoriteSongs();
      case SmartPlaylistType.recentlyAdded:
        return _databaseService.getRecentlyAddedSongs();
      case SmartPlaylistType.discovery:
        return _databaseService.getDiscoverySongs();
    }
  }

  /// Get display name for a smart playlist type
  static String getDisplayName(final SmartPlaylistType type) {
    switch (type) {
      case SmartPlaylistType.mostPlayed:
        return 'Nghe nhiều nhất';
      case SmartPlaylistType.recentlyPlayed:
        return 'Nghe gần đây';
      case SmartPlaylistType.favorites:
        return 'Yêu thích';
      case SmartPlaylistType.recentlyAdded:
        return 'Thêm gần đây';
      case SmartPlaylistType.discovery:
        return 'Khám phá';
    }
  }

  /// Get icon for a smart playlist type
  static String getIcon(final SmartPlaylistType type) {
    switch (type) {
      case SmartPlaylistType.mostPlayed:
        return '🔥';
      case SmartPlaylistType.recentlyPlayed:
        return '🕐';
      case SmartPlaylistType.favorites:
        return '❤️';
      case SmartPlaylistType.recentlyAdded:
        return '🆕';
      case SmartPlaylistType.discovery:
        return '🎲';
    }
  }
}
