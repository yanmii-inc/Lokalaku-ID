---
id: TASK-PKG-003
title: "core_network: auth interceptor & 401 retry"
milestone: M001
prd_ref: "REQ-BG-004"
app: pkg
status: in-progress
priority: high
complexity: M
github_issue: null
dependencies: [TASK-PKG-001]
assigned_to: null
---

# TASK-PKG-003: core_network: auth interceptor & 401 retry

> **Milestone:** [M001 — Core Foundation & Authentication Flow](../milestones/M001-foundation-and-auth.md)  
> **PRD Reference:** [REQ-BG-004](../../PRD.md#req-bg-004)  
> **Design Doc:** [docs/design/01-auth-flow.md](../../design/01-auth-flow.md), [ADR-003](../../decisions/003-jwt-refresh-token-strategy.md)

---

## Objective

Implement the `lokalaku_core_network` package (`packages/flutter/core_network`):
- `ApiClient`: Configured Dio HTTP client with standard timeouts, base URL, and logging.
- `AuthInterceptor`: Automatically attaches `Authorization: Bearer <token>` to requests and transparently queues and retries requests on HTTP 401 via token refresh callback.
- `RetryInterceptor`: Transparent retry with exponential backoff for transient network errors and 5xx failures.
- Standardized `ApiError` and `ApiResponse<T>` models mapping cleanly to `Result<T>`.

---

## Context

`lokalaku_core_network` is a pure Dart package (zero Flutter SDK dependencies) providing the foundation for all remote network calls.
Per ADR-003 and REQ-BG-004, access tokens expire after 15 minutes. When an HTTP 401 Unauthorized error occurs, the `AuthInterceptor` must:
1. Prevent duplicate concurrent refresh calls by synchronizing on an in-flight refresh mutex/lock.
2. Trigger the provided `onRefreshToken` callback.
3. If refresh succeeds, replay the queued requests with the new access token.
4. If refresh fails, reject queued requests and invoke the `onAuthFailure` callback (clearing session).

---

## Acceptance Criteria

- [ ] AC1: `ApiClient` provides configured Dio instance with default timeouts (connect, receive, send), JSON headers, and extensible interceptor pipeline.
- [ ] AC2: `AuthInterceptor` automatically injects `Authorization: Bearer <token>` unless request specifies `@NoAuth` / `requiresAuth: false`.
- [ ] AC3: `AuthInterceptor` intercepts HTTP 401, pauses concurrent requests, invokes refresh callback, and replays failed request with new token.
- [ ] AC4: `AuthInterceptor` handles refresh failure by notifying `onAuthFailure` and rejecting queued requests without infinite loops.
- [ ] AC5: `RetryInterceptor` retries idempotent requests on transient socket/connection errors with exponential backoff and jitter.
- [ ] AC6: `ApiError` and `ApiResponse<T>` models cleanly map HTTP status codes and error JSON payloads.
- [ ] AC7: Pure Dart test suite in `packages/flutter/core_network/test/` passing clean with 100% logic coverage.

---

## Technical Notes

- Pure Dart only (`sdk: ">=3.3.0 <4.0.0"`). No Flutter SDK or internal imports other than `lokalaku_domain`.
- Use `dio: ^5.6.0` interceptor architecture (`QueuedInterceptor` or synchronized request queuing to prevent refresh stampedes).
- Test with: `dart test` inside `packages/flutter/core_network` (or `moon run core_network:test`).

---

## Out of Scope

- Token secure storage (belongs in `lokalaku_core_auth`).
- Offline database caching (belongs in `lokalaku_data`).

---

## Definition of Done

- [ ] Code written and self-reviewed
- [ ] Unit tests added in `packages/flutter/core_network/test/`
- [ ] `dart test` passing clean
- [ ] `dart analyze` passing clean
- [ ] `TASK-INDEX.md` status updated to `done`
