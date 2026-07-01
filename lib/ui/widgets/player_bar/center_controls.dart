import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';
import '../../../core/audio/audio_engine_service.dart';
import 'play_mode_button.dart';
import 'progress_bar.dart';
import 'bass_button.dart';

class CenterControls extends ConsumerWidget {
  const CenterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 2.2: use state providers directly (was PlayerViewModel).
    final engineState = ref.watch(engineStateProvider);
    final playlist = ref.read(playlistServiceProvider);
    final isPlaying = engineState == AudioEngineState.playing;
    final isLoading = engineState == AudioEngineState.loading;
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
                onPressed: playlist.previous,
                hoverColor: context.adaptive.withValues(alpha: 0.1),
                tooltip: 'Bài trước',
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
                    isLoading
                        ? Icons.hourglass_empty
                        : isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    color: context.onAdaptive,
                    size: 28,
                  ),
                  onPressed: isLoading ? null : playlist.play,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: context.adaptive,
                  size: 32,
                ),
                onPressed: playlist.next,
                hoverColor: context.adaptive.withValues(alpha: 0.1),
                tooltip: 'Bài tiếp theo',
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
  }
}
