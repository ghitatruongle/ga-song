import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/providers/service_providers.dart';

void main() {
  testWidgets('settingsNotifierProvider resolves under test container', (
    final tester,
  ) async {
    final container = ProviderContainer(
      overrides: [settingsManagerProvider.overrideWithValue(SettingsManager())],
    );
    addTearDown(container.dispose);

    // The actual safety net for the migration is the grep in Task 7
    // (zero addListener calls in lib/ui/screens/home_screen.dart).
    // This smoke test asserts the providers resolve cleanly.
    expect(container.read(settingsNotifierProvider), isNotNull);
  });
}
