import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/core/service_locator.dart';
import 'package:ga_song/ui/widgets/cover_art_image.dart';

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<CoverArtRepository>(
      () => CoverArtRepository(),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('CoverArtImage shows fallback when cover is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverArtImage(
            fileName: 'missing.mp3',
            fallbackBuilder: _fallbackBuilder,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('fallback'), findsOneWidget);
  });
}

Widget _fallbackBuilder(BuildContext context) {
  return const Text('fallback');
}
