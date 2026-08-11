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
  double _previousVolume = 1;

  @override
  Widget build(final BuildContext context) {
    // Phase 2.2: read volume from state provider, set via engine service.
    final volume = ref.watch(volumeProvider);
    final engine = ref.read(audioEngineServiceProvider);

    return LayoutBuilder(
      builder: (final context, final constraints) {
        if (constraints.maxWidth < 36) {
          return const SizedBox.shrink();
        }
        final showSlider = constraints.maxWidth >= 80;
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: () {
                if (volume > 0) {
                  _previousVolume = volume;
                  engine.setVolume(0);
                } else {
                  engine.setVolume(_previousVolume > 0 ? _previousVolume : 1.0);
                }
              },
            ),
            if (showSlider)
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
                  child: Slider(value: volume, onChanged: engine.setVolume),
                ),
              ),
          ],
        );
      },
    );
  }
}
