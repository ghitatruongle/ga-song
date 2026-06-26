import 'package:flutter/material.dart';
import '../../core/theme_utils.dart';
import '../widgets/desktop_title_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/song.dart';

/// Grid hiển thị danh sách album/playlist.
///
/// Được tách ra từ HomeScreen để giảm kích thước file.
class AlbumGridWidget extends StatelessWidget {
  const AlbumGridWidget({
    super.key,
    required this.albums,
    required this.albumSongCount,
    required this.onAlbumTap,
    required this.songs,
  });

  final List<String> albums;
  final Map<String, int> albumSongCount;
  final void Function(String albumName, List<Song> songs) onAlbumTap;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final adaptiveColor = context.adaptive;

    return Column(
      children: [
        const DesktopTitleBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 10, 40, 40),
            child: albums.isEmpty
                ? _buildEmptyState(adaptiveColor, context)
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final albumName = albums[index];
                      final count = albumSongCount[albumName] ?? 0;
                      return _AlbumTile(
                        albumName: albumName,
                        songCount: count,
                        onTap: () {
                          final playlistSongs = songs
                              .where((s) => s.album == albumName)
                              .toList();
                          onAlbumTap(albumName, playlistSongs);
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color adaptiveColor, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.album_rounded,
            size: 64,
            color: adaptiveColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noPlaylist,
            style: TextStyle(
              fontSize: 18,
              color: adaptiveColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).addAlbumField,
            style: TextStyle(
              fontSize: 13,
              color: adaptiveColor.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.albumName,
    required this.songCount,
    required this.onTap,
  });

  final String albumName;
  final int songCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptiveColor = context.adaptive;
    final isSpecialAlbum = albumName == 'Mắt Nhắm Mắt Mở';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: adaptiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: adaptiveColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSpecialAlbum)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/pic/mat_nham_mat_mo/mat_nham_mat_mo_trailer.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              )
            else
              Icon(
                Icons.album_rounded,
                size: 64,
                color: adaptiveColor.withValues(alpha: 0.8),
              ),
            const SizedBox(height: 16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  albumName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: adaptiveColor.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translateWith(
                'songCount',
                {'count': songCount.toString()},
              ),
              style: TextStyle(
                fontSize: 14,
                color: adaptiveColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
