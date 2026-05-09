import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/service_locator.dart';
import 'package:ga_song/main.dart';

void main() {
  setUp(() async {
    await sl.reset();
    setupServiceLocator();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('GASongApp builds MaterialApp shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GASongApp(
        home: Scaffold(body: Center(child: Text('Smoke Home'))),
      ),
    );

    expect(find.text('Smoke Home'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'G.A - Song');
  });
}
