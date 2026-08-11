/// Tests for PlaylistImportExportService
///
/// Tests cover M3U, PLS, XSPF, and JSON import/export with round-trip validation.
library;

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/services/playlist_import_export_service.dart';
import 'package:ga_song/models/song.dart';

void main() {
  group('PlaylistImportExportService', () {
    // ─── M3U Tests ────────────────────────────────────────────────────────────

    group('M3U Import/Export', () {
      const m3uContent = '''#EXTM3U
#PLAYLIST:Test Playlist
#EXTINF:180,Test Song - Test Artist
assets/song/test.mp3
#EXTINF:240,Another Song - Another Artist
assets/song/another.mp3
#EXTALB:Test Album
#EXTINF:200,Third Song - Third Artist
assets/song/third.mp3
''';

      test('imports basic M3U playlist', () async {
        final service = PlaylistImportExportService();
        final result = await service.importFromString(
          m3uContent,
          format: PlaylistFormat.m3u,
        );

        expect(result.success, isTrue);
        expect(result.playlistName, 'Test Playlist');
        expect(result.entries.length, 3);
        expect(result.entries[0].title, 'Test Song');
        expect(result.entries[0].artist, 'Test Artist');
        expect(result.entries[0].durationSeconds, 180);
        expect(result.entries[0].sourcePath, 'assets/song/test.mp3');
      });

      test('handles missing EXTINF gracefully', () async {
        const m3uNoExtinf = '''#EXTM3U
assets/song/test.mp3
''';

        final service = PlaylistImportExportService();
        final result = await service.importFromString(
          m3uNoExtinf,
          format: PlaylistFormat.m3u,
        );

        expect(result.success, isTrue);
        expect(result.entries.length, 1);
        expect(result.entries[0].title, 'test');
      });

      test('exports M3U with correct format', () async {
        final songs = [
          Song(
            id: 1,
            name: 'Test Song',
            artist: 'Test Artist',
            album: 'Test Album',
            durationMs: 180000,
            sourcePath: 'assets/song/test.mp3',
            isBuiltIn: true,
          ),
          Song(
            id: 2,
            name: 'Another Song',
            artist: 'Another Artist',
            durationMs: 240000,
            sourcePath: 'assets/song/another.mp3',
            isBuiltIn: true,
          ),
        ];

        final service = PlaylistImportExportService();
        final result = await service.exportToString(
          songs,
          'Test Playlist',
          format: PlaylistFormat.m3u,
        );

        expect(result.success, isTrue);
        expect(result.content, contains('#EXTM3U'));
        expect(result.content, contains('#PLAYLIST:Test Playlist'));
        expect(result.content, contains('#EXTINF:180,Test Song - Test Artist'));
        expect(result.content, contains('assets/song/test.mp3'));
        expect(result.content, contains('#EXTALB:Test Album'));
      });

      test('round-trip M3U import/export', () async {
        const originalM3U = '''#EXTM3U
#PLAYLIST:Round Trip Test
#EXTINF:180,Song One - Artist One
assets/song/one.mp3
#EXTINF:240,Song Two - Artist Two
assets/song/two.mp3
''';

        final service = PlaylistImportExportService();

        // Import
        final importResult = await service.importFromString(
          originalM3U,
          format: PlaylistFormat.m3u,
        );
        expect(importResult.success, isTrue);
        expect(importResult.entries.length, 2);

        // Export back
        final songs = [
          Song(
            id: 1,
            name: 'Song One',
            artist: 'Artist One',
            durationMs: 180000,
            sourcePath: 'assets/song/one.mp3',
            isBuiltIn: true,
          ),
          Song(
            id: 2,
            name: 'Song Two',
            artist: 'Artist Two',
            durationMs: 240000,
            sourcePath: 'assets/song/two.mp3',
            isBuiltIn: true,
          ),
        ];

        final exportResult = await service.exportToString(
          songs,
          'Round Trip Test',
          format: PlaylistFormat.m3u,
        );
        expect(exportResult.success, isTrue);

        // Re-import
        final reimportResult = await service.importFromString(
          exportResult.content!,
          format: PlaylistFormat.m3u,
        );
        expect(reimportResult.success, isTrue);
        expect(reimportResult.entries.length, 2);
      });
    });

    // ─── PLS Tests ─────────────────────────────────────────────────────────────

    group('PLS Import/Export', () {
      const plsContent = '''[playlist]
Title=PLS Test Playlist
NumberOfEntries=2
File1=assets/song/one.mp3
Title1=Song One
Artist1=Artist One
Length1=180
File2=assets/song/two.mp3
Title2=Song Two
Artist2=Artist Two
Length2=240
Version=2
''';

      test('imports PLS playlist', () async {
        final service = PlaylistImportExportService();
        final result = await service.importFromString(
          plsContent,
          format: PlaylistFormat.pls,
        );

        expect(result.success, isTrue);
        expect(result.playlistName, 'PLS Test Playlist');
        expect(result.entries.length, 2);
        expect(result.entries[0].title, 'Song One');
        expect(result.entries[0].artist, 'Artist One');
        expect(result.entries[0].durationSeconds, 180);
        expect(result.entries[0].sourcePath, 'assets/song/one.mp3');
      });

      test('exports PLS with correct format', () async {
        final songs = [
          Song(
            id: 1,
            name: 'Song One',
            artist: 'Artist One',
            durationMs: 180000,
            sourcePath: 'assets/song/one.mp3',
            isBuiltIn: true,
          ),
          Song(
            id: 2,
            name: 'Song Two',
            artist: 'Artist Two',
            durationMs: 240000,
            sourcePath: 'assets/song/two.mp3',
            isBuiltIn: true,
          ),
        ];

        final service = PlaylistImportExportService();
        const playlistName = 'PLS Export Test';

        final result = await service.exportToString(
          songs,
          playlistName,
          format: PlaylistFormat.pls,
        );

        expect(result.success, isTrue);
        expect(result.content, contains('[playlist]'));
        expect(result.content, contains('Title=PLS Export Test'));
        expect(result.content, contains('NumberOfEntries=2'));
        expect(result.content, contains('File1=assets/song/one.mp3'));
        expect(result.content, contains('Title1=Song One'));
        expect(result.content, contains('Artist1=Artist One'));
        expect(result.content, contains('Length1=180'));
        expect(result.content, contains('Version=2'));
      });
    });

    // ─── XSPF Tests ─────────────────────────────────────────────────────────────

    group('XSPF Import/Export', () {
      const xspfContent = '''<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title>XSPF Test Playlist</title>
  <trackList>
    <track>
      <title>XSPF Song One</title>
      <creator>Artist One</creator>
      <album>Album One</album>
      <location>assets/song/one.mp3</location>
      <duration>180000</duration>
    </track>
    <track>
      <title>XSPF Song Two</title>
      <creator>Artist Two</creator>
      <location>assets/song/two.mp3</location>
      <duration>240000</duration>
    </track>
  </trackList>
</playlist>
''';

      test('imports XSPF playlist', () async {
        final service = PlaylistImportExportService();
        final result = await service.importFromString(
          xspfContent,
          format: PlaylistFormat.xspf,
        );

        expect(result.success, isTrue);
        expect(result.playlistName, 'XSPF Test Playlist');
        expect(result.entries.length, 2);
        expect(result.entries[0].title, 'XSPF Song One');
        expect(result.entries[0].artist, 'Artist One');
        expect(result.entries[0].album, 'Album One');
        expect(result.entries[0].sourcePath, 'assets/song/one.mp3');
        expect(result.entries[0].durationSeconds, 180);
      });

      test('exports XSPF with correct XML format', () async {
        final songs = [
          Song(
            id: 1,
            name: 'XSPF Song',
            artist: 'XSPF Artist',
            album: 'XSPF Album',
            durationMs: 180000,
            sourcePath: 'assets/song/xspf.mp3',
            isBuiltIn: true,
          ),
        ];

        final service = PlaylistImportExportService();
        const playlistName = 'XSPF Export Test';

        final result = await service.exportToString(
          songs,
          playlistName,
          format: PlaylistFormat.xspf,
        );

        expect(result.success, isTrue);
        expect(
          result.content,
          contains('<?xml version="1.0" encoding="UTF-8"?>'),
        );
        expect(
          result.content,
          contains('<playlist version="1" xmlns="http://xspf.org/ns/0/">'),
        );
        expect(result.content, contains('<title>XSPF Export Test</title>'));
        expect(result.content, contains('<track>'));
        expect(result.content, contains('<title>XSPF Song</title>'));
        expect(result.content, contains('<creator>XSPF Artist</creator>'));
        expect(result.content, contains('<album>XSPF Album</album>'));
        expect(
          result.content,
          contains('<location>assets/song/xspf.mp3</location>'),
        );
        expect(result.content, contains('<duration>180000</duration>'));
        expect(result.content, contains('</track>'));
        expect(result.content, contains('</trackList>'));
        expect(result.content, contains('</playlist>'));
      });

      test('handles special XML characters in export', () async {
        final songs = [
          Song(
            id: 1,
            name: 'Song & "Test"',
            artist: 'Artist <Test>',
            album: 'Album >Test',
            durationMs: 180000,
            sourcePath: 'assets/song/test.mp3',
            isBuiltIn: true,
          ),
        ];

        final service = PlaylistImportExportService();
        const playlistName = 'Special Chars Test';

        final result = await service.exportToString(
          songs,
          playlistName,
          format: PlaylistFormat.xspf,
        );

        expect(result.success, isTrue);
        expect(result.content, contains('Song & "Test"'));
        expect(result.content, contains('Artist <Test>'));
        expect(result.content, contains('Album >Test'));
      });
    });

    // ─── JSON Tests ─────────────────────────────────────────────────────────────

    group('JSON Import/Export', () {
      test('imports JSON playlist', () async {
        const jsonContent = '''{
  "name": "JSON Playlist",
  "songIds": [1, 2, 3],
  "songs": [
    {"id": 1, "name": "Song One", "artist": "Artist One", "durationMs": 180000, "sourcePath": "assets/song/one.mp3", "isBuiltIn": true},
    {"id": 2, "name": "Song Two", "artist": "Artist Two", "durationMs": 240000, "sourcePath": "assets/song/two.mp3", "isBuiltIn": true}
  ],
  "exportedAt": "2024-01-01T00:00:00.000Z",
  "format": "ga-song-playlist",
  "version": 1
}''';

        final service = PlaylistImportExportService();
        final result = await service.importFromString(
          jsonContent,
          format: PlaylistFormat.json,
        );

        expect(result.success, isTrue);
        expect(result.playlistName, 'JSON Playlist');
        expect(result.entries.length, 2);
      });

      test('exports full JSON with all song data', () async {
        final songs = [
          Song(
            id: 1,
            name: 'JSON Song',
            artist: 'JSON Artist',
            album: 'JSON Album',
            durationMs: 180000,
            sourcePath: 'assets/song/json.mp3',
            isBuiltIn: true,
            playCount: 5,
            genre: 'Pop',
            year: 2024,
          ),
        ];

        final service = PlaylistImportExportService();
        const playlistName = 'JSON Export Test';

        final result = await service.exportToString(
          songs,
          playlistName,
          format: PlaylistFormat.json,
        );

        expect(result.success, isTrue);
        final json = jsonDecode(result.content!);
        expect(json['name'], 'JSON Export Test');
        expect(json['songIds'], [1]);
        expect(json['songs'].length, 1);
        expect(json['songs'][0]['name'], 'JSON Song');
        expect(json['songs'][0]['playCount'], 5);
        expect(json['songs'][0]['genre'], 'Pop');
        expect(json['songs'][0]['year'], 2024);
        expect(json['format'], 'ga-song-playlist');
        expect(json['version'], 1);
      });
    });

    // ─── Format Detection ──────────────────────────────────────────────────────

    group('Format Detection', () {
      test('detects M3U from extension', () {
        expect(detectPlaylistFormat('playlist.m3u'), PlaylistFormat.m3u);
        expect(detectPlaylistFormat('playlist.m3u8'), PlaylistFormat.m3u);
      });

      test('detects PLS from extension', () {
        expect(detectPlaylistFormat('playlist.pls'), PlaylistFormat.pls);
      });

      test('detects XSPF from extension', () {
        expect(detectPlaylistFormat('playlist.xspf'), PlaylistFormat.xspf);
      });

      test('detects JSON from extension', () {
        expect(detectPlaylistFormat('playlist.json'), PlaylistFormat.json);
      });

      test('detects M3U from content', () {
        const m3uContent = '#EXTM3U\n#EXTINF:180,Song\nfile.mp3';
        expect(
          detectPlaylistFormat('unknown.txt', content: m3uContent),
          PlaylistFormat.m3u,
        );
      });

      test('detects PLS from content', () {
        const plsContent = '[playlist]\nFile1=file.mp3\nTitle1=Song';
        expect(
          detectPlaylistFormat('unknown.txt', content: plsContent),
          PlaylistFormat.pls,
        );
      });

      test('detects XSPF from content', () {
        const xspfContent =
            '<?xml version="1.0"?><playlist xmlns="http://xspf.org/ns/0/"><trackList/></playlist>';
        expect(
          detectPlaylistFormat('unknown.txt', content: xspfContent),
          PlaylistFormat.xspf,
        );
      });

      test('detects JSON from content', () {
        const jsonContent = '{"name":"Test","songIds":[1,2]}';
        expect(
          detectPlaylistFormat('unknown.txt', content: jsonContent),
          PlaylistFormat.json,
        );
      });

      test('returns unknown for unrecognized', () {
        expect(
          detectPlaylistFormat('playlist.txt', content: 'random content'),
          PlaylistFormat.unknown,
        );
      });
    });

    // ─── Edge Cases ────────────────────────────────────────────────────────────

    group('Edge Cases', () {
      test('handles empty playlist', () async {
        final service = PlaylistImportExportService();
        final result = await service.exportToString(
          [],
          'Empty Playlist',
          format: PlaylistFormat.m3u,
        );

        expect(result.success, isTrue);
        expect(result.content, contains('#EXTM3U'));
      });

      test('handles songs without duration', () async {
        final songs = [
          Song(
            id: 1,
            name: 'No Duration Song',
            artist: 'Artist',
            sourcePath: 'file.mp3',
            isBuiltIn: true,
          ),
        ];

        final service = PlaylistImportExportService();
        final result = await service.exportToString(
          songs,
          'Test',
          format: PlaylistFormat.m3u,
        );

        expect(result.success, isTrue);
        expect(
          result.content,
          contains('#EXTINF:-1,No Duration Song - Artist'),
        );
      });

      test('handles special characters in song metadata', () async {
        final songs = [
          Song(
            id: 1,
            name: 'Song, with "quotes" & ampersand',
            artist: 'Artist <test> & "quote"',
            album: 'Album "test" & more',
            durationMs: 180000,
            sourcePath: 'file.mp3',
            isBuiltIn: true,
          ),
        ];

        final service = PlaylistImportExportService();

        // Test M3U
        final m3uResult = await service.exportToString(
          songs,
          'Test',
          format: PlaylistFormat.m3u,
        );
        expect(m3uResult.success, isTrue);

        // Test PLS
        final plsResult = await service.exportToString(
          songs,
          'Test',
          format: PlaylistFormat.pls,
        );
        expect(plsResult.success, isTrue);

        // Test XSPF
        final xspfResult = await service.exportToString(
          songs,
          'Test',
          format: PlaylistFormat.xspf,
        );
        expect(xspfResult.success, isTrue);

        // Test JSON
        final jsonResult = await service.exportToString(
          songs,
          'Test',
          format: PlaylistFormat.json,
        );
        expect(jsonResult.success, isTrue);
      });
    });

    // ─── File I/O Tests ────────────────────────────────────────────────────────

    group('File I/O', () {
      test('imports from file', () async {
        final tempDir = await Directory.systemTemp.createTemp('playlist_test_');
        final file = File(p.join(tempDir.path, 'test.m3u'));

        const content = '''#EXTM3U
#EXTINF:180,File Song - File Artist
file.mp3
''';

        await file.writeAsString(content);

        final service = PlaylistImportExportService();
        final result = await service.importFromFile(file.path);

        expect(result.success, isTrue);
        expect(result.entries.length, 1);
        expect(result.entries[0].title, 'File Song');
        expect(result.entries[0].artist, 'File Artist');

        await tempDir.delete(recursive: true);
      });

      test('exports to file', () async {
        final songs = [
          Song(
            id: 1,
            name: 'File Song',
            artist: 'File Artist',
            durationMs: 180000,
            sourcePath: 'file.mp3',
            isBuiltIn: true,
          ),
        ];

        final tempDir = await Directory.systemTemp.createTemp(
          'playlist_export_',
        );
        final filePath = p.join(tempDir.path, 'export.m3u');

        final service = PlaylistImportExportService();
        final result = await service.exportToFile(
          songs,
          filePath,
          format: PlaylistFormat.m3u,
        );

        expect(result.success, isTrue);
        expect(await File(filePath).exists(), isTrue);

        final content = await File(filePath).readAsString();
        expect(content, contains('File Song - File Artist'));

        await tempDir.delete(recursive: true);
      });

      test('handles non-existent file', () async {
        final service = PlaylistImportExportService();
        final result = await service.importFromFile('/non/existent/path.m3u');

        expect(result.success, isFalse);
        expect(result.error, contains('File not found'));
      });
    });
  });
}
