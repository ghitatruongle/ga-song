import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('addPostFrameCallback fires after a frame is pumped', (tester) async {
    var fired = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fired = true;
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(fired, isTrue);
  });

  testWidgets('addPostFrameCallback runs after first frame, not before', (tester) async {
    var order = <String>[];
    order.add('before-pump');
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              order.add('post-frame');
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    order.add('after-pump');
    expect(order, ['before-pump', 'post-frame', 'after-pump']);
  });
}