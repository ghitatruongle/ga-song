import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';
import '../../../core/audio/audio_engine_service.dart';
import '../../utils/haptic_helper.dart';
import 'play_mode_button.dart';
import 'progress_bar.dart';
import 'bass_button.dart';

class CenterControls extends ConsumerWidget {
  const CenterControls({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Phase 2.2: use state providers directly (was PlayerViewModel).
    final engineState = ref.watch(engineStateProvider);
    final playlist = ref.read(playlistServiceProvider);
    // `soundOn` is only consulted inside onPressed callbacks; use
    // ref.read (not ref.watch) so the whole CenterControls subtree
    // doesn't rebuild on every toggle.
    final soundOn = ref.watch(
      settingsNotifierProvider.select((final s) => s.soundFeedbackEnabled),
    );
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
                onPressed: () {
                  safeHaptic(HapticType.light);
                  if (soundOn) {
                    SystemSound.play(SystemSoundType.click);
                  }
                  playlist.previous();
                },
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
                  onPressed: isLoading
                      ? null
                      : () {
                          safeHaptic(HapticType.medium);
                          // Toggle: pause if playing (play() would RESTART).
                          if (engineState == AudioEngineState.playing) {
                            ref.read(audioEngineServiceProvider).pause();
                          } else {
                            playlist.play();
                          }
                        },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: context.adaptive,
                  size: 32,
                ),
                onPressed: () {
                  safeHaptic(HapticType.light);
                  if (soundOn) {
                    SystemSound.play(SystemSoundType.click);
                  }
                  playlist.next();
                },
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
