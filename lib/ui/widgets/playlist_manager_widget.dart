import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/song_provider.dart';
import '../../core/theme_utils.dart';
import 'package:isar/isar.dart';

class PlaylistManagerWidget {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _PlaylistManagerDialog(),
    );
  }

  static void showAddToPlaylist(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(song: song),
    );
  }
}

class _PlaylistManagerDialog extends ConsumerStatefulWidget {
  const _PlaylistManagerDialog();

  @override
  ConsumerState<_PlaylistManagerDialog> createState() => _PlaylistManagerDialogState();
}

class _PlaylistManagerDialogState extends ConsumerState<_PlaylistManagerDialog> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _createPlaylist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final isar = ref.read(isarProvider);
    final playlist = Playlist()..name = name;
    
    await isar.writeTxn(() async {
      await isar.playlists.put(playlist);
    });

    if (mounted) {
      _nameController.clear();
      setState(() {});
    }
  }

  Future<void> _deletePlaylist(int id) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.playlists.delete(id);
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isar = ref.watch(isarProvider);
    final playlists = isar.playlists.where().findAllSync();
    final textColor = context.adaptive;

    return AlertDialog(
      backgroundColor: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
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
              child: playlists.isEmpty
                  ? Center(child: Text('Chưa có playlist', style: TextStyle(color: textColor.withValues(alpha: 0.5))))
                  : ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final pl = playlists[index];
                        return ListTile(
                          title: Text(pl.name, style: TextStyle(color: textColor)),
                          subtitle: Text('${pl.songs.length} bài hát', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deletePlaylist(pl.id),
                          ),
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
  ConsumerState<_AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
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
    final isar = ref.read(isarProvider);
    final playlists = await isar.playlists.where().findAll();
    
    final addedIds = <int>{};
    for (final pl in playlists) {
      await pl.songs.load();
      if (pl.songs.any((s) => s.id == widget.song.id)) {
        addedIds.add(pl.id);
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

  Future<void> _toggleSongInPlaylist(Playlist playlist) async {
    final isar = ref.read(isarProvider);
    final isAdded = _addedPlaylistIds.contains(playlist.id);

    await isar.writeTxn(() async {
      await playlist.songs.load();
      if (isAdded) {
        playlist.songs.remove(widget.song);
      } else {
        playlist.songs.add(widget.song);
      }
      await playlist.songs.save();
    });

    if (mounted) {
      setState(() {
        if (isAdded) {
          _addedPlaylistIds.remove(playlist.id);
        } else {
          _addedPlaylistIds.add(playlist.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;

    return AlertDialog(
      backgroundColor: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                    itemBuilder: (context, index) {
                      final pl = _playlists[index];
                      final isAdded = _addedPlaylistIds.contains(pl.id);

                      return ListTile(
                        title: Text(pl.name, style: TextStyle(color: textColor)),
                        trailing: isAdded
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.circle_outlined, color: textColor.withValues(alpha: 0.3)),
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
