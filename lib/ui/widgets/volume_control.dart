import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';

class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({super.key});

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  double _previousVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    // Phase 2.2: read volume from state provider, set via engine service.
    final volume = ref.watch(volumeProvider);
    final engine = ref.read(audioEngineServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            volume == 0
                ? Icons.volume_off_rounded
                : volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
            color: context.adaptiveSecondary,
            size: 22,
          ),
          // Match right_controls.dart: keep volume button compact so the
          // slider gets the leftover width on narrow mobile breakpoints.
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          onPressed: () {
            if (volume > 0) {
              _previousVolume = volume;
              engine.setVolume(0.0);
            } else {
              engine.setVolume(_previousVolume > 0 ? _previousVolume : 1.0);
            }
          },
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 5,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 10,
              ),
              activeTrackColor: context.adaptive,
              inactiveTrackColor: context.adaptive.withValues(alpha: 0.2),
              thumbColor: context.adaptive,
            ),
            child: Slider(
              value: volume,
              onChanged: engine.setVolume,
            ),
          ),
        ),
      ],
    );
  }
}
