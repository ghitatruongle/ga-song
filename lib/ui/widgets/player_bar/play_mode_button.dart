import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/playlist_service.dart';
import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';

class PlayModeButton extends ConsumerWidget {
  const PlayModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(playerViewModelProvider);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final playMode = viewModel.playMode;

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
          onPressed: viewModel.togglePlayMode,
          tooltip: 'Chế độ phát',
        );
      },
    );
  }
}
