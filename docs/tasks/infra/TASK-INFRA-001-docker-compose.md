---
id: TASK-INFRA-001
title: "Docker Compose for local development"
milestone: INFRA
prd_ref: "—"
app: infra
status: todo
priority: high
complexity: M
github_issue: 2
dependencies: []
assigned_to: null
---

# TASK-INFRA-001: Docker Compose for local development

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** _Not applicable_

---

## Objective

Provide a canonical `docker-compose.dev.yml` at the repo root to run the API, Postgres, Redis, and developer tooling for local development and CI.

---

## Context

Local development must be reproducible and fast for contributors and CI. The compose file should support:
- `apps/api` (build from local Dockerfile)
- PostgreSQL (dev database + user)
- Redis (sessions/tokens)
- Optional dev-only services like admin UIs or mock services

Refer to `docs/infra/REQUIREMENTS.md` for infra constraints.

---

## Acceptance Criteria

- [ ] `docker-compose.dev.yml` exists at repo root with services: `api`, `postgres`, `redis`
- [ ] Postgres uses a named volume and has example init scripts or supports a seed step (TASK-INFRA-002)
- [ ] README includes start/stop/reset instructions
- [ ] Compose is usable in CI for integration tests (no interactive prompts)

---

## Technical Notes

- Use a separate compose file for dev (`docker-compose.dev.yml`) and avoid committing production creds.
- Expose ports on localhost only.
- Use `.env.example` for env variables.
- Keep service images minimal and reproducible.

---

## Out of Scope

- Production orchestrator manifests (Kubernetes/Helm)
- Secrets management or vault integration

---

## Definition of Done

- [ ] Code written and self-reviewed
- [ ] Documentation added to README
- [ ] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
