import 'package:flutter/material.dart';
import '../widgets/lyric_view.dart';
import '../../core/service_locator.dart';
import '../../core/audio/playlist_service.dart';
import '../../core/settings_manager.dart';
import '../widgets/cover_art_image.dart';

class KTVScreen extends StatelessWidget {
  const KTVScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sl<PlaylistService>().currentIndexNotifier,
      builder: (context, index, _) {
        final song = sl<PlaylistService>().currentSong;
        if (song == null) {
          return const Center(
            child: Text(
              'Không có bài hát nào đang phát',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Stack(
          fit: StackFit.expand,
          children: [
            // KTV Mode Background - Uses CoverArt
            Opacity(
              opacity: isDark ? 0.3 : 0.15,
              child: CoverArtImage(
                song: song,
                cacheWidth: 800,
                cacheHeight: 600,
                fallbackBuilder: (_) => Container(color: Colors.black),
              ),
            ),
            // Gradient overlay for lyric readability
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            // Lyrics overlay
            const Positioned.fill(
              child: LyricView(isFullScreen: true),
            ),
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  tooltip: 'Thoát phòng nhạc',
                  onPressed: () {
                    sl<SettingsManager>().currentTabIndexNotifier.value = 0;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
