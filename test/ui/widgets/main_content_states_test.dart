import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:ga_song/ui/widgets/main_content_states.dart';

void main() {
  group('EmptyLibraryState', () {
    testWidgets('renders empty state with icon and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: const Scaffold(body: EmptyLibraryState()),
        ),
      );

      expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('ErrorLoadingState', () {
    testWidgets('renders error icon, message and retry button', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: Scaffold(
            body: ErrorLoadingState(
              errorMessage: 'Test error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(retried, isTrue);
    });
  });
}
