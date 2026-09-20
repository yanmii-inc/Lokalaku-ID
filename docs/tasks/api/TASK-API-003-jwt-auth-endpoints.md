---
id: TASK-API-003
title: "JWT auth endpoints (login, refresh, logout)"
milestone: M001
prd_ref: "REQ-BG-004"
app: api
status: done
priority: high
complexity: L
github_issue: null
dependencies: ["TASK-API-001", "TASK-API-002"]
assigned_to: null
---

# TASK-API-003: JWT auth endpoints (login, refresh, logout)

> **Milestone:** [M001 — Foundation & Auth System](../../milestones/M001-foundation-auth-system.md)  
> **PRD Reference:** [REQ-BG-004](../../apps/api/PRD.md) · [REQ-BG-005](../../apps/api/PRD.md#req-bg-005--role-based-access)  
> **Design Doc:** [docs/design/01-auth-flow.md](../../design/01-auth-flow.md)  
> **Linked ADR:** [ADR-003 — JWT + Refresh Token Strategy](../../decisions/003-jwt-refresh-token-strategy.md)

---

## Objective

Implement the authentication and token lifecycle service, endpoints, and middleware in `apps/api`:
1. `POST /auth/login` (email/phone + password credential verification)
2. `POST /auth/refresh` (opaque refresh token validation with mandatory rotation)
3. `POST /auth/logout` (session invalidation in Redis and database)
4. JWT validation middleware verifying token signatures, expiration, role, and extracting claims (`sub`, `role`, `village_cluster_id`, `status`) into context.

---

## Context

Per [ADR-003](../../decisions/003-jwt-refresh-token-strategy.md):
- **Access Tokens:** 15-minute JWT, HMAC-SHA256, contains `sub`, `role`, `village_cluster_id` (nullable), `status`. Verifiable statelessly.
- **Refresh Tokens:** 30-day random opaque tokens, hashed (SHA-256) and stored in Redis (with PostgreSQL `sessions` table backup), rotated upon every use.
- **Data Isolation:** `village_cluster_id` claim in JWT enables tenant isolation on subsequent API calls without database lookups.

---

## Acceptance Criteria

- [x] JWT service in `apps/api/internal/auth` can issue and validate JWT access tokens (HMAC-SHA256, 15m TTL).
- [x] Refresh token generator creates secure random opaque tokens, computes SHA-256 hash.
- [x] Session store interface with in-memory / Redis / DB implementations for refresh token storage, rotation, and revocation.
- [x] `POST /auth/login` validates credentials against hashed password using bcrypt, returns access + refresh tokens.
- [x] `POST /auth/refresh` accepts valid refresh token, revokes it, returns new access token and rotated refresh token.
- [x] `POST /auth/logout` revokes session.
- [x] Auth middleware validates `Authorization: Bearer <token>`, rejects expired or tampered tokens with 401 Unauthorized, injects claims into context.
- [x] Unit and integration tests covering token generation, verification, login, refresh rotation, logout, and middleware.
- [x] `go test ./...` and `go vet ./...` pass with 0 warnings.

---

## Out of Scope

- OTP issuance & verification endpoints (→ TASK-API-004)
- Account status transition middleware (→ TASK-API-005)
- Password reset emails (→ later milestone)

---

## Definition of Done

- [x] Auth service, handlers, and middleware implemented
- [x] Unit tests written and passing
- [x] Diagnostics clean (`go vet`)
- [x] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed (if linked)

