import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../providers/service_providers.dart';
import '../../../providers/lyric_provider.dart';
import '../../../core/theme_utils.dart';
import '../volume_control.dart';

class RightControls extends ConsumerWidget {
  const RightControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsManager = ref.read(settingsManagerProvider);
    final pipService = ref.read(pipServiceProvider);
    final desktopLyrics = ref.read(desktopLyricsServiceProvider);
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        IconButton(
          icon: Icon(
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                ? Icons.picture_in_picture_alt_rounded
                : Icons.open_in_new_rounded,
            color: context.adaptiveSecondary,
            size: 22,
          ),
          tooltip: (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              ? 'Picture-in-Picture'
              : 'Trình phát thu nhỏ (Mini Player)',
          onPressed: () async {
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              await pipService.enterPip();
              return;
            }
            settingsManager.setIsMiniPlayer(true);
            if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
              final isMaximized = await windowManager.isMaximized();
              final isFullScreen = await windowManager.isFullScreen();
              if (isFullScreen) {
                await windowManager.setFullScreen(false);
                await Future<void>.delayed(const Duration(milliseconds: 200));
              } else if (isMaximized) {
                await windowManager.unmaximize();
                await Future<void>.delayed(const Duration(milliseconds: 100));
              }
              final currentSize = await windowManager.getSize();
              await settingsManager.setSavedWindowState(currentSize, isMaximized, isFullScreen);
              await windowManager.setMinimumSize(const Size(500, 120));
              await windowManager.setMaximumSize(const Size(500, 120));
              await windowManager.setSize(const Size(500, 120));
              await windowManager.setAlwaysOnTop(true);
            }
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final showLyrics = ref.watch(lyricVisibilityProvider);
            return IconButton(
              icon: Icon(
                Icons.mic_rounded,
                color: showLyrics ? context.adaptive : context.adaptiveSecondary,
                size: 22,
              ),
              tooltip: 'Lời bài hát (trong app)',
              onPressed: () {
                ref.read(lyricVisibilityProvider.notifier).state = !showLyrics;
              },
            );
          },
        ),
        // Desktop lyrics toggle (only on desktop platforms)
        if (isDesktop)
          ValueListenableBuilder<bool>(
            valueListenable: desktopLyrics.isVisibleNotifier,
            builder: (context, isVisible, _) {
              return IconButton(
                icon: Icon(
                  Icons.lyrics_outlined,
                  color: isVisible
                      ? Theme.of(context).colorScheme.primary
                      : context.adaptiveSecondary,
                  size: 22,
                ),
                tooltip: 'Lời bài hát nổi (Desktop)',
                onPressed: () => desktopLyrics.toggle(context),
              );
            },
          ),
        const Expanded(child: VolumeControl()),
      ],
    );
  }
}
