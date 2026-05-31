# ADR-003: Short-Lived JWT + Long-Lived Opaque Refresh Token Auth Strategy

**Status:** `Accepted`  
**Date:** 2025-01-01  
**Decider(s):** Project Lead  
**Context Area:** `apps/api`, `packages/flutter/core_auth`

---

## Context

`REQ-BG-004` defines the authentication token architecture. The platform serves five distinct roles across six client apps. Requirements include:

- Access tokens must be stateless and verifiable without a DB round-trip on every request.
- Sessions must be **revocable** immediately (on logout, password reset, or account suspension).
- Role boundaries must be enforced per-request, not just at login.
- Couriers need proactive token refresh mid-route without interrupting live GPS telemetry (`REQ-CO-004`).
- Merchants need an offline PIN grace session when tokens expire off-network (`REQ-ME-004`).
- Backoffice sessions must auto-expire after 30 minutes of inactivity and not persist across tab closes (`REQ-SA-004`).

---

## Decision

**Access Tokens:** Short-lived JWT (15-minute expiry). HMAC-SHA256 signed. Claims: `sub` (account ID), `role`, `village_cluster_id`, `status`, `iat`, `exp`. No DB lookup needed to validate — the API checks signature and `exp` inline.

**Refresh Tokens:** Long-lived opaque random tokens (30-day expiry for mobile; cleared on tab close for backoffice). Stored server-side in Redis, keyed by a hash of the token value. **Rotated on every use** — each successful refresh invalidates the current token and issues a new one. Immediately invalidated on logout or password reset (Redis delete).

**Client storage per app:**

| App | Access Token | Refresh Token |
|:---|:---|:---|
| Mobile apps (merchant, courier, consumer, wholesaler) | In-memory Riverpod provider | `flutter_secure_storage` (encrypted on-device keychain) |
| Backoffice Web | In-memory Riverpod provider | `sessionStorage` (cleared on tab close) |

**Courier proactive refresh:** `core_auth` starts a timer at login that fires at ≤3 minutes remaining on the access token lifetime, triggering a background refresh before expiry.

**Merchant offline PIN:** When the device is offline and the access token expires, `core_auth` presents a local PIN challenge. The PIN is stored locally as a bcrypt hash — never transmitted. Background refresh is queued and executed when connectivity returns.

---

## Rationale

- **Stateless access token:** Low API latency — no DB round-trip per request. If a token is leaked, it expires within 15 minutes with no server action needed.
- **Opaque refresh token with server-side storage:** True revocation. A suspended account can have its token deleted from Redis immediately, blocking any further refresh. JWT-only approaches cannot achieve this without a denylist (which has its own cost).
- **Rotation:** A stolen refresh token is single-use. If rotation is detected (two refresh attempts with the same token), both can be invalidated, signalling a possible token theft.
- **Proactive courier refresh:** Prevents a hard auth failure mid-route that would cause GPS data loss — aligns with `REQ-CO-004`'s guarantee that no location data may be silently discarded.
- **Offline PIN continuity:** Preserves the merchant's POS flow during network outages without exposing credentials — the PIN never leaves the device.
- **`village_cluster_id` in JWT claims:** Avoids a DB lookup per request to resolve the cluster. Tradeoff: if a merchant is reassigned to a different cluster, they must re-login.

---

## Consequences

### Positive
- Stateless access token validation = low per-request latency across all API endpoints.
- True session revocation without coordination across API replicas.
- Proactive refresh prevents mid-route telemetry failures for couriers.
- Offline PIN preserves merchant POS continuity through network outages.
- Rotation makes stolen refresh tokens single-use.

### Negative / Tradeoffs
- Redis is a critical runtime dependency for refresh token validation. If Redis is unavailable, the API falls back to a PostgreSQL sessions table (slower path — plan for this in `GUARDRAILS.md`).
- Token rotation introduces a race condition if two requests fire simultaneously with the same refresh token (e.g., app resuming from background). Mitigation: accept reuse within a 30-second reuse window (industry standard practice).
- `village_cluster_id` embedded in the JWT means a cluster reassignment requires a forced re-login. This is acceptable for the current scale (reassignment is rare, superadmin-initiated).

### Neutral
- The entire token lifecycle (storage, refresh, proactive timer, PIN challenge) is encapsulated in `packages/flutter/core_auth`. No app reimplements auth logic.

---

## Alternatives Considered

| Option | Why Rejected |
|:---|:---|
| **Long-lived JWT only (no refresh)** | No revocation mechanism. A compromised token is valid until its `exp`. Unacceptable for a platform handling financial transactions. |
| **Server-side sessions only (stateful cookies)** | Requires a shared session store across API replicas. Works against the stateless, single-binary deployment goal. Complicates horizontal scaling. |
| **Firebase Auth** | Proprietary cloud dependency. Conflicts directly with zero-vendor-lock-in principle. Village cooperatives cannot self-host Firebase. |
| **Paseto tokens** | More cryptographically sound than JWT (no algorithm confusion attacks), but not natively supported by the Go JWT ecosystem at scale. Marginal security improvement does not justify the ecosystem switching cost at this stage. |
| **OAuth2 / OIDC (full flow)** | Overkill for a closed-platform ecosystem with well-defined roles. Adds complexity (authorization server, client registration) that isn't justified by the threat model. |

---

## Related

- **PRD Requirement(s):** `REQ-BG-004`, `REQ-ME-004`, `REQ-CO-004`, `REQ-SA-004`
- **Design Doc:** [`docs/design/01-auth-flow.md`](../design/01-auth-flow.md)
- **Package:** `packages/flutter/core_auth`
- **Milestone:** [M001 — Foundation & Auth System](../milestones/M001-foundation-auth-system.md)
- **Supersedes:** _none_
- **Superseded by:** _none_
