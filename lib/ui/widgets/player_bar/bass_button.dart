import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';
import '../equalizer_widget.dart';
import '../sleep_timer_dialog.dart';

class BassButton extends ConsumerWidget {
  const BassButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectService = ref.read(audioEffectServiceProvider);
    final playlistService = ref.read(playlistServiceProvider);
    return ValueListenableBuilder<int>(
      valueListenable: effectService.bassLevelNotifier,
      builder: (context, bassLevel, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: bassLevel > 0
                ? context.adaptive.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: bassLevel > 0
                      ? context.adaptive
                      : context.adaptiveSecondary,
                  size: 22,
                ),
                onPressed: () => EqualizerWidget.show(context),
                tooltip: 'Equalizer',
              ),
              ValueListenableBuilder<Duration?>(
                valueListenable: playlistService.sleepTimerRemainingNotifier,
                builder: (context, remaining, _) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, size: 22),
                        color: remaining != null
                            ? Theme.of(context).primaryColor
                            : context.adaptive.withValues(alpha: 0.7),
                        tooltip: 'Sleep Timer',
                        onPressed: () => SleepTimerDialog.show(context),
                      ),
                      if (remaining != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
