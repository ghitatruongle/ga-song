import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/utils/haptic_helper.dart';

void main() {
  // Smoke: function exists and is callable. Actual haptic invocation
  // requires platform-channel mocking — out of scope.
  test('safeHaptic light is callable (does not throw)', () async {
    await safeHaptic(HapticType.light);
  });

  test('safeHaptic medium is callable (does not throw)', () async {
    await safeHaptic(HapticType.medium);
  });
}
