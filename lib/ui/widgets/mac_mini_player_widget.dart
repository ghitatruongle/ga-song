import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../core/services/window_manager_service.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../core/audio/playlist_service.dart';
import 'cover_art_image.dart';

class MacMiniPlayerWidget extends ConsumerWidget {
  final WindowManagerService windowManagerService;

  const MacMiniPlayerWidget({super.key, required this.windowManagerService});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playlistService = ref.watch(playlistServiceProvider);
    final engineService = ref.watch(audioEngineServiceProvider);
    final currentSong = playlistService.currentSong;
    final playMode = ref.watch(playModeProvider);
    final isShuffle = playMode == PlayMode.shuffle;
    final isRepeatOne = playMode == PlayMode.repeatOne;
    final isRepeatAll = playMode == PlayMode.sequential;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanStart: (_) => windowManagerService.startDragging(),
        child: Stack(
          children: [
            if (currentSong != null)
              Positioned.fill(
                child: CoverArtImage(
                  song: currentSong,
                  fallbackBuilder: (_) => Container(color: Colors.grey[900]),
                ),
              ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar with Drag Handle & Restore Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              CupertinoIcons.pin_fill,
                              color: Color(0xFF1DB954),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'G.A - Song Mini',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            CupertinoIcons.fullscreen_exit,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: () =>
                              windowManagerService.exitMacMiniPlayerMode(),
                          tooltip: 'Khôi phục cửa sổ chính (Cmd+Shift+M)',
                        ),
                      ],
                    ),

                    // Cover Art & Song Info
                    if (currentSong != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: CoverArtImage(
                            song: currentSong,
                            fallbackBuilder: (_) => const Icon(
                              Icons.music_note,
                              size: 48,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              currentSong.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist ?? 'Ca sĩ chưa rõ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                      const Icon(
                        CupertinoIcons.music_note,
                        size: 48,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa chọn bài hát',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Spacer(),
                    ],

                    // Controls Row (Shuffle, Prev, Play/Pause, Next, Repeat)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            CupertinoIcons.shuffle,
                            color: isShuffle
                                ? const Color(0xFF1DB954)
                                : Colors.white54,
                            size: 18,
                          ),
                          onPressed: () {
                            if (isShuffle) {
                              playlistService.setPlayMode(PlayMode.sequential);
                            } else {
                              playlistService.setPlayMode(PlayMode.shuffle);
                            }
                          },
                          tooltip: 'Phát ngẫu nhiên',
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            CupertinoIcons.backward_fill,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => playlistService.previous(),
                        ),
                        ValueListenableBuilder(
                          valueListenable: engineService.engineState,
                          builder: (final context, final state, _) {
                            final isPlaying = state == AudioEngineState.playing;
                            return FloatingActionButton.small(
                              elevation: 0,
                              backgroundColor: const Color(0xFF1DB954),
                              onPressed: () => isPlaying
                                  ? engineService.pause()
                                  : playlistService.play(),
                              child: Icon(
                                isPlaying
                                    ? CupertinoIcons.pause_fill
                                    : CupertinoIcons.play_fill,
                                color: Colors.black,
                                size: 20,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            CupertinoIcons.forward_fill,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => playlistService.next(),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isRepeatOne
                                ? CupertinoIcons.repeat_1
                                : CupertinoIcons.repeat,
                            color: (isRepeatOne || isRepeatAll)
                                ? const Color(0xFF1DB954)
                                : Colors.white54,
                            size: 18,
                          ),
                          onPressed: () => playlistService.nextPlayMode(),
                          tooltip: 'Chế độ lặp lại',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
