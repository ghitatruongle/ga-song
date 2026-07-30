import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../providers/service_providers.dart';
import '../../models/song.dart';
import '../widgets/cover_art_image.dart';

/// Screen for viewing and reordering songs in a user-created playlist.
///
/// Supports drag-and-drop reorder via [ReorderableListView].  Changes
/// are persisted to the Drift database immediately on each reorder.
class ReorderablePlaylistView extends ConsumerStatefulWidget {
  const ReorderablePlaylistView({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  final int playlistId;
  final String playlistName;

  @override
  ConsumerState<ReorderablePlaylistView> createState() =>
      _ReorderablePlaylistViewState();
}

class _ReorderablePlaylistViewState extends ConsumerState<ReorderablePlaylistView> {
  late Future<List<Song>> _songsFuture;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void didUpdateWidget(covariant ReorderablePlaylistView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId != widget.playlistId) {
      _loadSongs();
    }
  }

  void _loadSongs() {
    _songsFuture = _fetchPlaylistSongs();
  }

  Future<List<Song>> _fetchPlaylistSongs() async {
    final db = ref.read(databaseServiceProvider);
    return await db.getPlaylistSongsDirect(widget.playlistId);
  }

  Future<void> _onReorderItem(int oldIndex, int newIndex) async {
    if (_isReordering) return;
    setState(() => _isReordering = true);

    try {
      final snapshot = await _songsFuture;
      if (oldIndex < newIndex) newIndex -= 1;

      final moved = snapshot[oldIndex];
      final reordered = List<Song>.from(snapshot);
      reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);

      // Persist new order to DB
      final db = ref.read(databaseServiceProvider);
      final songIds = reordered.where((s) => s.id != null).map((s) => s.id!).toList();
      await db.reorderPlaylistSongs(widget.playlistId, songIds);

      // Refresh the list
      setState(() {
        _songsFuture = _fetchPlaylistSongs();
      });

      // If this playlist is currently playing, update the queue order
      final playlistService = ref.read(playlistServiceProvider);
      if (playlistService.currentSong != null) {
        final currentFileName = playlistService.currentSong!.fileName;
        final currentInNewOrder =
            reordered.indexWhere((s) => s.fileName == currentFileName);
        if (currentInNewOrder >= 0) {
          playlistService.reorderPlaylist(reordered);
          playlistService.playSongAt(currentInNewOrder);
        }
      }
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptiveColor = context.adaptive;

    return Scaffold(
      backgroundColor: context.isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Column(
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: adaptiveColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.playlistName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: adaptiveColor.withValues(alpha: 0.9),
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isReordering)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          // Song list
          Expanded(
            child: FutureBuilder<List<Song>>(
              future: _songsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: adaptiveColor),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải danh sách bài hát',
                      style: TextStyle(color: adaptiveColor.withValues(alpha: 0.6)),
                    ),
                  );
                }
                final songs = snapshot.data ?? [];
                if (songs.isEmpty) {
                  return Center(
                    child: Text(
                      'Playlist trống',
                      style: TextStyle(color: adaptiveColor.withValues(alpha: 0.5)),
                    ),
                  );
                }

                return ReorderableListView.builder(
                  onReorderItem: _onReorderItem,
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
                  itemCount: songs.length,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return _ReorderableSongTile(
                      key: ValueKey<int>(song.id != null ? song.id! : index),
                      song: song,
                      index: index,
                      playlistId: widget.playlistId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReorderableSongTile extends ConsumerWidget {
  const _ReorderableSongTile({
    required super.key,
    required this.song,
    required this.index,
    required this.playlistId,
  });

  final Song song;
  final int index;
  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adaptiveColor = context.adaptive;
    final isDark = context.isDark;
    final playlistService = ref.read(playlistServiceProvider);
    final isCurrent = playlistService.currentSong?.fileName == song.fileName;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark ? AppColors.darkSidebarHover : AppColors.lightSurface2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ReorderableDragStartListener(
        index: index,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Icon(
                Icons.drag_handle_rounded,
                color: adaptiveColor.withValues(alpha: 0.3),
                size: 20,
              ),
              const SizedBox(width: 12),
              // Cover art thumbnail (fixed size via SizedBox)
              SizedBox(
                width: 40,
                height: 40,
                child: CoverArtImage(
                  song: song,
                  cacheWidth: 80,
                  cacheHeight: 80,
                  fit: BoxFit.cover,
                  fallbackBuilder: (context) => Container(
                    color: AppColors.darkSurface2,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: adaptiveColor.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            song.name,
            style: TextStyle(
              color: isCurrent
                  ? AppColors.defaultAccent
                  : adaptiveColor.withValues(alpha: 0.9),
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist ?? 'Không rõ',
            style: TextStyle(
              color: adaptiveColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            _formatDuration(song.durationMs ?? 0),
            style: TextStyle(
              color: adaptiveColor.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          onTap: () {
            // Play this song in the context of the playlist
            final db = ref.read(databaseServiceProvider);
            db.getPlaylistSongsDirect(playlistId).then((songs) {
              final currentPlaylist = ref.read(playlistServiceProvider);
              if (currentPlaylist.currentSong?.fileName != song.fileName) {
                currentPlaylist.reorderPlaylist(songs);
                final idx = songs.indexWhere((s) => s.fileName == song.fileName);
                if (idx >= 0) {
                  currentPlaylist.playSongAt(idx);
                }
              }
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  static String _formatDuration(int ms) {
    final totalSec = ms ~/ 1000;
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
