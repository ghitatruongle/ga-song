/// Playlist Import/Export Service
///
/// Supports multiple playlist formats:
/// - M3U / M3U8 (standard and extended)
/// - PLS (SHOUTcast playlist format)
/// - XSPF (XML Shareable Playlist Format)
/// - JSON (native GA Song format)
///
/// All formats support round-trip import/export with validation.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../models/song.dart';

/// Supported playlist formats
enum PlaylistFormat { m3u, m3u8, pls, xspf, json, unknown }

/// Result of a playlist import operation
class PlaylistImportResult {
  final bool success;
  final String? playlistName;
  final List<PlaylistImportEntry> entries;
  final List<String> warnings;
  final String? error;

  const PlaylistImportResult({
    required this.success,
    this.playlistName,
    this.entries = const [],
    this.warnings = const [],
    this.error,
  });

  factory PlaylistImportResult.success({
    required final String playlistName,
    required final List<PlaylistImportEntry> entries,
    final List<String> warnings = const [],
  }) => PlaylistImportResult(
    success: true,
    playlistName: playlistName,
    entries: entries,
    warnings: warnings,
  );

  factory PlaylistImportResult.failure({
    required final String error,
    final String? playlistName,
    final List<String> warnings = const [],
  }) => PlaylistImportResult(
    success: false,
    playlistName: playlistName,
    warnings: warnings,
    error: error,
  );
}

/// A single playlist entry during import
class PlaylistImportEntry {
  final String title;
  final String? artist;
  final String? album;
  final String? sourcePath; // For local files
  final String? url; // For remote/streaming
  final int? durationSeconds;
  final Map<String, dynamic> metadata;

  const PlaylistImportEntry({
    required this.title,
    this.artist,
    this.album,
    this.sourcePath,
    this.url,
    this.durationSeconds,
    this.metadata = const {},
  });

  factory PlaylistImportEntry.fromJson(final Map<String, dynamic> json) =>
      PlaylistImportEntry(
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String?,
        album: json['album'] as String?,
        sourcePath: json['sourcePath'] as String?,
        url: json['url'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    if (artist != null) 'artist': artist,
    if (album != null) 'album': album,
    if (sourcePath != null) 'sourcePath': sourcePath,
    if (url != null) 'url': url,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

/// Result of a playlist export operation
class PlaylistExportResult {
  final bool success;
  final String? content;
  final String? error;

  const PlaylistExportResult({required this.success, this.content, this.error});

  factory PlaylistExportResult.success(final String content) =>
      PlaylistExportResult(success: true, content: content);

  factory PlaylistExportResult.failure(final String error) =>
      PlaylistExportResult(success: false, error: error);
}

/// Detects playlist format from file extension and content
PlaylistFormat detectPlaylistFormat(
  final String filePath, {
  final String? content,
}) {
  final ext = p.extension(filePath).toLowerCase();

  switch (ext) {
    case '.m3u':
    case '.m3u8':
      return PlaylistFormat.m3u;
    case '.pls':
      return PlaylistFormat.pls;
    case '.xspf':
      return PlaylistFormat.xspf;
    case '.json':
      return PlaylistFormat.json;
    default:
      // Try to detect from content
      if (content != null) {
        final trimmed = content.trim();
        if (trimmed.startsWith('#EXTM3U') || trimmed.startsWith('#EXTINF')) {
          return PlaylistFormat.m3u;
        }
        if (trimmed.startsWith('[playlist]') ||
            trimmed.startsWith('NumberOfEntries')) {
          return PlaylistFormat.pls;
        }
        if (trimmed.startsWith('<?xml') && trimmed.contains('xspf')) {
          return PlaylistFormat.xspf;
        }
        if (trimmed.startsWith('{') &&
            trimmed.contains('"name"') &&
            trimmed.contains('"songIds"')) {
          return PlaylistFormat.json;
        }
      }
      return PlaylistFormat.unknown;
  }
}

/// Main playlist import/export service
class PlaylistImportExportService {
  PlaylistImportExportService();

  /// Import a playlist from a file
  Future<PlaylistImportResult> importFromFile(final String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return PlaylistImportResult.failure(
          error: 'File not found: $filePath',
          playlistName: p.basenameWithoutExtension(filePath),
        );
      }

      final content = await file.readAsString();
      final format = detectPlaylistFormat(filePath, content: content);

      return await importFromString(
        content,
        format: format,
        playlistName: p.basenameWithoutExtension(filePath),
      );
    } catch (e) {
      return PlaylistImportResult.failure(
        error: 'Import failed: $e',
        playlistName: p.basenameWithoutExtension(filePath),
      );
    }
  }

  /// Import a playlist from string content
  Future<PlaylistImportResult> importFromString(
    final String content, {
    required final PlaylistFormat format,
    final String? playlistName,
  }) async {
    try {
      switch (format) {
        case PlaylistFormat.m3u:
        case PlaylistFormat.m3u8:
          return _importM3U(content, playlistName: playlistName);
        case PlaylistFormat.pls:
          return _importPLS(content, playlistName: playlistName);
        case PlaylistFormat.xspf:
          return _importXSPF(content, playlistName: playlistName);
        case PlaylistFormat.json:
          return _importJSON(content, playlistName: playlistName);
        default:
          return PlaylistImportResult.failure(
            error: 'Unsupported format: $format',
            playlistName: playlistName,
          );
      }
    } catch (e) {
      return PlaylistImportResult.failure(
        error: 'Parse failed: $e',
        playlistName: playlistName,
      );
    }
  }

  /// Export a playlist to string content
  Future<PlaylistExportResult> exportToString(
    final List<Song> songs,
    final String playlistName, {
    required final PlaylistFormat format,
  }) async {
    try {
      switch (format) {
        case PlaylistFormat.m3u:
        case PlaylistFormat.m3u8:
          return PlaylistExportResult.success(_exportM3U(songs, playlistName));
        case PlaylistFormat.pls:
          return PlaylistExportResult.success(_exportPLS(songs, playlistName));
        case PlaylistFormat.xspf:
          return PlaylistExportResult.success(_exportXSPF(songs, playlistName));
        case PlaylistFormat.json:
          return PlaylistExportResult.success(_exportJSON(songs, playlistName));
        default:
          return PlaylistExportResult.failure('Unsupported format: $format');
      }
    } catch (e) {
      return PlaylistExportResult.failure('Export failed: $e');
    }
  }

  /// Export a playlist to a file
  Future<PlaylistExportResult> exportToFile(
    final List<Song> songs,
    final String filePath, {
    required final PlaylistFormat format,
    final String? playlistName,
  }) async {
    final result = await exportToString(
      songs,
      playlistName ?? p.basenameWithoutExtension(filePath),
      format: format,
    );

    if (!result.success || result.content == null) {
      return result;
    }

    try {
      final file = File(filePath);
      await file.writeAsString(result.content!);
      return PlaylistExportResult.success(result.content!);
    } catch (e) {
      return PlaylistExportResult.failure('Write failed: $e');
    }
  }

  // ─── M3U Import/Export ────────────────────────────────────────────────────────

  PlaylistImportResult _importM3U(
    final String content, {
    final String? playlistName,
  }) {
    final lines = content.split('\n');
    final entries = <PlaylistImportEntry>[];
    final warnings = <String>[];
    String? headerPlaylistName;
    String? currentTitle;
    String? currentArtist;
    String? currentAlbum;
    int? currentDuration;
    String? currentPath;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty || line.startsWith('#EXTM3U')) {
        continue;
      }

      if (line.startsWith('#PLAYLIST:')) {
        headerPlaylistName = line.substring(10).trim();
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        // #EXTINF:duration,title - Artist
        final extinf = line.substring(8);
        final commaIndex = extinf.indexOf(',');
        if (commaIndex > 0) {
          final durationStr = extinf.substring(0, commaIndex).trim();
          currentDuration = int.tryParse(durationStr);
          final titleInfo = extinf.substring(commaIndex + 1).trim();

          // Parse "Title - Artist" or just "Title"
          if (titleInfo.contains(' - ')) {
            final parts = titleInfo.split(' - ');
            currentTitle = parts[0].trim();
            currentArtist = parts.sublist(1).join(' - ').trim();
          } else {
            currentTitle = titleInfo;
            currentArtist = null;
          }
        }
        currentAlbum = null;
        currentPath = null;
      } else if (line.startsWith('#EXTALB:')) {
        currentAlbum = line.substring(8).trim();
      } else if (line.startsWith('#EXTVLCOPT:')) {
        // VLC specific options, skip
      } else if (!line.startsWith('#')) {
        // This is a file path/URL
        currentPath = line;

        // Try to extract title from filename if not set
        if (currentTitle == null) {
          final fileName = p.basename(currentPath);
          final nameWithoutExt = p.basenameWithoutExtension(fileName);
          currentTitle = nameWithoutExt;
        }

        entries.add(
          PlaylistImportEntry(
            title: currentTitle,
            artist: currentArtist,
            album: currentAlbum,
            sourcePath: currentPath,
            durationSeconds: currentDuration,
          ),
        );

        // Reset for next entry
        currentTitle = null;
        currentArtist = null;
        currentAlbum = null;
        currentDuration = null;
        currentPath = null;
      } else {
        warnings.add('Line ${i + 1}: Unknown tag: $line');
      }
    }

    if (entries.isEmpty) {
      return PlaylistImportResult.failure(
        error: 'No valid entries found in M3U playlist',
        playlistName: playlistName,
        warnings: warnings,
      );
    }

    return PlaylistImportResult.success(
      playlistName: headerPlaylistName ?? playlistName ?? 'Imported Playlist',
      entries: entries,
      warnings: warnings,
    );
  }

  String _exportM3U(final List<Song> songs, final String playlistName) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#PLAYLIST:$playlistName');

    for (final song in songs) {
      if (song.duration != null) {
        buffer.writeln(
          '#EXTINF:${song.duration!.inSeconds},${song.name} - ${song.artist ?? 'Unknown Artist'}',
        );
      } else {
        buffer.writeln(
          '#EXTINF:-1,${song.name} - ${song.artist ?? 'Unknown Artist'}',
        );
      }

      if (song.album != null) {
        buffer.writeln('#EXTALB:${song.album}');
      }

      // Use sourcePath for local files, or asset path
      buffer.writeln(song.sourcePath);
    }

    return buffer.toString();
  }

  // ─── PLS Import/Export ────────────────────────────────────────────────────────

  PlaylistImportResult _importPLS(
    final String content, {
    final String? playlistName,
  }) {
    final lines = content.split('\n');
    final entries = <PlaylistImportEntry>[];
    final warnings = <String>[];

    String? playlistTitle;
    int currentEntryIndex = 0;
    String? currentFile;
    String? currentTitle;
    String? currentArtist;
    String? currentAlbum;
    int? currentLength;

    void flushCurrentEntry() {
      if (currentFile == null) return;
      entries.add(
        PlaylistImportEntry(
          title: currentTitle ?? 'Unknown',
          artist: currentArtist,
          album: currentAlbum,
          sourcePath: currentFile!,
          durationSeconds: currentLength,
        ),
      );
      currentFile = null;
      currentTitle = null;
      currentArtist = null;
      currentAlbum = null;
      currentLength = null;
    }

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty || trimmed.startsWith(';')) continue;
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) continue;

      final equalsIndex = trimmed.indexOf('=');
      if (equalsIndex <= 0) continue;

      final key = trimmed.substring(0, equalsIndex).trim();
      final value = trimmed.substring(equalsIndex + 1).trim();

      // Top-level metadata (playlist title, entry count, version).
      if (key.toLowerCase() == 'title' &&
          !RegExp(r'^title\d+$').hasMatch(key.toLowerCase())) {
        playlistTitle = value;
        continue;
      }
      if (key.toLowerCase() == 'numberofentries' ||
          key.toLowerCase() == 'version') {
        continue;
      }

      // Per-entry keys: fileN, titleN, artistN, albumN, lengthN.
      final indexMatch = RegExp(
        r'^(file|title|artist|album|length)(\d+)$',
      ).firstMatch(key.toLowerCase());
      if (indexMatch == null) {
        warnings.add('Unknown PLS key: $key');
        continue;
      }

      final entryIndex = int.parse(indexMatch.group(2)!);
      if (entryIndex != currentEntryIndex) {
        flushCurrentEntry();
        currentEntryIndex = entryIndex;
      }

      switch (indexMatch.group(1)) {
        case 'file':
          currentFile = value;
          break;
        case 'title':
          currentTitle = value;
          break;
        case 'artist':
          currentArtist = value;
          break;
        case 'album':
          currentAlbum = value;
          break;
        case 'length':
          currentLength = int.tryParse(value);
          break;
      }
    }

    flushCurrentEntry();

    if (entries.isEmpty) {
      return PlaylistImportResult.failure(
        error: 'No valid entries found in PLS playlist',
        playlistName: playlistName,
        warnings: warnings,
      );
    }

    return PlaylistImportResult.success(
      playlistName: playlistTitle ?? playlistName ?? 'Imported Playlist',
      entries: entries,
      warnings: warnings,
    );
  }

  String _exportPLS(final List<Song> songs, final String playlistName) {
    final buffer = StringBuffer();
    buffer.writeln('[playlist]');
    buffer.writeln('Title=$playlistName');
    buffer.writeln('NumberOfEntries=${songs.length}');

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      final index = i + 1;
      buffer.writeln('File$index=${song.sourcePath}');
      buffer.writeln('Title$index=${song.name}');
      if (song.artist != null) buffer.writeln('Artist$index=${song.artist}');
      if (song.album != null) buffer.writeln('Album$index=${song.album}');
      if (song.duration != null) {
        buffer.writeln('Length$index=${song.duration!.inSeconds}');
      }
    }

    buffer.writeln('Version=2');
    return buffer.toString();
  }

  // ─── XSPF Import/Export ──────────────────────────────────────────────────────

  PlaylistImportResult _importXSPF(
    final String content, {
    final String? playlistName,
  }) {
    try {
      final document = XmlDocument.parse(content);
      final playlistElement = document.findAllElements('playlist').first;

      final String? playlistTitle = playlistElement
          .findElements('title')
          .firstOrNull
          ?.innerText;
      final trackElements = playlistElement.findAllElements('track');

      final entries = <PlaylistImportEntry>[];
      final warnings = <String>[];

      for (final track in trackElements) {
        String? trackTitle;
        String? artist;
        String? album;
        String? location;
        int? duration;

        for (final child in track.children) {
          if (child is XmlElement) {
            switch (child.name.local) {
              case 'title':
                trackTitle = child.innerText;
                break;
              case 'creator':
                artist = child.innerText;
                break;
              case 'album':
                album = child.innerText;
                break;
              case 'location':
                location = child.innerText;
                break;
              case 'duration':
                final ms = int.tryParse(child.innerText);
                if (ms != null) duration = (ms / 1000).round();
                break;
            }
          }
        }

        if (trackTitle != null && location != null) {
          entries.add(
            PlaylistImportEntry(
              title: trackTitle,
              artist: artist,
              album: album,
              sourcePath: location,
              durationSeconds: duration,
            ),
          );
        } else {
          warnings.add('Skipping track with missing title or location');
        }
      }

      return PlaylistImportResult.success(
        playlistName: playlistTitle ?? playlistName ?? 'Imported Playlist',
        entries: entries,
        warnings: warnings,
      );
    } catch (e) {
      return PlaylistImportResult.failure(
        error: 'XSPF parse error: $e',
        playlistName: playlistName,
      );
    }
  }

  String _exportXSPF(final List<Song> songs, final String playlistName) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<playlist version="1" xmlns="http://xspf.org/ns/0/">');
    buffer.writeln('  <title>${_escapeXml(playlistName)}</title>');
    buffer.writeln('  <trackList>');

    for (final song in songs) {
      buffer.writeln('    <track>');
      buffer.writeln('      <title>${_escapeXml(song.name)}</title>');
      if (song.artist != null) {
        buffer.writeln('      <creator>${_escapeXml(song.artist!)}</creator>');
      }
      if (song.album != null) {
        buffer.writeln('      <album>${_escapeXml(song.album!)}</album>');
      }
      if (song.duration != null) {
        buffer.writeln(
          '      <duration>${song.duration!.inMilliseconds}</duration>',
        );
      }
      buffer.writeln(
        '      <location>${_escapeXml(song.sourcePath)}</location>',
      );
      if (song.album != null) {
        buffer.writeln(
          '      <identifier>${_escapeXml(song.sourcePath)}</identifier>',
        );
      }
      buffer.writeln('    </track>');
    }

    buffer.writeln('  </trackList>');
    buffer.writeln('</playlist>');
    return buffer.toString();
  }

  String _escapeXml(final String input) => input
      .replaceAll('&', '&')
      .replaceAll('<', '<')
      .replaceAll('>', '>')
      .replaceAll('"', '"')
      .replaceAll("'", '&apos;');

  // ─── JSON Import/Export ──────────────────────────────────────────────────────

  PlaylistImportResult _importJSON(
    final String content, {
    final String? playlistName,
  }) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      final name =
          json['name'] as String? ?? playlistName ?? 'Imported Playlist';

      final entries = <PlaylistImportEntry>[];
      final warnings = <String>[];

      // Prefer the full `songs` array (GA Song's native round-trip format);
      // fall back to minimal entries from `songIds`.
      final songsJson = (json['songs'] as List?) ?? const [];
      if (songsJson.isNotEmpty) {
        for (final songJson in songsJson) {
          if (songJson is Map<String, dynamic>) {
            entries.add(
              PlaylistImportEntry(
                title: songJson['name'] as String? ?? 'Unknown',
                artist: songJson['artist'] as String?,
                album: songJson['album'] as String?,
                sourcePath: songJson['sourcePath'] as String? ?? '',
                durationSeconds:
                    ((songJson['durationMs'] as num?) ?? 0) ~/ 1000,
                metadata: {'songId': songJson['id']},
              ),
            );
          }
        }
      } else {
        final songIds = (json['songIds'] as List?)?.cast<int>() ?? [];
        for (final id in songIds) {
          entries.add(
            PlaylistImportEntry(
              title: 'Song ID: $id',
              metadata: {'songId': id},
            ),
          );
        }
      }

      if (entries.isEmpty) {
        return PlaylistImportResult.failure(
          error: 'No valid entries found in JSON playlist',
          playlistName: name,
          warnings: warnings,
        );
      }

      return PlaylistImportResult.success(
        playlistName: name,
        entries: entries,
        warnings: warnings,
      );
    } catch (e) {
      return PlaylistImportResult.failure(
        error: 'JSON parse error: $e',
        playlistName: playlistName,
      );
    }
  }

  String _exportJSON(final List<Song> songs, final String playlistName) {
    final data = {
      'name': playlistName,
      'songIds': songs
          .map((final s) => s.id)
          .where((final id) => id != null)
          .cast<int>()
          .toList(),
      'songs': songs.map((final s) => s.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'format': 'ga-song-playlist',
      'version': 1,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
