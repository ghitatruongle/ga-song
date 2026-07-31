import 'package:flutter/material.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme_utils.dart';
import '../utils/animation_utils.dart';
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
                          // Phase 4 fix: aspect 0.75 (tile is 33% taller than
                          // wide) gives the album-name Text enough vertical
                          // budget for 2 lines + ellipsis on narrow mobile
                          // viewports (~111 px wide after sidebar + padding)
                          // without silently collapsing to a single line.
                          childAspectRatio: 0.75,
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
                              .where(
                                (s) => albumName == 'Chưa phân loại'
                                    ? (s.album == null || s.album!.isEmpty)
                                    : s.album == albumName,
                              )
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

class _AlbumTile extends StatefulWidget {
  const _AlbumTile({
    required this.albumName,
    required this.songCount,
    required this.onTap,
  });

  final String albumName;
  final int songCount;
  final VoidCallback onTap;

  @override
  State<_AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<_AlbumTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _onTap() {
    // Phase 4 Task 7: tap also gets a tiny scale-down echo (released on press).
    if (animationsEnabled(context) && _isPressed) {
      setState(() => _isPressed = false);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final adaptiveColor = context.adaptive;
    final isSpecialAlbum = widget.albumName == 'Mắt Nhắm Mắt Mở';
    final animations = animationsEnabled(context);

    return AnimatedContainer(
      duration: animations ? AppDurations.short : Duration.zero,
      curve: AppCurves.decelerate,
      transform: Matrix4.identity()
        ..scaleByDouble(
          _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
          _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
          1.0,
          1.0,
        ),
      transformAlignment: Alignment.center,
      child: GestureDetector(
        onTap: _onTap,
        onTapDown: (_) {
          if (animations) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (animations) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (animations) setState(() => _isPressed = false);
        },
          child: MouseRegion(
            onEnter: (_) {
              if (animations) setState(() => _isHovered = true);
            },
            onExit: (_) {
              if (animations) setState(() => _isHovered = false);
            },
            child: Container(
              decoration: BoxDecoration(
                color: adaptiveColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered
                      ? adaptiveColor.withValues(alpha: 0.3)
                      : adaptiveColor.withValues(alpha: 0.15),
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: adaptiveColor.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSpecialAlbum)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/pic/mat_nham_mat_mo/mat_nham_mat_mo_trailer.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(
                    Icons.album_rounded,
                    size: 56,
                    color: adaptiveColor.withValues(alpha: 0.8),
                  ),
                const SizedBox(height: 10),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.albumName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: adaptiveColor.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).translateWith('songCount', {
                      'count': widget.songCount.toString(),
                    }),
                    style: TextStyle(
                      fontSize: 13,
                      color: adaptiveColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
