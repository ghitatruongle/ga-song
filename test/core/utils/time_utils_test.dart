import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/utils/time_utils.dart';

void main() {
  group('formatDuration', () {
    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('formats seconds only', () {
      expect(formatDuration(const Duration(seconds: 30)), '00:30');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 3, seconds: 45)), '03:45');
    });

    test('formats single digit seconds with padding', () {
      expect(formatDuration(const Duration(seconds: 5)), '00:05');
    });

    test('formats single digit minutes with padding', () {
      expect(formatDuration(const Duration(minutes: 1, seconds: 0)), '01:00');
    });

    test('formats 59 minutes correctly', () {
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('caps minutes at 59 for durations >= 1 hour', () {
      // 1 hour = 60 minutes, but inMinutes.remainder(60) = 0
      expect(formatDuration(const Duration(hours: 1, minutes: 0, seconds: 0)), '00:00');
    });

    test('formats 1 hour 30 minutes correctly', () {
      // 90 minutes → 90.remainder(60) = 30
      expect(formatDuration(const Duration(hours: 1, minutes: 30, seconds: 15)), '30:15');
    });

    test('formats 2 hours correctly', () {
      // 120 minutes → 120.remainder(60) = 0
      expect(formatDuration(const Duration(hours: 2)), '00:00');
    });

    test('formats milliseconds truncated to seconds', () {
      expect(formatDuration(const Duration(milliseconds: 90500)), '01:30');
    });

    test('formats common song duration', () {
      expect(formatDuration(const Duration(minutes: 3, seconds: 42)), '03:42');
    });

    test('formats long song duration', () {
      expect(formatDuration(const Duration(minutes: 12, seconds: 7)), '12:07');
    });
  });
}
