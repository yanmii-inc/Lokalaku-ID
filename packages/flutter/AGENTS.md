# 📦 AGENTS.md — Shared Flutter/Dart Packages (`packages/flutter/`)

This file governs all AI agent behaviour when working inside `packages/flutter/`.
These packages are the shared foundation consumed by all Flutter apps in `apps/`.

---

## Package Map & Responsibilities

| Package | Dart SDK only? | Responsibility |
| :--- | :---: | :--- |
| `lokalaku_domain` | ✅ | Entities, value objects, enums, repository interfaces, `Result<T>` type |
| `lokalaku_utils` | ✅ | Rupiah formatter, date helpers, validators, string/datetime extensions |
| `lokalaku_core_network` | ✅ | HTTP client (Dio), auth interceptor, retry logic, API error models |
| `lokalaku_core_auth` | ❌ Flutter | Auth service, token storage (secure), login/logout/refresh |
| `lokalaku_data` | ❌ Flutter | Repository implementations — bridges domain ↔ network ↔ auth |
| `lokalaku_ui_kit` | ❌ Flutter | Design tokens, theme, and shared widgets. Zero logic. Zero network. |

---

## Strict Dependency Graph

```
                    ┌──────────────┐
                    │   apps/*     │  (consumers — import what they need)
                    └──────┬───────┘
           ┌───────────────┼──────────────┐
           ▼               ▼              ▼
      lokalaku_ui_kit  lokalaku_data  lokalaku_utils
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
       lokalaku_core_auth  ...    lokalaku_core_network
              │                          │
              └──────────┬───────────────┘
                         ▼
                  lokalaku_domain   ◄── depends on nothing internal
```

**Rules enforced by this graph:**
- `domain` → imports nothing from other `lokalaku_*` packages.
- `utils` → imports nothing from other `lokalaku_*` packages.
- `core_network` → may only import `domain`.
- `core_auth` → may only import `domain` and `core_network`.
- `data` → may import `domain`, `core_network`, and `core_auth`.
- `ui_kit` → imports nothing from any other `lokalaku_*` package.
- **Apps** → import whatever packages they need; never import from other apps.
- **Packages** → never import from `apps/`.

Violating this graph creates circular dependencies. Reject any suggestion that breaks it.

---

## Non-Negotiable Rules

1. **`publish_to: none`** must be present in every `pubspec.yaml` in this directory. These packages are internal and must never be published to pub.dev.
2. **No app-specific logic** in shared packages. POS flows, GPS tracking, offline sync queues, PWA service worker registration — these belong in the respective app, not here.
3. **`domain` is Flutter-free.** Never add `flutter:` as a dependency to `lokalaku_domain` or `lokalaku_utils`. They must remain pure Dart so they can be tested without a Flutter environment.
4. **`ui_kit` is logic-free.** Never add business logic, network calls, or state management to `lokalaku_ui_kit`. It is a widget and token library only.
5. **No raw primitives in `ui_kit`.** No `Colors.*`, `TextStyle(...)`, or hardcoded hex values. All values must be defined as named tokens in `AppColors`, `AppTypography`, `AppSpacing`.
6. **`Result<T>` everywhere.** All repository methods (interfaces in `domain`, implementations in `data`) must return `Result<T>`. Never throw raw exceptions across package boundaries.
7. **Always use package imports.** `import 'package:lokalaku_domain/lokalaku_domain.dart'` — never relative imports across package boundaries.

---

## Moon Tasks

This monorepo uses **Moon** as the task runner. Each package has a `moon.yml` that inherits shared tasks from `.moon/tasks/dart.yml`.

### Common commands

```bash
# Run a task in one package
moon run domain:get
moon run ui_kit:lint
moon run domain:test

# Run a task across all Dart packages (Moon respects dependency order)
moon run :get
moon run :lint
moon run :test
moon run :format

# Code generation (only domain and data define this task)
moon run domain:build-runner
moon run data:build-runner

# Check the dependency/task graph
moon project domain
moon dep-graph
```

Moon automatically runs tasks in dependency order — e.g., running `:get` on `core_auth` will first run `get` on `domain` and `core_network` because of their `dependsOn` declarations in `moon.yml`.

Never manually edit `*.freezed.dart` or `*.g.dart` files — always use `moon run <package>:build-runner`.

---

## Testing

Each package must have its own `test/` directory.

```bash
# Test all Dart packages
moon run :test

# Test a single package
moon run domain:test
```

Pure Dart packages (`domain`, `utils`, `core_network`) must be testable without a Flutter environment.

---

## Adding a New Package

1. Create `packages/flutter/<package_name>/` with `pubspec.yaml`, `analysis_options.yaml`, `lib/<name>.dart`, and `moon.yml`.
2. The workspace glob `packages/flutter/*` in `.moon/workspace.yml` already picks it up — no registration needed.
3. Name it `lokalaku_<package_name>` in `pubspec.yaml`.
4. Set `language: dart` and declare `dependsOn` in `moon.yml`.
5. Document its place in the dependency graph above.
6. Set `publish_to: none`.
