---
id: TASK-PKG-001
title: "domain entities: Account, Role, Session, AuthToken"
milestone: M001
prd_ref: "REQ-BG-004"
app: pkg
status: done
priority: high
complexity: S
github_issue: null
dependencies: []
assigned_to: null
---

# TASK-PKG-001: domain entities: Account, Role, Session, AuthToken

> **Milestone:** [M001 — Core Foundation & Authentication Flow](../milestones/M001-foundation-and-auth.md)  
> **PRD Reference:** [REQ-BG-004](../../PRD.md#req-bg-004), [REQ-BG-005](../../PRD.md#req-bg-005)  
> **Design Doc:** [packages/flutter/AGENTS.md](../../packages/flutter/AGENTS.md)

---

## Objective

Create the pure Dart domain entities, enums, value objects, and Result type in `lokalaku_domain` (`packages/flutter/domain`) to support authentication and account state management across all Flutter apps.

---

## Context

The Go API core (`apps/api`) has established the domain models and API contracts for authentication, roles, tokens, and account lifecycle (`TASK-API-001` through `TASK-API-005`).
All Flutter client applications (`consumer_app`, `merchant_app`, `courier_app`, `wholesaler_app`, `backoffice_web`) rely on `lokalaku_domain` as their shared domain entity foundation.
`lokalaku_domain` is strictly pure Dart — no Flutter dependencies, no network, no storage.

---

## Acceptance Criteria

- [x] AC1: `Role` enum defined with `consumer`, `merchant`, `courier`, `wholesaler`, `backofficeAdmin`, `superadmin`, with `isClusterBound` helper matching platform data sovereignty rules.
- [x] AC2: `AccountStatus` enum defined with `pending`, `active`, `suspended`, `deactivated`, with `canTransitionTo(AccountStatus next)` transition table adhering to domain rules.
- [x] AC3: `Account` entity modeled with JSON serialization, equality, and validation (`validate()`).
- [x] AC4: `Session` and `AuthToken` (or `TokenPair`) entities modeled with helper methods for expiration and validity (`isExpired`, `expiresSoon`, `isActive`).
- [x] AC5: `Result<T>` type defined (`Success<T>`, `Failure<T>`) for standard repository returns across package boundaries.
- [x] AC6: Exported via `lib/lokalaku_domain.dart` with package imports.
- [x] AC7: Pure Dart unit test suite in `packages/flutter/domain/test/` passing clean with 100% core logic coverage.

---

## Technical Notes

- Pure Dart only (`sdk: ">=3.3.0 <4.0.0"`). Do NOT import Flutter or internal packages.
- Follow immutable data modeling practices (Freezed / modern Dart pattern matching & sealed classes).
- Result type must satisfy Rule 6 in `packages/flutter/AGENTS.md` ("Result<T> everywhere").
- Test with: `dart test` inside `packages/flutter/domain` (or `moon run domain:test`).

---

## Out of Scope

- Token secure storage or persistence (belongs in `lokalaku_core_auth` / `TASK-PKG-002`).
- HTTP interceptors or Dio networking (belongs in `lokalaku_core_network` / `TASK-PKG-003`).
- Repository implementations (belongs in `lokalaku_data`).

---

## Definition of Done

- [ ] Code written and self-reviewed
- [ ] Unit tests added in `packages/flutter/domain/test/`
- [ ] `dart analyze` / `dart test` clean
- [ ] `TASK-INDEX.md` status updated to `done`
