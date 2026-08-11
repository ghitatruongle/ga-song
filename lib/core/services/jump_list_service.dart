/// Windows Jump List Service for G.A - Song
///
/// Provides integration with Windows Taskbar Jump List for:
/// - Recent playlists
/// - Pinned songs/playlists
/// - Common tasks (Play, Pause, Next, Previous, Open Settings)
library;

import 'dart:async';

import '../logging/app_logger.dart';
import '../platform_capabilities.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';

/// Represents a Jump List item
class JumpListItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? iconPath;
  final JumpListItemType type;
  final Map<String, dynamic> arguments;

  const JumpListItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.iconPath,
    required this.type,
    this.arguments = const {},
  });

  factory JumpListItem.playlist(
    final Playlist playlist, {
    final bool pinned = false,
  }) => JumpListItem(
    id: 'playlist_${playlist.id}',
    title: playlist.name,
    subtitle: 'Playlist (${playlist.songIds.length} songs)',
    type: pinned ? JumpListItemType.pinned : JumpListItemType.recent,
    arguments: {'action': 'open_playlist', 'playlist_id': playlist.id},
  );

  factory JumpListItem.song(final Song song, {final bool pinned = false}) =>
      JumpListItem(
        id: 'song_${song.id}',
        title: song.name,
        subtitle: song.artist ?? 'Unknown Artist',
        type: pinned ? JumpListItemType.pinned : JumpListItemType.recent,
        arguments: {'action': 'play_song', 'song_id': song.id},
      );

  factory JumpListItem.task({
    required final String id,
    required final String title,
    required final String action,
    final String? iconPath,
    final Map<String, dynamic>? arguments,
  }) => JumpListItem(
    id: 'task_$id',
    title: title,
    type: JumpListItemType.task,
    iconPath: iconPath,
    arguments: {'action': action, ...?arguments},
  );
}

enum JumpListItemType { recent, pinned, task }

/// Windows Jump List Service
class JumpListService {
  JumpListService();

  static const int _maxRecentItems = 10;
  static const int _maxPinnedItems = 5;

  // In-memory storage (will be persisted to SharedPreferences)
  final List<JumpListItem> _recentItems = [];
  final List<JumpListItem> _pinnedItems = [];

  Timer? _debounceTimer;
  bool _initialized = false;

  /// Initialize the Jump List service
  Future<void> init() async {
    if (_initialized || !PlatformCapabilities.instance.isWindows) return;

    try {
      await _loadFromPrefs();
      await _rebuildJumpList();
      // Mark initialized only AFTER success — a failed init can be retried
      // on the next call (previously it was permanently stuck).
      _initialized = true;
      AppLogger.i('jump_list.service', 'Jump List initialized');
    } catch (e, stack) {
      AppLogger.e(
        'jump_list.service',
        'Failed to initialize Jump List',
        error: e,
        stack: stack,
      );
    }
  }

  /// Load items from SharedPreferences
  Future<void> _loadFromPrefs() async {
    // This would be implemented with SharedPreferences
    // For now, we'll use in-memory storage
  }

  /// Save items to SharedPreferences
  /// Add a playlist to recent items
  Future<void> addRecentPlaylist(final Playlist playlist) async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _recentItems.removeWhere(
      (final item) => item.id == 'playlist_${playlist.id}',
    );
    _recentItems.insert(0, JumpListItem.playlist(playlist));

    if (_recentItems.length > _maxRecentItems) {
      _recentItems.removeLast();
    }

    await _rebuildJumpList();
  }

  /// Add a song to recent items
  Future<void> addRecentSong(final Song song) async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _recentItems.removeWhere((final item) => item.id == 'song_${song.id}');
    _recentItems.insert(0, JumpListItem.song(song));

    if (_recentItems.length > _maxRecentItems) {
      _recentItems.removeLast();
    }

    await _rebuildJumpList();
  }

  /// Pin a playlist
  Future<void> pinPlaylist(final Playlist playlist) async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _pinnedItems.removeWhere(
      (final item) => item.id == 'playlist_${playlist.id}',
    );
    _pinnedItems.add(JumpListItem.playlist(playlist, pinned: true));

    if (_pinnedItems.length > _maxPinnedItems) {
      _pinnedItems.removeLast();
    }

    await _rebuildJumpList();
  }

  /// Pin a song
  Future<void> pinSong(final Song song) async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _pinnedItems.removeWhere((final item) => item.id == 'song_${song.id}');
    _pinnedItems.add(JumpListItem.song(song, pinned: true));

    if (_pinnedItems.length > _maxPinnedItems) {
      _pinnedItems.removeLast();
    }

    await _rebuildJumpList();
  }

  /// Unpin an item
  Future<void> unpinItem(final String itemId) async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _pinnedItems.removeWhere((final item) => item.id == itemId);
    await _rebuildJumpList();
  }

  /// Clear all recent items
  Future<void> clearRecent() async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _recentItems.clear();
    await _rebuildJumpList();
  }

  /// Clear all pinned items
  Future<void> clearPinned() async {
    if (!PlatformCapabilities.instance.isWindows) return;

    _pinnedItems.clear();
    await _rebuildJumpList();
  }

  /// Get all recent items
  List<JumpListItem> get recentItems => List.unmodifiable(_recentItems);

  /// Get all pinned items
  List<JumpListItem> get pinnedItems => List.unmodifiable(_pinnedItems);

  /// Rebuild the Windows Jump List
  Future<void> _rebuildJumpList() async {
    if (!PlatformCapabilities.instance.isWindows) return;

    try {
      // This is where we would call the Windows API to update the Jump List
      // Using Dart FFI or a platform channel
      await _updateWindowsJumpList();
    } catch (e, stack) {
      AppLogger.w(
        'jump_list.service',
        'Failed to rebuild Jump List',
        error: e,
        stack: stack,
      );
    }
  }

  /// Update the actual Windows Jump List via platform channel or FFI
  Future<void> _updateWindowsJumpList() async {
    // This would use a platform channel or Dart FFI to call Windows APIs
    // For now, we'll use a platform channel approach

    final items = <Map<String, dynamic>>[];

    // Add pinned items first
    for (final item in _pinnedItems) {
      items.add({
        'id': item.id,
        'title': item.title,
        'subtitle': item.subtitle,
        'type': item.type.name,
        'pinned': item.type == JumpListItemType.pinned,
        'arguments': item.arguments,
      });
    }

    // Add recent items
    for (final item in _recentItems) {
      if (item.type != JumpListItemType.pinned) {
        items.add({
          'id': item.id,
          'title': item.title,
          'subtitle': item.subtitle,
          'type': item.type.name,
          'pinned': false,
          'arguments': item.arguments,
        });
      }
    }

    // Add common tasks
    items.addAll([
      {
        'id': 'task_play',
        'title': 'Play',
        'type': 'task',
        'arguments': {'action': 'play'},
      },
      {
        'id': 'task_pause',
        'title': 'Pause',
        'type': 'task',
        'arguments': {'action': 'pause'},
      },
      {
        'id': 'task_next',
        'title': 'Next',
        'type': 'task',
        'arguments': {'action': 'next'},
      },
      {
        'id': 'task_previous',
        'title': 'Previous',
        'type': 'task',
        'arguments': {'action': 'previous'},
      },
      {
        'id': 'task_settings',
        'title': 'Settings',
        'type': 'task',
        'arguments': {'action': 'settings'},
      },
    ]);

    // Send to platform channel (would be implemented in platform-specific code)
    AppLogger.d(
      'jump_list.service',
      'Jump List items prepared: ${items.length} items',
    );
  }

  /// Handle a Jump List action
  Future<void> handleJumpListAction(
    final Map<String, dynamic> arguments,
  ) async {
    final action = arguments['action'] as String?;
    if (action == null) return;

    AppLogger.i('jump_list.service', 'Handling Jump List action: $action');

    switch (action) {
      case 'play':
        // Resume playback
        break;
      case 'pause':
        // Pause playback
        break;
      case 'next':
        // Next track
        break;
      case 'previous':
        // Previous track
        break;
      case 'settings':
        // Open settings
        break;
      case 'open_playlist':
        final playlistId = arguments['playlist_id'] as int?;
        if (playlistId != null) {
          // Navigate to playlist
        }
        break;
      case 'play_song':
        final songId = arguments['song_id'] as int?;
        if (songId != null) {
          // Play song
        }
        break;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
