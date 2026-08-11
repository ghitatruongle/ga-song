import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/widgets/debounced_slider.dart';

void main() {
  testWidgets('DebouncedSlider passes divisions through to underlying Slider', (
    final tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebouncedSlider(value: 0.5, divisions: 10, onChanged: (_) {}),
        ),
      ),
    );
    // Find the inner Slider to verify divisions reaches it.
    final inner = tester.widget<Slider>(find.byType(Slider));
    expect(inner.divisions, 10);
  });

  testWidgets('DebouncedSlider passes label through to underlying Slider', (
    final tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebouncedSlider(
            value: -12,
            min: -24,
            max: 0,
            label: '-12 dB',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final inner = tester.widget<Slider>(find.byType(Slider));
    expect(inner.label, '-12 dB');
  });
}
