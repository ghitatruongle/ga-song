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
    final viewModel = ref.read(playerViewModelProvider);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final volume = viewModel.volume;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
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
              onPressed: () {
                if (volume > 0) {
                  _previousVolume = volume;
                  viewModel.setVolume(0.0);
                } else {
                  viewModel.setVolume(_previousVolume > 0 ? _previousVolume : 1.0);
                }
              },
            ),
            Flexible(
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
                  onChanged: viewModel.setVolume,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
