# AGENTS.md

This file provides guidance to AI coding agents (Claude, Gemini, Cursor, etc.) when working with code in this repository.

## Commands

```bash
flutter pub get
flutter analyze
dart format lib/ test/
flutter test
flutter test test/path/to/test_file.dart
dart run build_runner build --delete-conflicting-outputs
dart run slang
```

Always run with a flavor. See the **Flavoring** section below.

---

## Tooling

This project uses `flutter_flavorizr` for multi-flavor support (`dev`, `stg`, `prd`).

### Flutter Version Manager

Depending on the version manager chosen during project generation, use the appropriate command prefix:

**No version manager:**
```bash
flutter pub get
flutter run --flavor dev
flutter build apk --flavor prd
```

**FVM (Flutter Version Management):**
```bash
fvm flutter pub get
fvm flutter run --flavor dev
fvm flutter build apk --flavor prd
```

Always check `.fvm/fvm_config.json` for the pinned Flutter version. Do **not** run bare `flutter` commands in an FVM project — always prefix with `fvm`.

**Puro:**
```bash
puro flutter pub get
puro flutter run --flavor dev
puro flutter build apk --flavor prd
```

Always check `.puro.json` for the pinned environment. Do **not** run bare `flutter` commands in a Puro project — always prefix with `puro`.

---

## Design System

No raw Flutter primitives (`Colors.*`, `TextStyle(...)`, `BoxShadow(...)`) when a design-system equivalent exists. Define your design tokens in `lib/src/constants/` (e.g. `AppColors`, `AppTypography`, `AppSpacing`) and reusable widgets in `lib/src/common_widgets/`.

---

## Architecture

Four layers: **Presentation** / **Application** / **Domain** / **Data**. State management is Riverpod throughout — no BLoC, GetX, or Provider.

Feature-First for presentation/application, Layer-First for domain/data shared across features.

---

## Before Writing Code

Search before creating. Check `common_widgets/`, `utils/extensions/`, `constants/`, `common/data/`, `common/domain/` first.

---

## Naming

Snake\_case files, PascalCase classes. Suffixes: `_screen`, `_controller`, `_state`, `_widget`, `_response`, `_request`. Domain entities have no suffix.

---

## Code Style

Two-space indent, trailing commas, line-break each param after 2+ params. Widget keys on every screen. Split large trees into classes, not helper methods. Use stateless widget instead of function widget to improve performance. No hardcoded colors or text styles.

---

## Riverpod (v3.x)

`StateNotifier`/`StateNotifierProvider` are removed. Use `Notifier<State>` + `NotifierProvider.autoDispose`. `AutoDisposeNotifier` does not exist. NEVER use `ref.read()` inside `build()` methods.

---

## Result\<T\> and Error Handling

All repository methods return `Result<T>`. Never throw raw exceptions to the UI. Always import `config.dart` directly in files calling `.when()` / `.maybeWhen()` — extension methods are not transitively imported.

---

## Localization

Uses **slang** (`slang` + `slang_flutter`). Translation files live in `lib/i18n/strings_{locale}.i18n.json`. Run `dart run slang` after editing any `.i18n.json` to regenerate `translations.g.dart`. Never edit `*.g.dart` files manually. Access translations via `final t = Translations.of(context);` inside widgets.

---

## Flavoring

Three flavors: `dev`, `stg`, `prd`. Runtime access via `F.appFlavor` / `F.title`. Environment-specific values (e.g. API URLs) must be injected via `--dart-define=KEY=value` — never hardcoded in source.

---

## Routing

Uses GoRouter. Routes in `lib/src/routing/routes.dart`. No nested navigators where a parent redirects to its own child.

---

## Security and Logging

No `print()` or `debugPrint()` — use `log()` from `dart:developer`. No sensitive data in `SharedPreferences` — use `flutter_secure_storage` or equivalent secure storage. Every caught error must be logged.

---

## Generated Sources

`*.freezed.dart`, `*.g.dart` — never edit manually, always commit.
