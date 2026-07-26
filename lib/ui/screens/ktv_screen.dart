import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/lyric_view.dart';
import '../../providers/service_providers.dart';
import '../widgets/cover_art_image.dart';

class KTVScreen extends ConsumerWidget {
  const KTVScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistService = ref.read(playlistServiceProvider);
    return ValueListenableBuilder<int>(
      valueListenable: playlistService.currentIndexNotifier,
      builder: (context, index, _) {
        final song = playlistService.currentSong;
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
            const Positioned.fill(child: LyricView(isFullScreen: true)),
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Thoát phòng nhạc',
                  onPressed: () {
                    ref
                            .read(settingsManagerProvider)
                            .currentTabIndexNotifier
                            .value =
                        0;
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
