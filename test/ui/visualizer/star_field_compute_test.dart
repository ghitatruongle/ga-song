import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/visualizer/visualizer_controller.dart';

void main() {
  test('StarFieldComputeInput carries all parameters', () {
    const input = StarFieldComputeInput(
      starCount: 20,
      timeSeconds: 1.5,
      amplitude: 0.5,
      seed: 42,
      screenWidth: 800,
      screenHeight: 600,
    );
    expect(input.starCount, 20);
    expect(input.timeSeconds, 1.5);
    expect(input.amplitude, 0.5);
    expect(input.seed, 42);
    expect(input.screenWidth, 800);
    expect(input.screenHeight, 600);
  });

  test('StarFieldSnapshot returns empty for zero stars', () {
    final s = computeStarField(
      const StarFieldComputeInput(
        starCount: 0,
        timeSeconds: 0,
        amplitude: 0,
        seed: 0,
        screenWidth: 800,
        screenHeight: 600,
      ),
    );
    expect(s.length, 0);
    expect(s.positions.length, 0);
    expect(s.colors.length, 0);
    expect(s.radii.length, 0);
    expect(s.zs.length, 0);
    expect(s.speeds.length, 0);
  });

  test('StarFieldSnapshot produces requested count of stars', () {
    final s = computeStarField(
      const StarFieldComputeInput(
        starCount: 20,
        timeSeconds: 1.0,
        amplitude: 0.5,
        seed: 7,
        screenWidth: 800,
        screenHeight: 600,
      ),
    );
    expect(s.length, 20);
    expect(s.positions.length, 40);
    expect(s.colors.length, 20);
    expect(s.radii.length, 20);
    expect(s.zs.length, 20);
    expect(s.speeds.length, 20);
  });

  test('computeStarField positions lie within the screen bounds', () {
    final s = computeStarField(
      const StarFieldComputeInput(
        starCount: 50,
        timeSeconds: 2.0,
        amplitude: 0.5,
        seed: 123,
        screenWidth: 800,
        screenHeight: 600,
      ),
    );
    for (var i = 0; i < s.length; i++) {
      final x = s.positions[i * 2];
      final y = s.positions[i * 2 + 1];
      expect(x, greaterThanOrEqualTo(0));
      expect(x, lessThan(801));
      expect(y, greaterThanOrEqualTo(0));
      expect(y, lessThan(601));
    }
  });

  test('computeStarField zs are bounded in [0.5, 1.0]', () {
    final s = computeStarField(
      const StarFieldComputeInput(
        starCount: 64,
        timeSeconds: 0.5,
        amplitude: 0.5,
        seed: 99,
        screenWidth: 1024,
        screenHeight: 768,
      ),
    );
    for (var i = 0; i < s.length; i++) {
      expect(s.zs[i], greaterThanOrEqualTo(0.5));
      expect(s.zs[i], lessThanOrEqualTo(1.0));
    }
  });

  test('computeStarField speeds lie in [10, 50] pixels/second', () {
    final s = computeStarField(
      const StarFieldComputeInput(
        starCount: 64,
        timeSeconds: 0.5,
        amplitude: 0.5,
        seed: 99,
        screenWidth: 1024,
        screenHeight: 768,
      ),
    );
    for (var i = 0; i < s.length; i++) {
      expect(s.speeds[i], greaterThanOrEqualTo(10.0));
      expect(s.speeds[i], lessThanOrEqualTo(50.0));
    }
  });

  test('computeStarField is deterministic for the same seed', () {
    const input = StarFieldComputeInput(
      starCount: 32,
      timeSeconds: 3.14,
      amplitude: 0.25,
      seed: 7,
      screenWidth: 1280,
      screenHeight: 720,
    );
    final a = computeStarField(input);
    final b = computeStarField(input);
    expect(a.positions.length, b.positions.length);
    for (var i = 0; i < a.positions.length; i++) {
      expect(a.positions[i], b.positions[i]);
    }
    for (var i = 0; i < a.zs.length; i++) {
      expect(a.zs[i], b.zs[i]);
    }
    for (var i = 0; i < a.speeds.length; i++) {
      expect(a.speeds[i], b.speeds[i]);
    }
  });

  test('computeStarField tolerates zero-sized screen inputs', () {
    // Degenerate but possible before the first layout pass. The isolate
    // should not throw — it falls back to a sane default viewport.
    final s = computeStarField(
      const StarFieldComputeInput(
        starCount: 4,
        timeSeconds: 0,
        amplitude: 0,
        seed: 1,
        screenWidth: 0,
        screenHeight: 0,
      ),
    );
    expect(s.length, 4);
    expect(s.zs.length, 4);
    expect(s.speeds.length, 4);
  });
}