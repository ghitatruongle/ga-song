import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../core/logging/app_logger.dart';
import '../screens/ios_fullscreen_player_screen.dart';
import 'cover_art_image.dart';

class MobileMiniPlayerBar extends ConsumerWidget {
  const MobileMiniPlayerBar({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playlistService = ref.watch(playlistServiceProvider);
    final engineService = ref.watch(audioEngineServiceProvider);
    final currentSong = playlistService.currentSong;
    final isAndroid = !kIsWeb && Platform.isAndroid;

    final content = Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isAndroid
            ? const Color(0xEE1E1E22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppLogger.i('MobileMiniPlayerBar', 'Cover/title tapped');
                HapticFeedback.lightImpact();
                IOSFullscreenPlayerScreen.show(context);
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: Colors.white10,
                      child: currentSong != null
                          ? CoverArtImage(
                              song: currentSong,
                              fallbackBuilder: (_) => const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            )
                          : const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong?.name ?? 'Chưa chọn bài hát',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentSong?.artist ?? 'Nhấn để mở trình phát',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: engineService.engineState,
            builder: (final context, final state, _) {
              final isPlaying = state == AudioEngineState.playing;
              return IconButton(
                icon: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (isPlaying) {
                    engineService.pause();
                  } else {
                    playlistService.play();
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.forward_fill,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              playlistService.next();
            },
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: isAndroid
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: content,
            ),
    );
  }
}
