import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/lyric_parser.dart';

void main() {
  group('LyricLine', () {
    test('stores startTime and text', () {
      final line = LyricLine(
        startTime: const Duration(seconds: 30),
        text: 'Hello world',
      );

      expect(line.startTime, const Duration(seconds: 30));
      expect(line.text, 'Hello world');
    });
  });

  group('LyricParser.parse', () {
    test('parses LRC format correctly', () {
      const lrc =
          '[00:10.00]First line\n[00:20.50]Second line\n[00:30.00]Third line';
      final lines = LyricParser.parse(lrc);

      expect(lines.length, 3);
      expect(lines[0].text, 'First line');
      expect(lines[0].startTime, const Duration(seconds: 10));
      expect(lines[1].text, 'Second line');
      expect(lines[1].startTime, const Duration(milliseconds: 20500));
      expect(lines[2].text, 'Third line');
      expect(lines[2].startTime, const Duration(seconds: 30));
    });

    test('parses SRT format correctly', () {
      const srt =
          '1\n00:00:10,000 --> 00:00:20,000\nFirst line\n\n2\n00:00:20,000 --> 00:00:30,000\nSecond line';
      final lines = LyricParser.parse(srt);

      expect(lines.length, 2);
      expect(lines[0].text, 'First line');
      expect(lines[0].startTime, const Duration(seconds: 10));
      expect(lines[1].text, 'Second line');
      expect(lines[1].startTime, const Duration(seconds: 20));
    });

    test('returns empty list for empty input', () {
      final lines = LyricParser.parse('');
      expect(lines, isEmpty);
    });

    test('handles LRC with milliseconds', () {
      const lrc = '[01:23.456]Test line';
      final lines = LyricParser.parse(lrc);

      expect(lines.length, 1);
      expect(lines[0].text, 'Test line');
      expect(
        lines[0].startTime,
        const Duration(minutes: 1, seconds: 23, milliseconds: 456),
      );
    });
  });

  group('CurrentLyricLineNotifier logic', () {
    test('finds correct lyric line for given position', () {
      final lines = [
        LyricLine(startTime: Duration.zero, text: ''),
        LyricLine(startTime: const Duration(seconds: 10), text: 'Line 1'),
        LyricLine(startTime: const Duration(seconds: 20), text: 'Line 2'),
        LyricLine(startTime: const Duration(seconds: 30), text: 'Line 3'),
      ];

      // Helper to find line at position (same logic as CurrentLyricLineNotifier)
      String findLine(Duration position) {
        for (int i = lines.length - 1; i >= 0; i--) {
          if (lines[i].startTime <= position) {
            return lines[i].text;
          }
        }
        return lines.isNotEmpty ? lines.first.text : '';
      }

      expect(findLine(Duration.zero), '');
      expect(findLine(const Duration(seconds: 5)), '');
      expect(findLine(const Duration(seconds: 10)), 'Line 1');
      expect(findLine(const Duration(seconds: 15)), 'Line 1');
      expect(findLine(const Duration(seconds: 20)), 'Line 2');
      expect(findLine(const Duration(seconds: 25)), 'Line 2');
      expect(findLine(const Duration(seconds: 30)), 'Line 3');
      expect(findLine(const Duration(seconds: 60)), 'Line 3');
    });

    test('returns empty string for empty lyrics', () {
      final lines = <LyricLine>[];

      String findLine(Duration position) {
        for (int i = lines.length - 1; i >= 0; i--) {
          if (lines[i].startTime <= position) {
            return lines[i].text;
          }
        }
        return lines.isNotEmpty ? lines.first.text : '';
      }

      expect(findLine(const Duration(seconds: 10)), '');
    });

    test('handles position before first lyric line', () {
      final lines = [
        LyricLine(startTime: const Duration(seconds: 10), text: 'First'),
      ];

      String findLine(Duration position) {
        for (int i = lines.length - 1; i >= 0; i--) {
          if (lines[i].startTime <= position) {
            return lines[i].text;
          }
        }
        return lines.isNotEmpty ? lines.first.text : '';
      }

      // Position before first line should return first line text
      expect(findLine(const Duration(seconds: 5)), 'First');
    });
  });
}
