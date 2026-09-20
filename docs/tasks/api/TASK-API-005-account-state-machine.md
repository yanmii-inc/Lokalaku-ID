---
id: TASK-API-005
title: "Account status state machine middleware"
milestone: M001
prd_ref: "REQ-BG-005"
app: api
status: done
priority: high
complexity: M
github_issue: null
dependencies: [TASK-API-003, TASK-API-004]
assigned_to: null
---

# TASK-API-005: Account Status State Machine Middleware

> **Milestone:** M001 — Foundation & Auth System
> **PRD Reference:** REQ-BG-005 (Role-Based Access / Account lifecycle enforcement)

---

## Objective

Enforce account lifecycle rules at two levels:

1. **Domain layer** — an explicit state machine (`CanTransition` / `TransitionStatus`) that codifies every legal status edge and rejects illegal moves with a typed error.
2. **Middleware layer** — `RequireActiveAccount` that reads the `status` claim from the JWT in context and returns `403` for any non-active account, without an extra DB round-trip.

---

## Acceptance Criteria

- [x] `domain.CanTransition(from, to)` returns `true` only for legal edges
- [x] `domain.TransitionStatus(from, to)` returns the new status or `ErrIllegalStatusTransition`
- [x] `deactivated` is a terminal state — no transitions out
- [x] `middleware.RequireActiveAccount` passes active tokens, returns `403` for suspended/pending/deactivated
- [x] `RequireActiveAccount` is wired after `RequireAuth` on the `/auth/me` protected route
- [x] All state machine tests pass; all middleware tests pass

---

## State Machine (legal edges)

```
pending     → active       (admin activates after verification)
pending     → deactivated  (admin rejects/purges unverified account)
active      → suspended    (admin suspends for review)
active      → deactivated  (admin permanently closes account)
suspended   → active       (admin reinstates)
suspended   → deactivated  (admin permanently closes suspended account)
deactivated → (terminal)   no further transitions
```

---

## Technical Notes

- Status claim is embedded in the JWT at login/OTP verify time. `RequireActiveAccount` reads it from context — zero DB cost per request. Status change propagates to clients on next token refresh.
- `RequireActiveAccount` is a plain `func(http.Handler) http.Handler` (not a factory) since it needs no configuration.
- Illegal transition errors wrap `ErrIllegalStatusTransition` so callers can use `errors.Is`.

---

## Files Changed

| File | Change |
|:---|:---|
| `internal/domain/auth.go` | MODIFIED — added `accountStatusTransitions` map, `ErrIllegalStatusTransition`, `CanTransition`, `TransitionStatus` |
| `internal/domain/state_machine_test.go` | NEW — 6 tests covering legal edges, illegal edges, terminal state, unknown status |
| `internal/middleware/auth.go` | MODIFIED — added `RequireActiveAccount` middleware |
| `internal/middleware/auth_test.go` | MODIFIED — added `TestRequireActiveAccountMiddleware` (5 cases) |
| `internal/router/router.go` | MODIFIED — applied `RequireActiveAccount` to the `/auth/me` protected group |

---

## Definition of Done

- [x] State machine and middleware implemented
- [x] All 32 tests pass (`go test ./...`)
- [x] `go vet` clean
- [x] `TASK-INDEX.md` status updated to `done`
