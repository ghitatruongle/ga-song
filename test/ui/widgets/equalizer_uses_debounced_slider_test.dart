import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/widgets/debounced_slider.dart';

void main() {
  testWidgets('DebouncedSlider accepts a value, onChanged, debounceMs', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebouncedSlider(
            value: 0.5,
            min: 0,
            max: 1,
            debounceMs: 50,
            onChanged: (_) {
              calls++;
            },
          ),
        ),
      ),
    );

    expect(find.byType(DebouncedSlider), findsOneWidget);
    // Smoke test: widget inflates with our callback registered.
    expect(calls, 0);
  });
}
