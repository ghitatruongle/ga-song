import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_effect_service.dart';
import '../../core/settings_manager.dart';
import '../../providers/service_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../core/motion/app_motion.dart';
import '../utils/animation_utils.dart';
import '../utils/haptic_helper.dart';
import 'debounced_slider.dart';

/// Premium equalizer dialog with 5-band control and preset selector
class EqualizerWidget {
  static void show(final BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (final context) => const _EqualizerDialog(),
    );
  }
}

class _EqualizerDialog extends ConsumerStatefulWidget {
  const _EqualizerDialog();

  @override
  ConsumerState<_EqualizerDialog> createState() => _EqualizerDialogState();
}

class _EqualizerDialogState extends ConsumerState<_EqualizerDialog> {
  late SettingsManager _settings;
  late AudioEffectService _effectService;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(settingsManagerProvider);
    _effectService = ref.read(audioEffectServiceProvider);
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDark;
    final textColor = context.adaptive;
    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.tune_rounded, color: textColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Equalizer',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Preset selector — subscribes to eqPresetNotifier so the
            // selected chip updates when `eqPreset = 'Custom'` is set.
            ValueListenableBuilder<String>(
              valueListenable: _settings.eqPresetNotifier,
              builder: (final context, _, _) => _buildPresetSelector(textColor),
            ),
            const SizedBox(height: 20),

            // 5-band sliders — subscribe to eqBandsNotifier so each band's
            // dB readout and active-color flip live during drag.
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<List<double>>(
                valueListenable: _settings.eqBandsNotifier,
                builder: (final context, final bands, _) {
                  Widget band(
                    final int i,
                    final String label,
                    final IconData icon,
                  ) => _buildBandSlider(
                    label: label,
                    icon: icon,
                    value: bands[i],
                    textColor: textColor,
                    onChanged: (final v) {
                      _settings.setEqBand(i, v);
                    },
                  );
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      band(0, '60Hz', Icons.graphic_eq_rounded),
                      band(1, '230Hz', Icons.equalizer_rounded),
                      band(2, '910Hz', Icons.bar_chart_rounded),
                      band(3, '3.6kHz', Icons.waves_rounded),
                      band(4, '14kHz', Icons.surround_sound_rounded),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Bass Boost
            _buildBassBoostRow(textColor),
            const SizedBox(height: 8),

            // Reset
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _settings.applyEqPreset('Normal');
                  for (var i = 0; i < 5; i++) {
                    _settings.setEqBand(i, 0);
                  }
                  _effectService.setBassLevel(0);
                },
                icon: Icon(
                  Icons.restart_alt_rounded,
                  color: textColor.withValues(alpha: 0.7),
                  size: 18,
                ),
                label: Text('Đặt lại', style: TextStyle(color: textColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector(final Color textColor) {
    const presets = [
      'Normal',
      'Pop',
      'Rock',
      'Jazz',
      'Classical',
      'Bass Boost',
      'Vocal',
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (final context, final i) {
          final p = presets[i];
          final selected = _settings.eqPresetNotifier.value == p;
          return ChoiceChip(
            label: Text(p),
            selected: selected,
            onSelected: (_) {
              _settings.applyEqPreset(p);
            },
          );
        },
      ),
    );
  }

  Widget _buildBandSlider({
    required final String label,
    required final IconData icon,
    required final double value,
    required final Color textColor,
    required final ValueChanged<double> onChanged,
  }) {
    final isActive = value.abs() > 0.05;
    return _BandSliderWidget(
      key: ValueKey(label),
      value: value,
      textColor: textColor,
      isActive: isActive,
      label: label,
      icon: icon,
      onChanged: (v) {
        if (v.abs() < 0.05) v = 0.0;
        onChanged(v);
        _settings.eqPresetNotifier.value = 'Custom';
      },
    );
  }

  Widget _buildBassBoostRow(
    final Color textColor,
  ) => ValueListenableBuilder<int>(
    valueListenable: _settings.eqBassNotifier,
    builder: (final context, final bassLevel, _) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speaker_rounded,
            color: textColor.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Bass Boost',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 140,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: textColor,
                inactiveTrackColor: textColor.withValues(alpha: 0.15),
                thumbColor: textColor,
              ),
              child: DebouncedSlider(
                value: bassLevel.toDouble(),
                max: 100,
                debounceMs: 250,
                onChanged: (final val) {
                  final level = val.round();
                  _settings.setEqBass(level);
                  _effectService.setBassLevel(level);
                  _settings.eqPresetNotifier.value = 'Custom';
                },
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$bassLevel%',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Phase 4 Task 8: per-band slider that glows while dragging.
class _BandSliderWidget extends StatefulWidget {
  const _BandSliderWidget({
    super.key,
    required this.value,
    required this.textColor,
    required this.isActive,
    required this.label,
    required this.icon,
    required this.onChanged,
  });
  final double value;
  final Color textColor;
  final bool isActive;
  final String label;
  final IconData icon;
  final ValueChanged<double> onChanged;

  @override
  State<_BandSliderWidget> createState() => _BandSliderWidgetState();
}

class _BandSliderWidgetState extends State<_BandSliderWidget> {
  bool _isDragging = false;

  @override
  Widget build(final BuildContext context) {
    final animations = animationsEnabled(context);
    final displayDb = (widget.value * 12).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${displayDb > 0 ? '+' : ''}${displayDb}dB',
          style: TextStyle(
            color: widget.isActive
                ? widget.textColor
                : widget.textColor.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: animations ? AppDurations.short : Duration.zero,
          curve: AppCurves.decelerate,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.textColor.withValues(
                  alpha: _isDragging && animations ? 0.4 : 0.0,
                ),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SizedBox(
            height: 130,
            width: 40,
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: widget.isActive
                      ? Theme.of(context).primaryColor
                      : widget.textColor.withValues(alpha: 0.3),
                  inactiveTrackColor: widget.textColor.withValues(alpha: 0.1),
                  thumbColor: widget.isActive
                      ? Theme.of(context).primaryColor
                      : widget.textColor.withValues(alpha: 0.5),
                ),
                child: DebouncedSlider(
                  value: widget.value,
                  min: -1,
                  debounceMs: 250,
                  onChanged: (final v) {
                    setState(() => _isDragging = true);
                    widget.onChanged(v);
                  },
                  onChangeEnd: (_) {
                    setState(() => _isDragging = false);
                    safeHaptic(HapticType.light);
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          widget.icon,
          color: widget.textColor.withValues(alpha: 0.6),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.textColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
