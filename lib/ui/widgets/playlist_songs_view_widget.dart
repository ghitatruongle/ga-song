import 'package:flutter/material.dart';
import '../../core/theme_utils.dart';
import '../widgets/desktop_title_bar.dart';
import '../widgets/main_content.dart';
import '../../models/song.dart';

/// View danh sách bài hát của một album/playlist cụ thể.
///
/// Được tách ra từ HomeScreen để giảm kích thước file.
class PlaylistSongsViewWidget extends StatelessWidget {
  const PlaylistSongsViewWidget({
    super.key,
    required this.playlistName,
    required this.currentViewSongs,
    required this.filteredSongs,
    required this.songIndexByFileName,
    required this.isLoading,
    required this.loadingError,
    required this.searchQuery,
    required this.onBack,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  final String? playlistName;
  final List<Song> currentViewSongs;
  final List<Song> filteredSongs;
  final Map<String, int> songIndexByFileName;
  final bool isLoading;
  final String? loadingError;
  final String searchQuery;
  final VoidCallback onBack;
  final void Function(String query) onSearchChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(final BuildContext context) {
    final adaptiveColor = context.adaptive;

    return Column(
      children: [
        const DesktopTitleBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: adaptiveColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                playlistName ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: adaptiveColor.withValues(alpha: 0.9),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: MainContentWidget(
            showTitleBar: false,
            isLoading: isLoading,
            loadingError: loadingError,
            songs: currentViewSongs,
            filteredSongs: filteredSongs,
            songIndexByFileName: songIndexByFileName,
            onSearchChanged: onSearchChanged,
            searchQuery: searchQuery,
            onRefresh: onRefresh,
          ),
        ),
      ],
    );
  }
}
