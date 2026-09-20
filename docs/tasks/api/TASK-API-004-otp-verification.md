---
id: TASK-API-004
title: "OTP issuance & verification endpoint"
milestone: M001
prd_ref: "REQ-BG-006"
app: api
status: done
priority: high
complexity: M
github_issue: null
dependencies: [TASK-API-003]
assigned_to: null
---

# TASK-API-004: OTP Issuance & Verification Endpoint

> **Milestone:** M001 — Foundation & Auth System
> **PRD Reference:** REQ-BG-006 (Immutable Audit Trail)

---

## Objective

Add phone-based OTP auth flow to the API: issue a 6-digit OTP for a phone number and verify it. On success for `purpose=auth`, return a JWT access token if the phone belongs to a registered account.

---

## Acceptance Criteria

- [x] `POST /auth/otp/request` — accepts `{phone, purpose}`, generates a 6-digit OTP, hashes and stores it, returns `{phone, purpose, expires_in_seconds}`
- [x] `POST /auth/otp/verify` — accepts `{phone, code, purpose}`, validates OTP, returns `{verified: true, token_pair?}` on success
- [x] OTP expires after 5 minutes
- [x] Maximum 5 failed attempts before OTP is locked
- [x] A new `RequestOTP` call invalidates any prior active OTP for the same phone+purpose
- [x] For `purpose=auth`: if phone has an active account, returns a full `TokenPairResponse`
- [x] For `purpose=auth`: if phone is unregistered, returns `{verified: true}` with no token pair
- [x] Plain-text OTP code is logged via `slog.Info` (dev-mode; production replaces with SMS)
- [x] Unit tests cover: happy path, wrong code, expiry, max attempts, duplicate request invalidation, empty inputs
- [x] HTTP integration tests cover: request→verify flow, missing phone → 400

---

## Technical Notes

- `OTPStore` interface + `MemoryOTPStore` — same pattern as `SessionStore` / `MemorySessionStore`
- OTP code: 6-digit, zero-padded, `crypto/rand` generated
- Code hash: SHA-256 via existing `HashToken()` — raw code never persisted
- Purpose field: `"auth"` (default) | `"phone_verify"` (extensible)
- HTTP status mapping:
  - Expired OTP → `422 Unprocessable Entity`
  - Max attempts → `429 Too Many Requests`
  - Already verified → `409 Conflict`
  - Wrong/not found → `401 Unauthorized` (avoid phone enumeration)

---

## Files Changed

| File | Change |
|:---|:---|
| `internal/auth/otp.go` | NEW — `OTPService`, `MemoryOTPStore`, `OTPStore` interface |
| `internal/auth/otp_test.go` | NEW — unit + HTTP integration tests |
| `internal/auth/handler.go` | MODIFIED — added `OTPService` field, `HandleOTPRequest`, `HandleOTPVerify` |
| `internal/auth/store.go` | MODIFIED — added OTP sentinel errors |
| `internal/router/router.go` | MODIFIED — wired `POST /auth/otp/request`, `POST /auth/otp/verify` |
| `internal/router/router_test.go` | MODIFIED — updated `router.New` call signature |
| `cmd/server/main.go` | MODIFIED — wire `OTPService` and pass to router |

---

## Definition of Done

- [x] `POST /auth/otp/request` and `POST /auth/otp/verify` implemented
- [x] All tests pass (`go test ./...`)
- [x] `go vet ./...` clean
- [x] `TASK-INDEX.md` status updated to `done`
