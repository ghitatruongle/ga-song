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
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int debounceMs;
  final SliderThemeData? sliderTheme;

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
  void didUpdateWidget(covariant DebouncedSlider oldWidget) {
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
  Widget build(BuildContext context) {
    final slider = Slider(
      value: _local.clamp(widget.min, widget.max),
      min: widget.min,
      max: widget.max,
      onChanged: (v) {
        setState(() => _local = v);
        _d.run(() => widget.onChanged(v));
      },
      onChangeEnd: (v) {
        // Flush immediately on release so final value is applied.
        _d.cancel();
        widget.onChanged(v);
      },
    );
    if (widget.sliderTheme == null) return slider;
    return SliderTheme(data: widget.sliderTheme!, child: slider);
  }
}
