import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/ui/widgets/album_grid_widget.dart';

/// Helper to create a test-ready MaterialApp with AppLocalizations.
/// Uses the default locale (en) to avoid MaterialLocalizations warnings.
Widget createTestApp(final Widget child) => MaterialApp(
  localizationsDelegates: const [AppLocalizations.delegate],
  home: Builder(builder: (final context) => child),
);

void main() {
  testWidgets('AlbumGridWidget renders album names', (final tester) async {
    await tester.pumpWidget(
      createTestApp(
        AlbumGridWidget(
          albums: ['Album A', 'Album B'],
          albumSongCount: {'Album A': 5, 'Album B': 3},
          songs: [],
          onAlbumTap: (_, _) {},
        ),
      ),
    );
    await tester.pump();

    // The album names should be displayed
    expect(find.text('Album A'), findsOneWidget);
    expect(find.text('Album B'), findsOneWidget);
  });

  testWidgets('AlbumGridWidget calls onAlbumTap callback', (
    final tester,
  ) async {
    String? tappedAlbum;
    final songList = <Song>[
      Song(name: 'Song 1', sourcePath: 'assets/song/s1.mp3', album: 'Album A'),
      Song(name: 'Song 2', sourcePath: 'assets/song/s2.mp3', album: 'Album A'),
    ];

    await tester.pumpWidget(
      createTestApp(
        AlbumGridWidget(
          albums: ['Album A'],
          albumSongCount: {'Album A': 2},
          songs: songList,
          onAlbumTap: (final albumName, _) {
            tappedAlbum = albumName;
          },
        ),
      ),
    );
    await tester.pump();

    // Tap the album tile by finding the album name text
    await tester.tap(find.text('Album A'));
    await tester.pump();

    expect(tappedAlbum, 'Album A');
  });

  testWidgets('AlbumGridWidget renders empty state when no albums', (
    final tester,
  ) async {
    await tester.pumpWidget(
      createTestApp(
        AlbumGridWidget(
          albums: [],
          albumSongCount: {},
          songs: [],
          onAlbumTap: (_, _) {},
        ),
      ),
    );
    await tester.pump();

    // When albums list is empty, should show the empty state icon
    expect(find.byIcon(Icons.album_rounded), findsOneWidget);
  });
}
