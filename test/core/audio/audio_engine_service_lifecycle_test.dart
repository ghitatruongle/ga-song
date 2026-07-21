import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import '../../mocks/mock_audio_engine_service.dart';

void main() {
  // P3.4: Smoke tests for the lifecycle → position-timer wiring.
  //
  // The real AudioEngineService cannot be instantiated in this test
  // environment because flutter_soloud's native DLL isn't available, and
  // its constructor eagerly reads SoLoud.instance (line 55:
  //   final _soloud = SoLoud.instance;
  // ). So we exercise the wiring through MockAudioEngineService (which
  // implements the same interface, including WidgetsBindingObserver) and
  // rely on a compile-time type check below to guarantee the real class
  // has the same shape.

  // ─── Compile-time type check ────────────────────────────────────────────
  //
  // The factory declares its return type as `AudioEngineService?`. If
  // the real class ever drops the `with WidgetsBindingObserver` mixin,
  // the call site `is WidgetsBindingObserver` (further down) will fail
  // to compile, which is the deliverable assertion.
  AudioEngineService? probeType() => null;

  test(
      'AudioEngineService is a WidgetsBindingObserver (compile-time anchor)',
      () {
    final AudioEngineService? maybeEngine = probeType();
    // The `is` check below is the actual type assertion. Because
    // maybeEngine is null, the test only checks the type at runtime
    // when we cast; but the *static* type check is what matters.
    final WidgetsBindingObserver? observer = maybeEngine;
    expect(observer, isNull); // runtime is null; compile-time is the gate
  });

  // ─── Behavioural tests via the mock ─────────────────────────────────────

  group('MockAudioEngineService (implements WidgetsBindingObserver)', () {
    late MockAudioEngineService engine;

    setUp(() {
      engine = MockAudioEngineService();
    });

    tearDown(() {
      engine.dispose();
    });

    test('is a WidgetsBindingObserver at runtime', () {
      expect(engine, isA<WidgetsBindingObserver>());
    });

    test('receives AppLifecycleState.paused', () {
      engine.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(engine.lifecycleEventCount, 1);
      expect(engine.lastLifecycleState, AppLifecycleState.paused);
    });

    test('receives every AppLifecycleState without throwing', () {
      for (final state in AppLifecycleState.values) {
        expect(
          () => engine.didChangeAppLifecycleState(state),
          returnsNormally,
          reason: 'state=$state should be accepted',
        );
      }
      expect(engine.lifecycleEventCount, AppLifecycleState.values.length);
    });

    test('records state transitions in order', () {
      engine.didChangeAppLifecycleState(AppLifecycleState.resumed);
      engine.didChangeAppLifecycleState(AppLifecycleState.inactive);
      engine.didChangeAppLifecycleState(AppLifecycleState.paused);
      engine.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(engine.lifecycleEventCount, 4);
      expect(engine.lastLifecycleState, AppLifecycleState.hidden);
    });

    test('dispose after a lifecycle roundtrip completes', () async {
      // Use a local engine (not the setUp/tearDown one) so dispose is
      // only called once.
      final localEngine = MockAudioEngineService();
      localEngine.didChangeAppLifecycleState(AppLifecycleState.paused);
      localEngine.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await expectLater(localEngine.dispose(), completes);
    });
  });
}