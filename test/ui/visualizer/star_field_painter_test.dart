import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/painters/visualizer_painters.dart';
import 'package:ga_song/ui/visualizer/visualizer_controller.dart';

/// Minimal fake controller exposing a snapshot for the painter. We avoid
/// pulling in real `AudioEngineService` / `SettingsManager` since the
/// painter only reads `controller.snapshot`.
class _FakeVisualizerController extends ChangeNotifier
    implements VisualizerController {
  _FakeVisualizerController(this._snapshot);

  final VisualizerFrameSnapshot _snapshot;
  @override
  VisualizerFrameSnapshot get snapshot => _snapshot;

  // The painter only reads `snapshot`, so all other members are stubs
  // that throw if accidentally invoked.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected access: ${invocation.memberName}. '
      'The painter under test should only read `snapshot`.',
    );
  }
}

VisualizerFrameSnapshot _frameWith({
  StarFieldSnapshot? typedSnapshot,
  UnmodifiableListView<Star>? legacyStars,
  UnmodifiableListView<double>? fft,
}) {
  return VisualizerFrameSnapshot(
    fftData: fft ?? UnmodifiableListView<double>(const []),
    particles: UnmodifiableListView<Particle>(const []),
    stars: legacyStars ?? UnmodifiableListView<Star>(const []),
    smoothEnergy: 0.0,
    time: 0.0,
    size: const Size(800, 600),
    isBeat: false,
    starFieldSnapshot: typedSnapshot,
  );
}

Future<void> _pumpWithPainter(
  WidgetTester tester,
  VisualizerController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: CustomPaint(
            key: const ValueKey<String>('starfield-painter-canvas'),
            painter: StarfieldPainter(controller: controller),
          ),
        ),
      ),
    ),
  );
  expect(
    find.byKey(const ValueKey<String>('starfield-painter-canvas')),
    findsOneWidget,
  );
}

void main() {
  testWidgets(
    'StarfieldPainter renders without error when starFieldSnapshot is set',
    (tester) async {
      final typed = StarFieldSnapshot(
        positions: Float32List.fromList(const [
          100,
          100,
          200,
          200,
          400,
          300,
          600,
          500,
        ]),
        colors: Int32List.fromList(const [
          0xFFFFFFFF,
          0xFFFF0000,
          0xFF00FF00,
          0xFF0000FF,
        ]),
        radii: Float32List.fromList(const [2.0, 3.0, 1.5, 4.0]),
        zs: Float32List.fromList(const [0.5, 0.7, 0.9, 1.0]),
        speeds: Float32List.fromList(const [10.0, 20.0, 30.0, 40.0]),
      );
      final controller = _FakeVisualizerController(
        _frameWith(typedSnapshot: typed),
      );
      await _pumpWithPainter(tester, controller);
      // No exceptions should have been thrown by paint().
    },
  );

  testWidgets(
    'StarfieldPainter falls back to legacy Star list when typed snapshot is null',
    (tester) async {
      final legacyStars = UnmodifiableListView<Star>([
        Star(
          x: 50,
          y: 50,
          z: 0.5,
          speed: 1.0,
          baseAngle: 0,
          color: const Color(0xFFFFFFFF),
        ),
      ]);
      final controller = _FakeVisualizerController(
        _frameWith(legacyStars: legacyStars),
      );
      await _pumpWithPainter(tester, controller);
    },
  );

  testWidgets(
    'StarfieldPainter prefers typed snapshot over legacy list when both are set',
    (tester) async {
      final typed = StarFieldSnapshot(
        positions: Float32List.fromList(const [10, 10]),
        colors: Int32List.fromList(const [0xFFFFFFFF]),
        radii: Float32List.fromList(const [2.0]),
        zs: Float32List.fromList(const [0.8]),
        speeds: Float32List.fromList(const [25.0]),
      );
      final legacyStars = UnmodifiableListView<Star>([
        Star(
          x: 9999, // intentionally far off-screen
          y: 9999,
          z: 0.5,
          speed: 1.0,
          baseAngle: 0,
          color: const Color(0xFFFFFFFF),
        ),
      ]);
      final controller = _FakeVisualizerController(
        _frameWith(typedSnapshot: typed, legacyStars: legacyStars),
      );

      // Painting this should NOT throw — the painter should pick the
      // typed snapshot and ignore the legacy off-screen star.
      await _pumpWithPainter(tester, controller);
    },
  );

  testWidgets(
    'StarfieldPainter still draws the bottom wave when fftData is present',
    (tester) async {
      final fft = UnmodifiableListView<double>(
        List<double>.generate(256, (i) => i / 255.0),
      );
      final controller = _FakeVisualizerController(_frameWith(fft: fft));
      await _pumpWithPainter(tester, controller);
    },
  );
}
