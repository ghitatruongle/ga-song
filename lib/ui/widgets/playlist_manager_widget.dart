import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import '../../core/theme/tokens.dart';
import '../screens/reorderable_playlist_view.dart';

class PlaylistManagerWidget {
  static void show(final BuildContext context) {
    showDialog(
      context: context,
      builder: (final context) => const _PlaylistManagerDialog(),
    );
  }

  static void showAddToPlaylist(final BuildContext context, final Song song) {
    showDialog(
      context: context,
      builder: (final context) => _AddToPlaylistDialog(song: song),
    );
  }
}

class _PlaylistManagerDialog extends ConsumerStatefulWidget {
  const _PlaylistManagerDialog();

  @override
  ConsumerState<_PlaylistManagerDialog> createState() =>
      _PlaylistManagerDialogState();
}

class _PlaylistManagerDialogState
    extends ConsumerState<_PlaylistManagerDialog> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _createPlaylist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final db = ref.read(databaseServiceProvider);
    final playlist = Playlist(name: name);
    await db.putPlaylist(playlist);

    if (mounted) {
      _nameController.clear();
      setState(() {});
    }
  }

  Future<void> _deletePlaylist(final int id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deletePlaylist(id);
    if (mounted) setState(() {});
  }

  void _openReorderablePlaylist(
    final BuildContext context,
    final int playlistId,
    final String name,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReorderablePlaylistView(playlistId: playlistId, playlistName: name),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final db = ref.watch(databaseServiceProvider);
    final textColor = context.adaptive;

    return AlertDialog(
      backgroundColor: context.isDark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      title: Text('Quản lý Playlist', style: TextStyle(color: textColor)),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Tên playlist mới...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createPlaylist,
                  child: const Text('Tạo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Playlist>>(
                future: db.getAllPlaylists(),
                builder: (final context, final snapshot) {
                  final playlists = snapshot.data ?? [];
                  if (playlists.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có playlist',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (final context, final index) {
                      final pl = playlists[index];
                      return ListTile(
                        title: Text(
                          pl.name,
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          '${pl.songIds.length} bài hát',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deletePlaylist(pl.id!),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openReorderablePlaylist(context, pl.id!, pl.name);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _AddToPlaylistDialog extends ConsumerStatefulWidget {
  final Song song;
  const _AddToPlaylistDialog({required this.song});

  @override
  ConsumerState<_AddToPlaylistDialog> createState() =>
      _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends ConsumerState<_AddToPlaylistDialog> {
  List<Playlist> _playlists = [];
  Set<int> _addedPlaylistIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final db = ref.read(databaseServiceProvider);
    final playlists = await db.getAllPlaylists();

    final addedIds = <int>{};
    for (final pl in playlists) {
      if (pl.songIds.contains(widget.song.id)) {
        addedIds.add(pl.id!);
      }
    }

    if (mounted) {
      setState(() {
        _playlists = playlists;
        _addedPlaylistIds = addedIds;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSongInPlaylist(final Playlist playlist) async {
    final db = ref.read(databaseServiceProvider);
    final isAdded = _addedPlaylistIds.contains(playlist.id);

    if (isAdded) {
      await db.removeSongFromPlaylist(playlist.id!, widget.song.id!);
    } else {
      await db.addSongToPlaylist(playlist.id!, widget.song.id!);
    }

    if (mounted) {
      setState(() {
        if (isAdded) {
          _addedPlaylistIds.remove(playlist.id);
        } else {
          _addedPlaylistIds.add(playlist.id!);
        }
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final textColor = context.adaptive;

    return AlertDialog(
      backgroundColor: context.isDark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      title: Text(
        'Thêm "${widget.song.name}" vào...',
        style: TextStyle(color: textColor, fontSize: 18),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 300,
        height: 300,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: textColor))
            : _playlists.isEmpty
            ? Center(
                child: Text(
                  'Chưa có playlist nào',
                  style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                ),
              )
            : ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (final context, final index) {
                  final pl = _playlists[index];
                  final isAdded = _addedPlaylistIds.contains(pl.id);

                  return ListTile(
                    title: Text(pl.name, style: TextStyle(color: textColor)),
                    trailing: isAdded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Icon(
                            Icons.circle_outlined,
                            color: textColor.withValues(alpha: 0.3),
                          ),
                    onTap: () => _toggleSongInPlaylist(pl),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            PlaylistManagerWidget.show(context);
          },
          child: const Text('Tạo mới'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Xong'),
        ),
      ],
    );
  }
}
