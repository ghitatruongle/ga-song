import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:ga_song/ui/widgets/album_grid_widget.dart';

/// Helper to create a test-ready MaterialApp with AppLocalizations.
Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
    ],
    home: Builder(builder: (context) => child),
  );
}

void main() {
  // Phase 4 device-debug regression: on a 720-physical-px / DPR 1.75
  // phone in portrait with sidebar visible, the album grid is only
  // ~191 logical px wide (411 device width - 220 sidebar = 191).  After
  // the 40+40 inner padding, each tile is ~111 px tall.  The current
  // Phase-4 fix uses Column(mainAxisSize.min) + Flexible(loose-fit),
  // which silently collapses the 2-line title to a single line — the
  // fontSize-18 title wants 44 px for 2 lines but only ~25 px remain
  // after the icon + spacings + songCount text.
  //
  // These tests pin two contracts:
  //   1. The layout must not throw a RenderFlex overflow exception.
  //   2. A long album name must actually render on TWO lines
  //      (>= 36 logical px tall) so the user sees the full title.
  group('AlbumGridWidget overflow regression', () {
    testWidgets(
      'no overflow exception at device-realistic narrow viewport (191 wide)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(191, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp(
          SizedBox(
            width: 191, // 411 device width − 220 sidebar
            height: 700,
            child: AlbumGridWidget(
              albums: const ['Mắt Nhắm Mắt Mở', 'Chưa phân loại'],
              albumSongCount: const {
                'Mắt Nhắm Mắt Mở': 13,
                'Chưa phân loại': 20,
              },
              songs: const [],
              onAlbumTap: (_, _) {},
            ),
          ),
        ));
        await tester.pump();

        // Contract 1: no RenderFlex overflow during this build.
        expect(tester.takeException(), isNull,
            reason: 'Album grid must not overflow at narrow viewport');
      },
    );

    testWidgets(
      'long album name renders on 2 lines (full title visible)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(191, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp(
          SizedBox(
            width: 191,
            height: 700,
            child: AlbumGridWidget(
              albums: const ['Mắt Nhắm Mắt Mở'],
              albumSongCount: const {'Mắt Nhắm Mắt Mở': 13},
              songs: const [],
              onAlbumTap: (_, _) {},
            ),
          ),
        ));
        await tester.pump();

        // Contract 2: the rendered title must be 2 lines tall.
        // fontSize 18 → line-height ~22 logical px → 2 lines ~44 px.
        // We assert >= 36 px to leave a small slack for font metrics.
        final titleFinder = find.byWidgetPredicate((w) {
          if (w is! Text) return false;
          return w.data == 'Mắt Nhắm Mắt Mở';
        });
        expect(titleFinder, findsOneWidget,
            reason: 'Full album name Text widget must exist');

        final renderParagraph =
            tester.renderObject<RenderParagraph>(titleFinder);
        final titleHeight = renderParagraph.size.height;
        expect(
          titleHeight,
          greaterThanOrEqualTo(36.0),
          reason:
              'Album title must render 2 lines (>= 36 px) at narrow viewport; '
              'got ${titleHeight.toStringAsFixed(2)} px — title silently '
              'collapsed to 1 line.',
        );
      },
    );
  });
}