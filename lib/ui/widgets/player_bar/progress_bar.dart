import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../core/theme_utils.dart';
import '../../../core/utils/time_utils.dart';

class ProgressBar extends ConsumerWidget {
  const ProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 2.2: read position/duration from state providers (was PlayerViewModel).
    final position = ref.watch(positionProvider);
    final duration = ref.watch(trackDurationProvider);
    final engine = ref.read(audioEngineServiceProvider);
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 36,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatDuration(position),
              style: TextStyle(
                color: context.adaptive.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 12,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 10,
                ),
                activeTrackColor: context.adaptive,
                inactiveTrackColor: context.adaptive.withValues(alpha: 0.2),
                thumbColor: context.adaptive,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).round(),
                  );
                  engine.seek(newPosition);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatDuration(duration),
              style: TextStyle(
                color: context.adaptive.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
