import 'package:flutter/material.dart';

import '../../core/utils/debouncer.dart';

/// A slider that debounces [onChanged] events by [milliseconds].
///
/// Useful when each onChanged call is expensive (e.g. applying audio
/// effects in real time). The slider's local state immediately reflects
/// the dragged value for smooth UI, while the callback fires once per
/// pause after [milliseconds] of inactivity.
class DebouncedSlider extends StatefulWidget {
  const DebouncedSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.debounceMs = 100,
    this.sliderTheme,
    this.divisions,
    this.label,
    this.onChangeStart,
    this.onChangeEnd,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int debounceMs;
  final SliderThemeData? sliderTheme;

  /// Number of discrete divisions. Forwarded to inner [Slider].
  /// Null means continuous.
  final int? divisions;

  /// Floating label shown above thumb on drag. Forwarded to inner [Slider].
  final String? label;

  /// Optional callback fired when the user starts dragging the thumb.
  final ValueChanged<double>? onChangeStart;

  /// Optional callback fired when the user releases the thumb. The final
  /// value is always applied via [onChanged] on release — this fires in
  /// addition so callers can react to the drag lifecycle.
  final ValueChanged<double>? onChangeEnd;

  @override
  State<DebouncedSlider> createState() => _DebouncedSliderState();
}

class _DebouncedSliderState extends State<DebouncedSlider> {
  late double _local;
  late final Debouncer _d;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
    _d = Debouncer(milliseconds: widget.debounceMs);
  }

  @override
  void didUpdateWidget(covariant final DebouncedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _local) {
      _local = widget.value;
    }
  }

  @override
  void dispose() {
    _d.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final slider = Slider(
      value: _local.clamp(widget.min, widget.max),
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label,
      onChanged: (final v) {
        setState(() => _local = v);
        _d.run(() => widget.onChanged(v));
      },
      onChangeStart: widget.onChangeStart,
      onChangeEnd: (final v) {
        // Flush immediately on release so final value is applied.
        _d.cancel();
        widget.onChanged(v);
        widget.onChangeEnd?.call(v);
      },
    );
    if (widget.sliderTheme == null) return slider;
    return SliderTheme(data: widget.sliderTheme!, child: slider);
  }
}
