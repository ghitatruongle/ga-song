import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/playlist_service.dart';
import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';

class PlayModeButton extends ConsumerWidget {
  const PlayModeButton({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Phase 2.2: play mode from state provider instead of PlayerViewModel.
    final playMode = ref.watch(playModeProvider);
    final playlist = ref.read(playlistServiceProvider);

    var icon = Icons.repeat_rounded;
    var color = context.adaptiveSecondary;

    switch (playMode) {
      case PlayMode.sequential:
        icon = Icons.repeat_rounded;
        break;
      case PlayMode.repeatOne:
        icon = Icons.repeat_one_rounded;
        color = context.adaptive;
        break;
      case PlayMode.playOneStop:
        icon = Icons.looks_one_rounded;
        break;
      case PlayMode.shuffle:
        icon = Icons.shuffle_rounded;
        color = context.adaptive;
        break;
    }

    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: playlist.nextPlayMode,
      tooltip: 'Chế độ phát',
    );
  }
}
