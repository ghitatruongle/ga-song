import '../../models/song.dart';
import '../audio/playlist_service.dart';

/// Shared sorting logic used by both [PlaylistService] and UI layers.
///
/// Centralizes sort comparison to eliminate the duplication that previously
/// existed between `home_screen.dart` and `playlist_service.dart`.
class SongSortUtils {
  const SongSortUtils._();

  /// Sorts [songs] in-place according to [mode] and [ascending].
  ///
  /// When [ascending] is true (default), songs are sorted A→Z / old→new /
  /// short→long. When false, the order is reversed.
  ///
  /// **Edge cases handled:**
  /// - Empty artist name sorts to the end regardless of direction
  ///   (songs with no artist metadata should not interrupt alphabetically
  ///    ordered groups).
  /// - Null [durationMs] is treated as 0 (sorts first when ascending).
  /// - Null [dateAdded] is treated as [DateTime.epoch] (sorts first when
  ///   ascending).
  static void sort(
    final List<Song> songs,
    final SortMode mode, {
    final bool ascending = true,
  }) {
    final int dir = ascending ? 1 : -1;

    songs.sort((final a, final b) {
      switch (mode) {
        case SortMode.name:
          return dir * a.name.toLowerCase().compareTo(b.name.toLowerCase());

        case SortMode.artist:
          final aArtist = a.artist?.toLowerCase() ?? '';
          final bArtist = b.artist?.toLowerCase() ?? '';

          // Songs without artist metadata sort to the end.
          if (aArtist.isEmpty && bArtist.isEmpty) return 0;
          if (aArtist.isEmpty) return dir;
          if (bArtist.isEmpty) return -dir;

          return dir * aArtist.compareTo(bArtist);

        case SortMode.duration:
          final aDur = a.durationMs ?? 0;
          final bDur = b.durationMs ?? 0;
          return dir * aDur.compareTo(bDur);

        case SortMode.dateAdded:
          final aDate = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dir * aDate.compareTo(bDate);

        case SortMode.playCount:
          return dir * a.playCount.compareTo(b.playCount);

        case SortMode.lastPlayed:
          final aLast = a.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bLast = b.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dir * aLast.compareTo(bLast);
      }
    });
  }

  /// Returns a new sorted [List] based on [mode] and [ascending].
  ///
  /// The original list is not modified.
  static List<Song> sorted(
    final List<Song> songs,
    final SortMode mode, {
    final bool ascending = true,
  }) {
    final result = List<Song>.from(songs);
    sort(result, mode, ascending: ascending);
    return result;
  }

  /// Converts an integer sort-mode value (as stored in [SettingsManager])
  /// to the [SortMode] enum.
  ///
  /// Mapping:
  /// - 0 → [SortMode.name]
  /// - 1 → [SortMode.artist]
  /// - 2 → [SortMode.dateAdded]
  /// - 3 → [SortMode.duration]
  /// - Any other value → [SortMode.name] (safe fallback)
  static SortMode sortModeFromInt(final int mode) {
    switch (mode) {
      case 0:
        return SortMode.name;
      case 1:
        return SortMode.artist;
      case 2:
        return SortMode.dateAdded;
      case 3:
        return SortMode.duration;
      case 4:
        return SortMode.playCount;
      case 5:
        return SortMode.lastPlayed;
      default:
        return SortMode.name;
    }
  }
}
