import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/settings/settings_state.dart';

void main() {
  test('SettingsState defaults soundFeedbackEnabled to false', () {
    const state = SettingsState();
    expect(state.soundFeedbackEnabled, isFalse);
  });

  test('SettingsState.copyWith updates soundFeedbackEnabled', () {
    const state = SettingsState();
    final updated = state.copyWith(soundFeedbackEnabled: true);
    expect(updated.soundFeedbackEnabled, isTrue);
    // Other fields unchanged
    expect(updated.themeMode, state.themeMode);
    expect(updated.enableBlur, state.enableBlur);
  });
}
