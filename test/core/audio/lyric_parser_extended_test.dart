import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/lyric_parser.dart';

void main() {
  group('LyricParser', () {
    // ─── LRC Format ────────────────────────────────────────────────────

    group('LRC parsing', () {
      test('parses basic LRC format', () {
        const lrc = '[00:10.00]First line\n[00:20.50]Second line';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 2);
        expect(lines[0].text, 'First line');
        expect(lines[0].startTime, const Duration(seconds: 10));
        expect(lines[1].text, 'Second line');
        expect(lines[1].startTime, const Duration(milliseconds: 20500));
      });

      test('parses LRC with 3-digit milliseconds', () {
        const lrc = '[01:23.456]Test line';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 1);
        expect(lines[0].text, 'Test line');
        expect(lines[0].startTime, const Duration(minutes: 1, seconds: 23, milliseconds: 456));
      });

      test('parses LRC with 2-digit milliseconds', () {
        const lrc = '[00:05.50]Half second';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 1);
        expect(lines[0].startTime, const Duration(seconds: 5, milliseconds: 500));
      });

      test('parses multiple timestamps on same line', () {
        const lrc = '[00:10.00][00:20.00]Repeated line';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 2);
        expect(lines[0].text, 'Repeated line');
        expect(lines[1].text, 'Repeated line');
      });

      test('sorts lines by time', () {
        const lrc = '[00:30.00]Third\n[00:10.00]First\n[00:20.00]Second';
        final lines = LyricParser.parse(lrc);
        expect(lines[0].text, 'First');
        expect(lines[1].text, 'Second');
        expect(lines[2].text, 'Third');
      });

      test('ignores lines without timestamps', () {
        const lrc = '[00:10.00]Valid\nNo timestamp here\n[00:20.00]Also valid';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 2);
      });

      test('handles empty lines in LRC', () {
        const lrc = '[00:10.00]First\n\n\n[00:20.00]Second';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 2);
      });
    });

    // ─── SRT Format ────────────────────────────────────────────────────

    group('SRT parsing', () {
      test('parses basic SRT format', () {
        const srt = '1\n00:00:10,000 --> 00:00:20,000\nFirst line\n\n2\n00:00:20,000 --> 00:00:30,000\nSecond line';
        final lines = LyricParser.parse(srt);
        expect(lines.length, 2);
        expect(lines[0].text, 'First line');
        expect(lines[0].startTime, const Duration(seconds: 10));
        expect(lines[1].text, 'Second line');
        expect(lines[1].startTime, const Duration(seconds: 20));
      });

      test('parses SRT with hours', () {
        const srt = '1\n01:30:00,000 --> 01:30:10,000\nHour test';
        final lines = LyricParser.parse(srt);
        expect(lines.length, 1);
        expect(lines[0].startTime, const Duration(hours: 1, minutes: 30));
      });

      test('parses SRT with multiline text', () {
        const srt = '1\n00:00:10,000 --> 00:00:20,000\nLine one\nLine two';
        final lines = LyricParser.parse(srt);
        expect(lines.length, 1);
        expect(lines[0].text, 'Line one\nLine two');
      });

      test('handles SRT with Windows line endings', () {
        const srt = '1\r\n00:00:10,000 --> 00:00:20,000\r\nTest line';
        final lines = LyricParser.parse(srt);
        expect(lines.length, 1);
        expect(lines[0].text, 'Test line');
      });

      test('ignores empty SRT blocks', () {
        const srt = '1\n00:00:10,000 --> 00:00:20,000\nValid\n\n\n\n2\n00:00:20,000 --> 00:00:30,000\nAlso valid';
        final lines = LyricParser.parse(srt);
        expect(lines.length, 2);
      });
    });

    // ─── Edge Cases ────────────────────────────────────────────────────

    group('edge cases', () {
      test('returns empty list for empty input', () {
        expect(LyricParser.parse(''), isEmpty);
      });

      test('returns empty list for whitespace only', () {
        expect(LyricParser.parse('   \n  \n  '), isEmpty);
      });

      test('returns empty list for garbage input', () {
        expect(LyricParser.parse('not a lyric file at all'), isEmpty);
      });

      test('auto-detects SRT format by --> marker', () {
        const srt = '1\n00:00:10,000 --> 00:00:20,000\nSRT detected';
        final lines = LyricParser.parse(srt);
        expect(lines.length, 1);
        expect(lines[0].text, 'SRT detected');
      });

      test('auto-detects LRC format when no --> marker', () {
        const lrc = '[00:10.00]LRC detected';
        final lines = LyricParser.parse(lrc);
        expect(lines.length, 1);
        expect(lines[0].text, 'LRC detected');
      });
    });

    // ─── LyricLine ─────────────────────────────────────────────────────

    group('LyricLine', () {
      test('stores startTime and text', () {
        final line = LyricLine(
          startTime: const Duration(seconds: 30),
          text: 'Hello world',
        );
        expect(line.startTime, const Duration(seconds: 30));
        expect(line.text, 'Hello world');
      });

      test('handles empty text', () {
        final line = LyricLine(startTime: Duration.zero, text: '');
        expect(line.text, isEmpty);
      });

      test('handles unicode text', () {
        final line = LyricLine(
          startTime: Duration.zero,
          text: 'Xin chào thế giới 🎵',
        );
        expect(line.text, 'Xin chào thế giới 🎵');
      });
    });
  });
}
