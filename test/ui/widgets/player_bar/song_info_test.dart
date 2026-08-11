import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/ui/widgets/player_bar/song_info.dart';

void main() {
  testWidgets('SongInfo displays song name and artist', (final tester) async {
    final song = Song(
      id: 1,
      name: 'Test Song',
      artist: 'Test Artist',
      sourcePath: 'test.mp3',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverArtRepositoryProvider.overrideWithValue(CoverArtRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(body: SongInfo(song: song)),
        ),
      ),
    );

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
  });

  testWidgets('SongInfo shows Unknown Artist when artist is null', (
    final tester,
  ) async {
    final song = Song(id: 2, name: 'No Artist Song', sourcePath: 'test2.mp3');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverArtRepositoryProvider.overrideWithValue(CoverArtRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(body: SongInfo(song: song)),
        ),
      ),
    );

    expect(find.text('No Artist Song'), findsOneWidget);
    expect(find.text('Unknown Artist'), findsOneWidget);
  });
}
