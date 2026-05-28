# consumer_app

A Flutter mobile application built with Clean Architecture, Riverpod, GoRouter, and slang. Pinned to **Flutter 3.44.0**.

## Architecture

The application follows a four-layer clean architecture combined with feature-first organization:

1. **Presentation** — widgets, controllers, states. Lives under `pages/<feature>/presentation/`.
2. **Application** — optional services that bridge presentation ↔ domain. Lives under `pages/<feature>/application/`.
3. **Domain** — entities (plain Dart objects) and abstract repository interfaces. Lives under `common/domain/`.
4. **Data** — repositories, DTOs, mappers, and data sources (remote/local). Lives under `common/data/`.

State management is **Riverpod** throughout. No BLoC, no GetX, no Provider.

### Project Structure

```
lib/
├── i18n/                            # Slang translation JSON files
│   ├── strings_en.i18n.json         # Base locale (English)
│   └── translations.g.dart          # Generated — never edit
├── core/
│   └── network/
│       └── api_client.dart          # Dio HTTP client provider
└── src/
    ├── app/
    │   └── runner.dart              # App bootstrap (Firebase, slang, Riverpod)
    ├── common/
    │   ├── data/                    # Repositories, DTOs, mappers, data sources
    │   └── domain/                  # Entities and abstract repository interfaces
    ├── pages/
    │   └── <feature>/
    │       ├── application/
    │       └── presentation/
    │           ├── <feature>_screen.dart
    │           ├── <feature>_controller.dart
    │           └── <feature>_state.dart
    ├── common_widgets/
    ├── constants/
    ├── routing/routes.dart
    └── utils/extensions/
```

## Getting Started

> **First run after `moon generate`?** Run this immediately:
> ```sh
> moon run consumer_app:init
> ```
> This scaffolds native Android/iOS and merges VS Code launch configs — all in one step.

**Subsequent runs — install dependencies:**
```sh
moon run consumer_app:install
```


## Common Tasks

```sh
moon run consumer_app:install         # Install pub dependencies
moon run consumer_app:test            # Run unit tests
moon run consumer_app:lint            # Run flutter analyze
moon run consumer_app:format          # Format lib/ and test/
moon run consumer_app:build           # Build APK
moon run consumer_app:clean           # Clean build artifacts
```

## VS Code

After running `moon run consumer_app:init`, a generic debug configuration is available in your workspace `.vscode/launch.json`. You can debug using the normal VS Code launch tools.

## Testing

```sh
moon run consumer_app:test                                  # Run all unit tests
flutter test test/path/to/test_file.dart                   # Run a single test file
```

Tests live in `test/` and mirror the `lib/src/` structure. All repository methods return `Result<T>` — test both `success` and `failure` variants using `mocktail`.

## Generated Sources

`*.freezed.dart`, `*.g.dart`, and `translations.g.dart` are generated — never edit them manually. Always commit them.

```sh
dart run build_runner build --delete-conflicting-outputs   # Freezed + json_serializable
dart run slang                                             # Regenerate i18n translations
```

## Localization

Uses [slang](https://pub.dev/packages/slang). Translation files live in `lib/i18n/strings_{locale}.i18n.json`.

- Base locale: **English** (`en`)
- After editing any `.i18n.json`, run `dart run slang` to regenerate `translations.g.dart`
- Access translations inside widgets via `final t = Translations.of(context);`

## Scaffold a New Feature

```sh
mkdir -p lib/src/pages/<feature>/presentation
mkdir -p lib/src/pages/<feature>/application
touch lib/src/pages/<feature>/presentation/<feature>_screen.dart
touch lib/src/pages/<feature>/presentation/<feature>_controller.dart
touch lib/src/pages/<feature>/presentation/<feature>_state.dart
```

> Register the new screen in `lib/src/routing/routes.dart`. Export each new file from its layer's barrel file.

## Networking

A pre-configured [Dio](https://pub.dev/packages/dio) HTTP client is available via `dioProvider` in `lib/core/network/api_client.dart`. Inject it into your repository providers using Riverpod:

```dart
final myRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return MyRepository(dio);
});
```

Update the `baseUrl` in `api_client.dart` to match your environment's API endpoint.
