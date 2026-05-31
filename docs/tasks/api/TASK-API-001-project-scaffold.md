---
id: TASK-API-001
title: "Go project scaffold & Chi router setup"
milestone: M001
prd_ref: "—"
app: api
status: todo
priority: high
complexity: M
github_issue: null
dependencies: []
assigned_to: null
---

# TASK-API-001: Go project scaffold & Chi router setup

> **Milestone:** [M001 — Foundation & Auth System](../../milestones/M001-foundation-auth-system.md)  
> **PRD Reference:** _Not tied to a specific REQ — this is foundational infrastructure._  
> **Design Doc:** _N/A_

---

## Objective

Establish the canonical Go project layout for `apps/api`, including the Chi router, a structured logging middleware, graceful shutdown, and a `/health` endpoint. This is the skeleton every other API task builds on.

---

## Context

All API development depends on this scaffold. Per `apps/api/GUARDRAILS.md` (to be created), only lightweight routers (Chi or Fiber) are permitted — no enterprise frameworks. The API must compile to a single binary deployable via Docker Compose on a cheap Linux VPS (`compose.yaml` at repo root).

See also:
- [ADR-003 — JWT + Refresh Token Strategy](../../decisions/003-jwt-refresh-token-strategy.md) (the auth layer that mounts on top of this router)
- Global principle: zero vendor lock-in, single-binary friendly.

---

## Acceptance Criteria

- [ ] `apps/api/cmd/server/main.go` compiles and starts without errors.
- [ ] Chi router is wired in `apps/api/internal/router/router.go`.
- [ ] Structured JSON request logging middleware is mounted (use Go stdlib `log/slog` — no external logger).
- [ ] `GET /health` returns `{"status":"ok","version":"dev"}` with HTTP 200.
- [ ] Graceful shutdown: SIGTERM/SIGINT drains in-flight requests within a configurable timeout (default 10s), then exits cleanly.
- [ ] `apps/api/Dockerfile` builds the binary into a minimal `distroless/static` or `scratch` image.
- [ ] `go build ./apps/api/cmd/server` succeeds from the repo root.
- [ ] `go vet ./apps/api/...` passes with zero warnings.

---

## Technical Notes

**Project layout to use:**
```
apps/api/
├── cmd/
│   └── server/
│       └── main.go          ← entrypoint: wire deps, start server, handle signals
├── internal/
│   ├── config/
│   │   └── config.go        ← read env vars, no 3rd-party config library yet
│   ├── router/
│   │   └── router.go        ← chi.NewRouter(), mount middleware, register routes
│   └── middleware/
│       └── logger.go        ← slog structured request/response logging
├── Dockerfile
└── .air.toml                ← hot-reload config for local dev (optional)
```

**Logging format (slog):**
```go
slog.Info("request", "method", r.Method, "path", r.URL.Path, "status", ww.Status(), "duration_ms", elapsed.Milliseconds())
```

**Config via env vars only** — no Viper, no config files at this stage:
```go
type Config struct {
    Port            string // PORT, default "8080"
    ShutdownTimeout time.Duration // SHUTDOWN_TIMEOUT_SECONDS, default 10s
}
```

**Do NOT add** database, Redis, or auth at this stage — those are TASK-API-002 and TASK-API-003.

---

## Out of Scope

- Database connection or any ORM (→ TASK-API-002)
- Auth middleware or JWT logic (→ TASK-API-003)
- Redis integration (→ later)
- CORS or rate limiting middleware (→ can add in later tasks as needed)

---

## Definition of Done

- [ ] Code written and self-reviewed
- [ ] `go build ./apps/api/cmd/server` succeeds
- [ ] `go vet ./apps/api/...` passes
- [ ] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed (link in frontmatter above)
