import 'package:ga_song/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/core/services/db_service_wrapper.dart';
import 'package:ga_song/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GASongApp builds MaterialApp shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsManager();
    await settings.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsManagerProvider.overrideWithValue(settings),
          databaseServiceProvider.overrideWithValue(
            DatabaseServiceWrapper(
              AppDatabase(executor: NativeDatabase.memory()),
            ),
          ),
        ],
        child: const GASongApp(
          home: Scaffold(body: Center(child: Text('Smoke Home'))),
        ),
      ),
    );

    expect(find.text('Smoke Home'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'G.A - Song');

    settings.dispose();
  });
}
