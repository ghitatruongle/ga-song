import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../providers/service_providers.dart';
import '../utils/theme_helpers.dart';
import 'debounced_slider.dart';

class AudioEffectsDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _AudioEffectsDialog(),
    );
  }
}

class _AudioEffectsDialog extends ConsumerStatefulWidget {
  const _AudioEffectsDialog();

  @override
  ConsumerState<_AudioEffectsDialog> createState() =>
      _AudioEffectsDialogState();
}

class _AudioEffectsDialogState extends ConsumerState<_AudioEffectsDialog> {
  late final _effectService = ref.read(audioEffectServiceProvider);
  late final _settings = ref.read(settingsManagerProvider);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final bgColor = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface,
      light: Colors.white,
    );
    final spacing = ThemeSpacing.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          width: 520,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.lg + 4),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: textColor, size: 24),
                    SizedBox(width: spacing.sm + spacing.xxs),
                    Text(
                      'Audio Effects',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.md),

              // Scrollable content area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCrossfadeSection(textColor),
                      _buildDivider(textColor),
                      _buildNormalizationSection(textColor),
                      _buildDivider(textColor),
                      _buildPitchShiftSection(textColor),
                      _buildDivider(textColor),
                      _buildReverbSection(textColor),
                      _buildDivider(textColor),
                      _buildCompressionSection(textColor),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Xong',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      child: Divider(color: textColor.withValues(alpha: 0.08), height: 1),
    );
  }

  // ─── Crossfade ─────────────────────────────────────────────────────────────

  Widget _buildCrossfadeSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Crossfade',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _settings.crossfadeDurationNotifier,
              builder: (context, value, _) {
                return Text(
                  '${value.toStringAsFixed(1)}s',
                  style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pha trộn mượt giữa các bài hát',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<double>(
          valueListenable: _settings.crossfadeDurationNotifier,
          builder: (context, value, _) {
            return DebouncedSlider(
              sliderTheme: SliderThemeData(
                activeTrackColor: Theme.of(context).primaryColor,
                thumbColor: Theme.of(context).primaryColor,
              ),
              value: value,
              min: 0,
              max: 10,
              divisions: 20,
              debounceMs: 200,
              onChanged: (v) {
                _settings.setCrossfadeDuration(v);
                _effectService.setCrossfadeDuration(v);
              },
            );
          },
        ),
        // Crossfade curve selector
        ValueListenableBuilder<int>(
          valueListenable: _settings.crossfadeCurveNotifier,
          builder: (context, curveIndex, _) {
            return Row(
              children: [
                Text(
                  'Đường cong:',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Tuyến tính')),
                      ButtonSegment(value: 1, label: Text('Mũ')),
                      ButtonSegment(value: 2, label: Text('S-curve')),
                    ],
                    selected: {curveIndex},
                    onSelectionChanged: (Set<int> selected) {
                      final newIndex = selected.first;
                      _settings.setCrossfadeCurve(newIndex);
                      _effectService.crossfadeCurveNotifier.value = newIndex;
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        TextStyle(fontSize: 11, color: textColor),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── Normalization ─────────────────────────────────────────────────────────

  Widget _buildNormalizationSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Volume Normalization',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _settings.normalizationEnabledNotifier,
              builder: (context, enabled, _) {
                return Switch(
                  value: enabled,
                  activeThumbColor: Theme.of(context).primaryColor,
                  onChanged: (v) {
                    _settings.setNormalizationEnabled(v);
                    _effectService.enableNormalization(v);
                  },
                );
              },
            ),
          ],
        ),
        Text(
          'Tự động cân bằng âm lượng giữa các bài hát',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<double>(
          valueListenable: _settings.normalizationLevelNotifier,
          builder: (context, value, _) {
            return DebouncedSlider(
              sliderTheme: SliderThemeData(
                activeTrackColor: Theme.of(context).primaryColor,
                thumbColor: Theme.of(context).primaryColor,
              ),
              value: value,
              min: -24,
              max: 0,
              divisions: 24,
              label: '${value.toStringAsFixed(0)} dB',
              debounceMs: 200,
              onChanged: (v) {
                _settings.setNormalizationLevel(v);
                _effectService.setNormalizationLevel(v);
              },
            );
          },
        ),
      ],
    );
  }

  // ─── Pitch Shift ───────────────────────────────────────────────────────────

  Widget _buildPitchShiftSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pitch Shift',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _settings.pitchShiftNotifier,
              builder: (context, value, _) {
                return Text(
                  '${value.toStringAsFixed(2)}x',
                  style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                );
              },
            ),
          ],
        ),
        Text(
          'Thay đổi cao độ bài hát (0.5x thấp hơn — 2.0x cao hơn)',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<double>(
          valueListenable: _settings.pitchShiftNotifier,
          builder: (context, value, _) {
            return DebouncedSlider(
              sliderTheme: SliderThemeData(
                activeTrackColor: Theme.of(context).primaryColor,
                thumbColor: Theme.of(context).primaryColor,
              ),
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              debounceMs: 200,
              onChanged: (v) {
                _settings.setPitchShift(v);
                _effectService.setPitchShift(v);
              },
            );
          },
        ),
      ],
    );
  }

  // ─── Reverb ────────────────────────────────────────────────────────────────

  Widget _buildReverbSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reverb',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _settings.reverbMixNotifier,
              builder: (context, value, _) {
                return Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                );
              },
            ),
          ],
        ),
        Text(
          'Hiệu ứng vang âm thanh phòng thu',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),

        // Wet / Mix slider
        _buildSubParam(
          textColor: textColor,
          label: 'Mix',
          notifier: _settings.reverbMixNotifier,
          min: 0,
          max: 1,
          divisions: 20,
          format: (v) => '${(v * 100).toStringAsFixed(0)}%',
          onChanged: (v) {
            _settings.setReverbMix(v);
            _effectService.setReverbMix(v);
          },
        ),

        // Room Size slider
        _buildSubParam(
          textColor: textColor,
          label: 'Room Size',
          notifier: _settings.reverbRoomSizeNotifier,
          min: 0,
          max: 1,
          divisions: 20,
          format: (v) => '${(v * 100).toStringAsFixed(0)}%',
          onChanged: (v) {
            _settings.setReverbRoomSize(v);
            _effectService.setReverbRoomSize(v);
          },
        ),

        // Damp slider
        _buildSubParam(
          textColor: textColor,
          label: 'Damp',
          notifier: _settings.reverbDampNotifier,
          min: 0,
          max: 1,
          divisions: 20,
          format: (v) => '${(v * 100).toStringAsFixed(0)}%',
          onChanged: (v) {
            _settings.setReverbDamp(v);
            _effectService.setReverbDamp(v);
          },
        ),
      ],
    );
  }

  // ─── Compression ───────────────────────────────────────────────────────────

  Widget _buildCompressionSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compressor',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _settings.compressionRatioNotifier,
              builder: (context, value, _) {
                return Text(
                  '${value.toStringAsFixed(1)}:1',
                  style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                );
              },
            ),
          ],
        ),
        Text(
          'Nén dynamic range — âm thanh đều hơn',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),

        // Ratio
        _buildSubParam(
          textColor: textColor,
          label: 'Ratio',
          notifier: _settings.compressionRatioNotifier,
          min: 1,
          max: 10,
          divisions: 18,
          format: (v) => '${v.toStringAsFixed(1)}:1',
          onChanged: (v) {
            _settings.setCompressionRatio(v);
            _effectService.setCompressionRatio(v);
          },
        ),

        // Threshold
        _buildSubParam(
          textColor: textColor,
          label: 'Threshold',
          notifier: _settings.compThresholdNotifier,
          min: -80,
          max: 0,
          divisions: 80,
          format: (v) => '${v.toStringAsFixed(0)} dB',
          onChanged: (v) {
            _settings.setCompThreshold(v);
            _effectService.setCompThreshold(v);
          },
        ),

        // Attack
        _buildSubParam(
          textColor: textColor,
          label: 'Attack',
          notifier: _settings.compAttackNotifier,
          min: 0,
          max: 100,
          divisions: 20,
          format: (v) => '${v.toStringAsFixed(0)} ms',
          onChanged: (v) {
            _settings.setCompAttack(v);
            _effectService.setCompAttack(v);
          },
        ),

        // Release
        _buildSubParam(
          textColor: textColor,
          label: 'Release',
          notifier: _settings.compReleaseNotifier,
          min: 0,
          max: 1000,
          divisions: 20,
          format: (v) => '${v.toStringAsFixed(0)} ms',
          onChanged: (v) {
            _settings.setCompRelease(v);
            _effectService.setCompRelease(v);
          },
        ),

        // Knee Width
        _buildSubParam(
          textColor: textColor,
          label: 'Knee',
          notifier: _settings.compKneeWidthNotifier,
          min: 0,
          max: 40,
          divisions: 20,
          format: (v) => '${v.toStringAsFixed(1)} dB',
          onChanged: (v) {
            _settings.setCompKneeWidth(v);
            _effectService.setCompKneeWidth(v);
          },
        ),

        // Makeup Gain
        _buildSubParam(
          textColor: textColor,
          label: 'Makeup Gain',
          notifier: _settings.compMakeupGainNotifier,
          min: -40,
          max: 40,
          divisions: 80,
          format: (v) => '${v.toStringAsFixed(1)} dB',
          onChanged: (v) {
            _settings.setCompMakeupGain(v);
            _effectService.setCompMakeupGain(v);
          },
        ),
      ],
    );
  }

  // ─── Shared sub-parameter row ──────────────────────────────────────────────

  Widget _buildSubParam({
    required Color textColor,
    required String label,
    required ValueNotifier<double> notifier,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: notifier,
              builder: (context, value, _) {
                return DebouncedSlider(
                  sliderTheme: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: Theme.of(context).primaryColor,
                    thumbColor: Theme.of(context).primaryColor,
                  ),
                  debounceMs: 200,
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                );
              },
            ),
          ),
          SizedBox(
            width: 65,
            child: ValueListenableBuilder<double>(
              valueListenable: notifier,
              builder: (context, value, _) {
                return Text(
                  format(value),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
