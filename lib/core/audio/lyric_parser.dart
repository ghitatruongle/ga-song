import 'dart:io';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

class LyricLine {
  final Duration startTime;
  final String text;

  LyricLine({required this.startTime, required this.text});
}

class LyricParser {
  /// Parses an LRC or SRT string into a list of LyricLine.
  static List<LyricLine> parse(String content) {
    if (content.contains('-->')) {
      return _parseSrt(content);
    }
    return _parseLrc(content);
  }

  static List<LyricLine> _parseLrc(String lrcContent) {
    final lines = lrcContent.split('\n');
    final List<LyricLine> lyrics = [];
    
    // Matches [mm:ss.xx] or [mm:ss.xxx]
    final RegExp timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

    for (var line in lines) {
      final matches = timeRegex.allMatches(line);
      if (matches.isNotEmpty) {
        // Find the last match to split the text from timestamps
        final text = line.substring(matches.last.end).trim();
        
        for (var match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final millisecondsStr = match.group(3)!;
          // Handle 2 or 3 digit milliseconds
          final milliseconds = millisecondsStr.length == 2 
              ? int.parse(millisecondsStr) * 10
              : int.parse(millisecondsStr);

          final duration = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );

          lyrics.add(LyricLine(startTime: duration, text: text));
        }
      }
    }

    // Sort by time just in case
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));
    return lyrics;
  }

  static List<LyricLine> _parseSrt(String srtContent) {
    final blocks = srtContent.split(RegExp(r'\n\s*\n'));
    final List<LyricLine> lyrics = [];
    final RegExp timeRegex = RegExp(r'(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->');

    for (var block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length >= 3) {
        final timeLine = lines[1];
        final match = timeRegex.firstMatch(timeLine);
        if (match != null) {
          final hours = int.parse(match.group(1)!);
          final minutes = int.parse(match.group(2)!);
          final seconds = int.parse(match.group(3)!);
          final milliseconds = int.parse(match.group(4)!);
          
          final text = lines.skip(2).join('\n').trim();
          if (text.isNotEmpty) {
            lyrics.add(LyricLine(
              startTime: Duration(
                hours: hours,
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds,
              ),
              text: text,
            ));
          }
        }
      }
    }
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));
    return lyrics;
  }

  /// Attempts to load an LRC or SRT file matching the audio file path.
  static Future<List<LyricLine>> loadLyricForSong(String audioSourcePath, bool isBuiltIn) async {
    try {
      final lastDotIndex = audioSourcePath.lastIndexOf('.');
      if (lastDotIndex == -1) return [];
      final basePath = audioSourcePath.substring(0, lastDotIndex);

      if (isBuiltIn) {
        // Try .srt then .lrc
        // Try .srt, .lrc, _lyric.srt, _lyric.lrc
        final patterns = ['$basePath.srt', '$basePath.lrc', '${basePath}_lyric.srt', '${basePath}_lyric.lrc'];
        for (final path in patterns) {
          try {
            final content = await rootBundle.loadString(path);
            return parse(content);
          } catch (e) {
            AppLogger.w('audio.lyric_parser', 'line parse failed; continuing', error: e);
            // Keep looking
          }
        }
      } else {
        // Local file
        final patterns = ['$basePath.srt', '$basePath.lrc', '${basePath}_lyric.srt', '${basePath}_lyric.lrc'];
        for (final path in patterns) {
          final lrcFile = File(path);
          if (await lrcFile.exists()) {
            final content = await lrcFile.readAsString();
            return parse(content);
          }
        }
      }
    } catch (e) {
      // Ignored
    }
    return [];
  }
}
