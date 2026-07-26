import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/ui/widgets/cover_art_image.dart';

void main() {
  testWidgets('CoverArtImage shows fallback when cover is missing', (
    WidgetTester tester,
  ) async {
    final repo = CoverArtRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coverArtRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: CoverArtImage(
              song: (Song(
                id: 1,
                name: 'Test',
                sourcePath: 'assets/song/missing.mp3',
                isBuiltIn: true,
              )),
              fallbackBuilder: _fallbackBuilder,
            ),
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
