---
id: TASK-PKG-002
title: "core_auth: token storage, refresh timer, offline PIN"
milestone: M001
prd_ref: "REQ-BG-004"
app: pkg
status: done
priority: high
complexity: XL
github_issue: null
dependencies: [TASK-PKG-001]
assigned_to: null
---

# TASK-PKG-002: core_auth: token storage, refresh timer, offline PIN

> **Milestone:** [M001 — Core Foundation & Authentication Flow](../milestones/M001-foundation-and-auth.md)  
> **PRD Reference:** [REQ-BG-004](../../PRD.md#req-bg-004), [REQ-ME-004](../../PRD.md#req-me-004), [REQ-CO-004](../../PRD.md#req-co-004)  
> **Design Doc:** [docs/design/01-auth-flow.md](../../design/01-auth-flow.md), [ADR-003](../../decisions/003-jwt-refresh-token-strategy.md)

---

## Objective

Implement the `lokalaku_core_auth` package (`packages/flutter/core_auth`):
- Secure on-device token and account storage backed by `flutter_secure_storage`.
- Proactive token refresh timer (firing at ≤3 minutes before JWT access token expiry).
- Offline 6-digit PIN quick-auth and grace session for merchant POS operations.
- `AuthService` managing lifecycle states (`unauthenticated`, `authenticating`, `authenticated`, `offlineGrace`).

---

## Context

Per ADR-003, mobile apps store short-lived JWT access tokens in-memory and long-lived opaque refresh tokens in secure keychain storage (`flutter_secure_storage`).
Couriers require proactive background refresh to prevent mid-route telemetry disruption (`REQ-CO-004`).
Merchants require a local 6-digit PIN (stored as a salted hash, never sent to the server) that unlocks a temporary 8-hour offline session when connectivity is down (`REQ-ME-004`).

---

## Acceptance Criteria

- [x] AC1: `TokenStorage` securely persists and retrieves `AuthToken` (access + refresh token) and cached `Account` using `FlutterSecureStorage`.
- [x] AC2: `TokenStorage` supports offline 6-digit PIN management (salted SHA-256 hash storage, verification, attempt counting with lockout at 5 failed attempts).
- [x] AC3: `RefreshTokenTimer` proactively fires refresh callbacks at ≤3 minutes before access token expiry, with robust start/cancel lifecycle.
- [x] AC4: `AuthService` exposes `Stream<AuthState>` and current `AuthState` (`unauthenticated`, `authenticating`, `authenticated`, `offlineGrace`).
- [x] AC5: `AuthService` handles silent session restore on app start from secure storage.
- [x] AC6: `AuthService` supports offline PIN unlock granting `offlineGrace` mode during network outages.
- [x] AC7: Full test suite in `packages/flutter/core_auth/test/` with mock secure storage and fake async timers, passing clean.

---

## Technical Notes

- Flutter package (`environment: sdk: ">=3.3.0 <4.0.0", flutter: ">=3.19.0"`).
- Uses `flutter_secure_storage` for encrypted keychain storage.
- Pure crypto helper for local PIN hashing (SHA-256 + salt) without network dependency.
- Return `Result<T>` across public service boundaries per Rule 6 in `packages/flutter/AGENTS.md`.
- Test with: `flutter test` in `packages/flutter/core_auth`.

---

## Out of Scope

- Direct UI widgets or screens (screens live in `apps/<app>/`).
- Riverpod state notifiers (app-level notifiers consume `AuthService`).
- Offline database syncing (handled by `lokalaku_data`).

---

## Definition of Done

- [ ] Code written and self-reviewed
- [ ] Unit tests added in `packages/flutter/core_auth/test/`
- [ ] `flutter test` passing clean
- [ ] `dart analyze` passing clean
- [ ] `TASK-INDEX.md` status updated to `done`
