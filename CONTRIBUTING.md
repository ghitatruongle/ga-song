# Contributing to G.A - Song

## Development Setup

1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.44.0+
2. Clone the repository
3. Run `flutter pub get`
4. Run `flutter run` to start the app

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Run `dart format lib/` before committing
- Run `flutter analyze` — ensure 0 warnings

## Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/models/song_test.dart

# Run with coverage
flutter test --coverage
```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass: `flutter test`
5. Ensure no analyzer warnings: `flutter analyze`
6. Format code: `dart format lib/ test/`
7. Submit PR with clear description

## Branch Naming

- `feat/feature-name` — New features
- `fix/bug-description` — Bug fixes
- `refactor/area` — Code refactoring
- `docs/topic` — Documentation changes

## Architecture Guidelines

- **Models** should have no dependencies on services
- **Services** should depend only on models and other services
- **Providers** should be thin wrappers around services
- **UI** should depend only on providers and models
- Use `ValueNotifier` for reactive state within services
- Use Riverpod for widget tree dependency injection
