import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';

/// Premium equalizer dialog with 5-band control and preset selector
class EqualizerWidget {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _EqualizerDialog(),
    );
  }
}

class _EqualizerDialog extends ConsumerStatefulWidget {
  const _EqualizerDialog();

  @override
  ConsumerState<_EqualizerDialog> createState() => _EqualizerDialogState();
}

class _EqualizerDialogState extends ConsumerState<_EqualizerDialog> {
  late final _effectService = ref.read(audioEffectServiceProvider);
  late final _settings = ref.read(settingsManagerProvider);

  // Band labels
  static const _bandLabels = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
  static const _bandIcons = [
    Icons.waves_rounded, // Sub bass
    Icons.graphic_eq_rounded, // Bass
    Icons.equalizer_rounded, // Mid
    Icons.surround_sound_rounded, // Upper mid
    Icons.auto_awesome_rounded, // Treble
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;
    final bgColor = context.isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: textColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Bộ chỉnh âm (Equalizer)',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        _settings.applyEqPreset('Normal');
                        _effectService.applyAllEqualizer(_settings.eqBandsNotifier.value);
                        _effectService.setBassLevel(_settings.eqBassNotifier.value);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      color: textColor.withValues(alpha: 0.7),
                      tooltip: 'Đặt lại (Reset)',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preset chips
                _buildPresetSelector(textColor),
                const SizedBox(height: 24),

                // 5-band EQ sliders
                SizedBox(
                  height: 220,
                  child: ValueListenableBuilder<List<double>>(
                    valueListenable: _settings.eqBandsNotifier,
                    builder: (context, bands, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) {
                          return _buildBandSlider(
                            label: _bandLabels[i],
                            icon: _bandIcons[i],
                            value: bands[i],
                            textColor: textColor,
                            onChanged: (val) {
                              _settings.setEqBand(i, val);
                              _effectService.applyAllEqualizer(
                                _settings.eqBandsNotifier.value,
                              );
                            },
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Bass Boost (existing feature, integrated here)
                _buildBassBoostRow(textColor),
                const SizedBox(height: 20),

                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Xong',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetSelector(Color textColor) {
    return ValueListenableBuilder<String>(
      valueListenable: _settings.eqPresetNotifier,
      builder: (context, currentPreset, _) {
        final presets = ['Normal', 'Bass+', 'Vocal', 'Acoustic', 'Custom'];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((preset) {
              final isSelected = currentPreset == preset;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    preset,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : textColor.withValues(alpha: 0.8),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: textColor.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) {
                    _settings.applyEqPreset(preset);
                    // Apply all bands atomically
                    _effectService.applyAllEqualizer(
                      _settings.eqBandsNotifier.value,
                    );
                    // Also apply bass level from preset
                    _effectService.setBassLevel(_settings.eqBassNotifier.value);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBandSlider({
    required String label,
    required IconData icon,
    required double value,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    // Map -1..1 to display: -12dB to +12dB
    final displayDb = (value * 12).round();
    final isActive = value.abs() > 0.05;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${displayDb > 0 ? '+' : ''}${displayDb}dB',
          style: TextStyle(
            color: isActive ? textColor : textColor.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          width: 40,
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: isActive
                    ? Theme.of(context).primaryColor
                    : textColor.withValues(alpha: 0.3),
                inactiveTrackColor: textColor.withValues(alpha: 0.1),
                thumbColor: isActive
                    ? Theme.of(context).primaryColor
                    : textColor.withValues(alpha: 0.5),
              ),
              child: Slider(
                value: value,
                min: -1.0,
                max: 1.0,
                onChanged: (v) {
                  // Snap to zero near center
                  if (v.abs() < 0.05) v = 0.0;
                  onChanged(v);
                  // Mark as custom preset
                  _settings.eqPresetNotifier.value = 'Custom';
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, color: textColor.withValues(alpha: 0.6), size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBassBoostRow(Color textColor) {
    return ValueListenableBuilder<int>(
      valueListenable: _settings.eqBassNotifier,
      builder: (context, bassLevel, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
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
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: textColor,
                    inactiveTrackColor: textColor.withValues(alpha: 0.15),
                    thumbColor: textColor,
                  ),
                  child: Slider(
                    value: bassLevel.toDouble(),
                    min: 0,
                    max: 100,
                    onChanged: (val) {
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
        );
      },
    );
  }
}
