import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/utils/debouncer.dart';

void main() {
  test('Debouncer coalesces rapid calls into one', () async {
    final d = Debouncer(milliseconds: 50);
    var calls = 0;
    final futures = <Future<void>>[];
    for (var i = 0; i < 10; i++) {
      futures.add(Future(() => d.run(() => calls++)));
    }
    await Future.wait(futures);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(calls, 1);
  });

  test('Debouncer cancel discards pending action', () async {
    final d = Debouncer(milliseconds: 50);
    var called = false;
    d.run(() => called = true);
    d.cancel();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(called, isFalse);
  });
}
