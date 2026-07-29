import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/ui/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_audio_engine_service.dart';

void main() {
  late SettingsManager settings;
  late MockAudioEngineService mockEngine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsManager();
    await settings.init();
    mockEngine = MockAudioEngineService();
  });

  tearDown(() {
    settings.dispose();
  });

  Future<void> pumpSidebar(
    WidgetTester tester, {
    TabItem currentTab = TabItem.home,
    ValueChanged<TabItem>? onTabChanged,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsManagerProvider.overrideWithValue(settings),
          audioEngineServiceProvider.overrideWithValue(mockEngine),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SidebarWidget(
                  currentTab: currentTab,
                  onTabChanged: onTabChanged ?? (_) {},
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    // The expanded sidebar hosts a continuously repeating animation, so
    // pumpAndSettle would time out — pump past the 250ms collapse animation
    // with fixed durations instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SidebarWidget', () {
    testWidgets('renders main navigation items when expanded', (tester) async {
      await pumpSidebar(tester);

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Thư viện'), findsOneWidget);
    });

    testWidgets('tapping a nav item fires onTabChanged', (tester) async {
      TabItem? selected;
      await pumpSidebar(tester, onTabChanged: (tab) => selected = tab);

      await tester.tap(find.text('Thư viện'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(selected, TabItem.library);
    });

    testWidgets('collapse state from settings shrinks the sidebar width', (
      tester,
    ) async {
      await settings.setSidebarCollapsed(true);
      await pumpSidebar(tester);

      final sidebarSize = tester.getSize(find.byType(SidebarWidget));
      expect(sidebarSize.width, kSidebarCollapsedWidth);
      // Labels are hidden when collapsed.
      expect(find.text('Trang chủ'), findsNothing);
    });
  });
}
