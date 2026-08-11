import 'dart:io';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Represents a single syllable in karaoke lyrics.
class LyricSyllable {
  final String text;
  final Duration startTime;
  final Duration endTime;

  const LyricSyllable({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  /// Duration of this syllable.
  Duration get duration => endTime - startTime;

  /// Checks if the given position is within this syllable's time range.
  bool contains(final Duration position) =>
      position >= startTime && position < endTime;

  /// Progress of the syllable (0.0 to 1.0) at the given position.
  double progressAt(final Duration position) {
    final total = duration.inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = (position - startTime).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

/// Represents a line of lyrics with optional syllable-level timing.
class LyricLine {
  final Duration startTime;
  final String text;
  final List<LyricSyllable>? syllables;

  /// Creates a line without syllable-level timing (legacy).
  const LyricLine({
    required this.startTime,
    required this.text,
    this.syllables,
  });

  /// Creates a line with syllable-level timing.
  factory LyricLine.withSyllables({
    required final Duration startTime,
    required final String text,
    required final List<LyricSyllable> syllables,
  }) => LyricLine(startTime: startTime, text: text, syllables: syllables);

  /// Whether this line has syllable-level timing.
  bool get hasSyllables => syllables != null && syllables!.isNotEmpty;

  /// Gets the syllable at the given position, or null if none.
  LyricSyllable? getSyllableAt(final Duration position) {
    if (!hasSyllables) return null;
    for (final syllable in syllables!) {
      if (syllable.contains(position)) {
        return syllable;
      }
    }
    return null;
  }

  /// Gets the index of the syllable at the given position, or -1 if none.
  int getSyllableIndexAt(final Duration position) {
    if (!hasSyllables) return -1;
    for (int i = 0; i < syllables!.length; i++) {
      if (syllables![i].contains(position)) {
        return i;
      }
    }
    return -1;
  }
}

class LyricParser {
  /// Parses an LRC or SRT string into a list of LyricLine.
  static List<LyricLine> parse(final String content) {
    if (content.contains('-->')) {
      return _parseSrt(content);
    }
    return _parseLrc(content);
  }

  static List<LyricLine> _parseLrc(final String lrcContent) {
    final lines = lrcContent.split('\n');
    final List<LyricLine> lyrics = [];

    // Matches [mm:ss.xx] or [mm:ss.xxx]
    final RegExp timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

    for (var line in lines) {
      final matches = timeRegex.allMatches(line);
      if (matches.isNotEmpty) {
        // Check if this is enhanced LRC (syllable-level timing)
        // Enhanced format has timestamps interleaved with text
        final hasEnhanced = _isEnhancedLrc(line, matches);

        if (hasEnhanced) {
          lyrics.add(_parseEnhancedLrcLine(line, matches));
        } else {
          lyrics.addAll(_parseStandardLrcLine(line, matches));
        }
      }
    }

    // Sort by time just in case
    lyrics.sort((final a, final b) => a.startTime.compareTo(b.startTime));
    return lyrics;
  }

  /// Checks if the line uses enhanced LRC format (syllable-level timing).
  /// Enhanced LRC has timestamps both at the start of the line AND within the text.
  static bool _isEnhancedLrc(
    final String line,
    final Iterable<RegExpMatch> matches,
  ) {
    // Enhanced LRC has timestamps both at the start of the line AND within the text
    // We check if there's text between timestamps (not just at the end)
    final matchList = matches.toList();
    if (matchList.length < 2) return false;

    // Check if there's text between the last two timestamps
    final lastMatch = matchList[matchList.length - 1];
    final secondLastMatch = matchList[matchList.length - 2];

    // If there's non-whitespace text between timestamps, it's enhanced
    final betweenText = line
        .substring(secondLastMatch.end, lastMatch.start)
        .trim();
    return betweenText.isNotEmpty;
  }

  /// Parses a standard LRC line (single timestamp at start, text follows).
  /// A line may carry multiple timestamps (e.g. `[00:10.00][00:20.00]Text`);
  /// one [LyricLine] is produced per timestamp.
  static List<LyricLine> _parseStandardLrcLine(
    final String line,
    final Iterable<RegExpMatch> matches,
  ) {
    // Find the last match to split the text from timestamps
    final matchList = matches.toList();
    final text = line.substring(matchList.last.end).trim();

    final List<LyricLine> lineEntries = [];
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

      lineEntries.add(LyricLine(startTime: duration, text: text));
    }

    return lineEntries;
  }

  /// Parses an enhanced LRC line with syllable-level timing.
  /// Format: [mm:ss.xx]syllable1[mm:ss.xx]syllable2[mm:ss.xx]...
  static LyricLine _parseEnhancedLrcLine(
    final String line,
    final Iterable<RegExpMatch> matches,
  ) {
    final matchList = matches.toList();

    // First timestamp is the line start time
    final firstMatch = matchList.first;
    final lineStartMinutes = int.parse(firstMatch.group(1)!);
    final lineStartSeconds = int.parse(firstMatch.group(2)!);
    final lineStartMsStr = firstMatch.group(3)!;
    final lineStartMs = lineStartMsStr.length == 2
        ? int.parse(lineStartMsStr) * 10
        : int.parse(lineStartMsStr);

    final lineStartTime = Duration(
      minutes: lineStartMinutes,
      seconds: lineStartSeconds,
      milliseconds: lineStartMs,
    );

    // Parse syllables from the interleaved timestamps and text
    final List<LyricSyllable> syllables = [];
    String fullText = '';

    for (int i = 0; i < matchList.length - 1; i++) {
      final currentMatch = matchList[i];
      final nextMatch = matchList[i + 1];

      // Text between this timestamp and the next
      final syllableText = line
          .substring(currentMatch.end, nextMatch.start)
          .trim();

      if (syllableText.isEmpty) continue;

      final startMinutes = int.parse(currentMatch.group(1)!);
      final startSeconds = int.parse(currentMatch.group(2)!);
      final startMsStr = currentMatch.group(3)!;
      final startMs = startMsStr.length == 2
          ? int.parse(startMsStr) * 10
          : int.parse(startMsStr);

      final endMinutes = int.parse(nextMatch.group(1)!);
      final endSeconds = int.parse(nextMatch.group(2)!);
      final endMsStr = nextMatch.group(3)!;
      final endMs = endMsStr.length == 2
          ? int.parse(endMsStr) * 10
          : int.parse(endMsStr);

      final startTime = Duration(
        minutes: startMinutes,
        seconds: startSeconds,
        milliseconds: startMs,
      );

      final endTime = Duration(
        minutes: endMinutes,
        seconds: endSeconds,
        milliseconds: endMs,
      );

      syllables.add(
        LyricSyllable(
          text: syllableText,
          startTime: startTime,
          endTime: endTime,
        ),
      );

      fullText += syllableText;
    }

    // Also add the text after the last timestamp
    final lastMatch = matchList.last;
    final remainingText = line.substring(lastMatch.end).trim();
    if (remainingText.isNotEmpty && syllables.isNotEmpty) {
      // Extend the last syllable
      final lastSyllable = syllables.last;
      final updatedSyllable = LyricSyllable(
        text: '${lastSyllable.text} $remainingText',
        startTime: lastSyllable.startTime,
        endTime: lastSyllable.endTime,
      );
      syllables[syllables.length - 1] = updatedSyllable;
      fullText += ' $remainingText';
    } else if (remainingText.isNotEmpty && syllables.isEmpty) {
      // Fallback: treat as standard line
      fullText = remainingText;
    }

    if (fullText.isEmpty) {
      fullText = line.substring(matchList.first.end).trim();
    }

    return LyricLine.withSyllables(
      startTime: lineStartTime,
      text: fullText,
      syllables: syllables,
    );
  }

  static List<LyricLine> _parseSrt(final String srtContent) {
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
            lyrics.add(
              LyricLine(
                startTime: Duration(
                  hours: hours,
                  minutes: minutes,
                  seconds: seconds,
                  milliseconds: milliseconds,
                ),
                text: text,
              ),
            );
          }
        }
      }
    }
    lyrics.sort((final a, final b) => a.startTime.compareTo(b.startTime));
    return lyrics;
  }

  /// Attempts to load an LRC or SRT file matching the audio file path.
  static Future<List<LyricLine>> loadLyricForSong(
    final String audioSourcePath,
    final bool isBuiltIn,
  ) async {
    try {
      final lastDotIndex = audioSourcePath.lastIndexOf('.');
      if (lastDotIndex == -1) return [];
      final basePath = audioSourcePath.substring(0, lastDotIndex);

      if (isBuiltIn) {
        // Try .srt then .lrc
        // Try .srt, .lrc, _lyric.srt, _lyric.lrc
        final patterns = [
          '$basePath.srt',
          '$basePath.lrc',
          '${basePath}_lyric.srt',
          '${basePath}_lyric.lrc',
        ];
        for (final path in patterns) {
          try {
            final content = await rootBundle.loadString(path);
            return parse(content);
          } catch (e) {
            AppLogger.w(
              'audio.lyric_parser',
              'line parse failed; continuing',
              error: e,
            );
            // Keep looking
          }
        }
      } else {
        // Local file
        final patterns = [
          '$basePath.srt',
          '$basePath.lrc',
          '${basePath}_lyric.srt',
          '${basePath}_lyric.lrc',
        ];
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
