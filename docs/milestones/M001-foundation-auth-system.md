# M001: Foundation & Auth System

**Status:** `In Progress`  
**Period:** 2025 Q1 → Ongoing  
**Apps / Packages Affected:** `apps/api`, `packages/flutter/core_auth`, `packages/flutter/domain`, `packages/flutter/core_network`  
**Linked ADRs:** [ADR-001 — Riverpod v3](../decisions/001-riverpod-v3-state-management.md), [ADR-002 — Offline Local DB](../decisions/002-offline-first-local-db.md), [ADR-003 — JWT + Refresh Tokens](../decisions/003-jwt-refresh-token-strategy.md)  
**Linked Design Docs:** [`docs/design/01-auth-flow.md`](../design/01-auth-flow.md)  
**Linked Tasks:** See [TASK-INDEX.md](../tasks/TASK-INDEX.md) — M001 section.

---

## 1. Summary

Establish the foundational infrastructure that every other milestone depends on: the Golang API scaffold, the PostgreSQL + Redis data layer, the complete authentication and session system (JWT + opaque refresh token + OTP verification), the account status state machine, and the `core_auth` Flutter package that encapsulates the entire token lifecycle for all client apps.

---

## 2. Motivation & Problem Statement

No feature work can begin without a working API and a secure, role-aware auth system. The system must handle five distinct roles across six client apps, each with different session requirements (proactive refresh for couriers, offline PIN for merchants, non-persistent sessions for backoffice). Getting this wrong early creates pervasive security debt across the entire platform.

Additionally, the offline-first requirements (`REQ-ME-004`, `REQ-CO-004`) are tightly coupled to how auth tokens are managed client-side. These decisions must be made once, correctly, and encoded into the shared `core_auth` package so no app reinvents them.

---

## 3. Key Changes

| Area | What Changed | Notes |
|:---|:---|:---|
| `apps/api` | Go project scaffold, Chi router, structured logging, health endpoint | Single-binary, stateless design |
| `apps/api` | PostgreSQL schema: `accounts`, `sessions`, `otp_codes`, `audit_events` | Role-scoped, `village_cluster_id` on every tenant table |
| `apps/api` | JWT issuance (15 min) + opaque refresh token (30 day, Redis-backed) | See ADR-003 |
| `apps/api` | OTP issuance + verification endpoint (6-digit, 5-min TTL, rate-limited) | See REQ-BG-006 |
| `apps/api` | Account status state machine middleware (`pending → active → suspended`) | See REQ-BG-005 |
| `packages/flutter/domain` | `Account`, `Role`, `Session`, `AuthToken` entities | Pure Dart, no Flutter dependency |
| `packages/flutter/core_auth` | Token storage, proactive refresh timer, offline PIN challenge | Encapsulates all client-side auth logic |
| `packages/flutter/core_network` | Auth interceptor, 401 retry handler | Transparently attaches access tokens |

---

## 4. Decisions Made During This Milestone

### Decision: Riverpod v3 as the Exclusive State Management Solution
- **Context:** Needed a single state management approach across 5 apps and shared packages.
- **Choice:** Riverpod v3 with `Notifier<State>` + `NotifierProvider`. No other state management libraries permitted.
- **Rationale:** Compile-time safety, testability without Flutter environment, `autoDispose` for low-RAM devices.
- **Tradeoffs:** Contributors must learn v3 API; code generation step required.
- **ADR:** [ADR-001](../decisions/001-riverpod-v3-state-management.md)

### Decision: Hive + Isar for Offline Local Storage
- **Context:** Merchant POS and courier GPS require local persistence that survives process kills.
- **Choice:** Hive for sequential writes (sync queues, PIN hash); Isar for queryable merchant inventory.
- **Rationale:** Both are proven, Flutter-native, zero proprietary dependency.
- **Tradeoffs:** Two libraries vs. one; Isar requires native build step.
- **ADR:** [ADR-002](../decisions/002-offline-first-local-db.md)

### Decision: JWT 15min + Opaque Refresh Token 30d Strategy
- **Context:** Five roles, revocable sessions, offline continuity requirements.
- **Choice:** Short-lived stateless JWT for API auth; long-lived Redis-backed opaque refresh token for session continuity; rotation on every use.
- **Rationale:** Stateless validation per request, true revocation, proactive refresh for couriers, PIN fallback for merchants.
- **Tradeoffs:** Redis becomes a critical dependency; rotation introduces a reuse-window race condition.
- **ADR:** [ADR-003](../decisions/003-jwt-refresh-token-strategy.md)

### Decision: `village_cluster_id` Embedded in JWT Claims
- **Context:** Every API request needs to know the caller's cluster for data isolation (`REQ-BG-001`).
- **Choice:** Include `village_cluster_id` in JWT claims at issuance time.
- **Rationale:** Avoids a DB lookup per request. The cluster is a stable property of the account.
- **Tradeoffs:** Cluster reassignment (rare, superadmin-only) requires forced re-login.
- **ADR:** Covered inline in [ADR-003](../decisions/003-jwt-refresh-token-strategy.md), not a separate ADR.

---

## 5. Deferred Work

| Item | Moved To | Reason |
|:---|:---|:---|
| Hive/Isar implementation in merchant_app | [M003 — Merchant POS Offline](./CHANGELOG.md) | Auth system must exist before offline flow can be built on top of it |
| Consumer OTP registration (phone-only, no approval) | [M004 — Consumer Discovery](./CHANGELOG.md) | Consumer auth is simpler and can be implemented after core auth infra is solid |
| Courier proactive refresh (≤3 min timer) | [M005 — Courier Dispatch](./CHANGELOG.md) | Depends on courier route lifecycle — not meaningful without dispatch screens |

---

## 6. Lessons Learned

_To be filled in when the milestone is completed._

---

## 7. Follow-Up Actions

- [ ] Create `apps/api/GUARDRAILS.md` — concurrency, memory, and error handling constraints for the Go API
- [ ] Create `apps/website/GUARDRAILS.md` — SEO and bundle size constraints for the Astro website
- [ ] Create per-app `AGENTS.md` for `merchant_app`, `courier_app`, `wholesaler_app`, `backoffice_web`
- [ ] Add `docs/design/02-offline-sync-queue.md` before M003 begins
- [ ] Update TASK-INDEX.md as tasks complete
- [ ] Move CHANGELOG.md entry to "Completed" when milestone ships
