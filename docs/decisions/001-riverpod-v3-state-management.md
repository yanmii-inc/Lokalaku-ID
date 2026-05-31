# ADR-001: Riverpod v3 as the Exclusive State Management Solution

**Status:** `Accepted`  
**Date:** 2025-01-01  
**Decider(s):** Project Lead  
**Context Area:** Cross-cutting — all Flutter apps and `packages/flutter`

---

## Context

All five Flutter apps (consumer, merchant, courier, wholesaler, backoffice) needed a unified state management approach. The architecture requires:

- Compile-time safety for state mutations (catch errors before runtime)
- Testability at the notifier level without a full running Flutter environment
- An offline-first architecture with async state that survives navigation and app lifecycle events
- Code generation support to reduce repetitive boilerplate
- A single paradigm for all contributors to learn — no per-app variation

Multiple competing state management solutions exist in the Flutter ecosystem and choosing different ones per app would fragment contributor knowledge and make shared `packages/flutter` packages inconsistent.

---

## Decision

Use **Riverpod v3+ exclusively**, with the `Notifier<State>` + `NotifierProvider` API pattern throughout all apps and shared packages.

Specifically:
- All state is expressed as `Notifier<State>` or `AsyncNotifier<State>`.
- All providers use `NotifierProvider` or `AsyncNotifierProvider`.
- `autoDispose` variants are the default on all feature-scoped providers.
- `ref.read()` is **never** called inside `build()` methods.
- `@riverpod` annotation + `riverpod_generator` is used for complex features to eliminate manual boilerplate.

---

## Rationale

- **Compile-time safety:** Provider types are fully typed. Mismatches are caught at compile time, not at runtime on a low-end Android device in the field.
- **No inheritance boilerplate:** Unlike BLoC's `Bloc`/`Cubit` hierarchy, `Notifier` is a plain Dart class with a single `build()` method. Easier to read and review.
- **Testability:** Riverpod providers can be overridden in tests using `ProviderContainer` without a full widget tree. This matters especially for `packages/flutter/domain` and `data` which need unit tests in pure Dart.
- **`StateNotifier` removal in v3:** Riverpod v3 removes deprecated `StateNotifier`/`StateNotifierProvider` APIs entirely, forcing a clean break from legacy patterns. We adopt v3 from the start to avoid a future migration.
- **Code generation:** `@riverpod` + `riverpod_generator` eliminates manual provider boilerplate in feature-heavy screens. Run via `moon run <app>:build-runner`.
- **Community trajectory:** Riverpod is the recommended path for complex state in offline-capable Flutter apps. Long-term support is well-established.

---

## Consequences

### Positive
- Uniform patterns across all 5 apps — contributors can switch context without re-learning a paradigm.
- Strong notifier-level testability, independent of widgets.
- `autoDispose` reduces RAM pressure on low-end Android devices.
- Code generation reduces diff noise in PRs.

### Negative / Tradeoffs
- Riverpod v3 API differs significantly from v1/v2 — contributors familiar with older Riverpod must unlearn `StateNotifierProvider`.
- `riverpod_generator` adds a build step: code generation must run after modifying `@riverpod`-annotated files. Agents must run `moon run <app>:build-runner` after changes.

### Neutral
- Any v2-era `StateNotifierProvider` usage found in the codebase must be migrated before adding new code using the old pattern.

---

## Alternatives Considered

| Option | Why Rejected |
|:---|:---|
| **BLoC / flutter_bloc** | Verbose event/state class hierarchy. Harder to test in pure-Dart environments without widget binding. Does not align with low-boilerplate goal for high-velocity development. |
| **GetX** | Opinionated "magic" via `Get.find()` creates hidden dependencies. Weak testability. Not recommended for complex, multi-layer architectures. |
| **Provider (v4/v5)** | Superseded by Riverpod from the same author. Lacks compile-time safety and code generation support. |
| **ChangeNotifier / InheritedWidget** | Too low-level for feature-scale state. No built-in async, disposal, or code generation support. |
| **Signals (dart)** | Immature ecosystem at time of decision. No production track record in offline-first Flutter apps at our scale. |

---

## Related

- **PRD Requirement(s):** _Not tied to a specific REQ — cross-cutting architecture constraint._
- **Enforced in:** `AGENTS.md`, `packages/flutter/AGENTS.md`, all `apps/*/AGENTS.md`
- **Milestone:** [M001 — Foundation & Auth System](../milestones/M001-foundation-auth-system.md)
- **Supersedes:** _none_
- **Superseded by:** _none_
