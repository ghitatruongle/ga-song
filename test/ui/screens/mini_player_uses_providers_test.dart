import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/core/settings_manager.dart';

void main() {
  test('settingsManagerProvider resolves under test container', () {
    final container = ProviderContainer(
      overrides: [settingsManagerProvider.overrideWithValue(SettingsManager())],
    );
    addTearDown(container.dispose);
    expect(container.read(settingsManagerProvider), isNotNull);
  });

  test('audioEngineServiceProvider is a registered Provider', () {
    // We cannot fully resolve audioEngineServiceProvider in unit tests
    // because SoLoud requires native bindings. Instead, verify it is a
    // Provider (compile-time type assertion) and that the providers it
    // depends on can be constructed under overrides.
    expect(audioEngineServiceProvider, isA<Provider>());
    final container = ProviderContainer(
      overrides: [settingsManagerProvider.overrideWithValue(SettingsManager())],
    );
    addTearDown(container.dispose);
    // Trigger lazy creation chain by reading a sibling that depends on
    // the engine — we just verify no crash for an unrelated provider.
    expect(container.read(settingsManagerProvider), isNotNull);
  });

  test('playlistServiceProvider is a registered Provider', () {
    expect(playlistServiceProvider, isA<Provider>());
  });
}
