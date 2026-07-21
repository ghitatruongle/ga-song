import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/widgets/debounced_slider.dart';

void main() {
  testWidgets('DebouncedSlider passes divisions through to underlying Slider', (tester) async {
    var lastValue = 0.0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DebouncedSlider(
          value: 0.5,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (v) => lastValue = v,
        ),
      ),
    ));
    // Find the inner Slider to verify divisions reaches it.
    final inner = tester.widget<Slider>(find.byType(Slider));
    expect(inner.divisions, 10);
  });

  testWidgets('DebouncedSlider passes label through to underlying Slider', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DebouncedSlider(
          value: -12.0,
          min: -24.0,
          max: 0.0,
          label: '-12 dB',
          onChanged: (_) {},
        ),
      ),
    ));
    final inner = tester.widget<Slider>(find.byType(Slider));
    expect(inner.label, '-12 dB');
  });
}
