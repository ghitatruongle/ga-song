import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';
import 'play_mode_button.dart';
import 'progress_bar.dart';
import 'bass_button.dart';

class CenterControls extends ConsumerWidget {
  const CenterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(playerViewModelProvider);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const PlayModeButton(),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: context.adaptive,
                      size: 32,
                    ),
                    onPressed: viewModel.previous,
                    hoverColor: context.adaptive.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.adaptive,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        viewModel.isLoading
                            ? Icons.hourglass_empty
                            : viewModel.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: context.onAdaptive,
                        size: 28,
                      ),
                      onPressed: viewModel.isLoading
                          ? null
                          : viewModel.togglePlayPause,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: context.adaptive,
                      size: 32,
                    ),
                    onPressed: viewModel.next,
                    hoverColor: context.adaptive.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 16),
                  const BassButton(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const ProgressBar(),
          ],
        );
      },
    );
  }
}
