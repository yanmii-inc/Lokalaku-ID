---
id: TASK-INFRA-005
title: "Backend CD pipeline (Docker, GHCR, VPS deploy on PR merge)"
milestone: INFRA
prd_ref: "REQ-INFRA-053"
app: infra
status: done
priority: high
complexity: M
github_issue: null
dependencies: ["TASK-INFRA-001"]
assigned_to: null
---

# TASK-INFRA-005: Backend CD pipeline (Docker, GHCR, VPS deploy on PR merge)

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** [REQ-INFRA-052, REQ-INFRA-053](../../infra/REQUIREMENTS.md)  
> **Design Doc:** _Not applicable_

---

## Objective

Build an automated Continuous Deployment (CD) workflow in GitHub Actions that triggers when a pull request modifying `apps/api` or database migrations is merged into `main`, building a minimal distroless production container image, pushing to GitHub Container Registry (GHCR), executing pending database migrations, and updating the API service on the target VPS.

---

## Context

Lokalaku operates on a low-cost Linux VPS adhering to REQ-INFRA-001 (single-host deployability) and REQ-INFRA-041 (minimal container attack surface). When pull requests modifying `apps/api` or `apps/api/migrations` merge to `main`, deployment must happen automatically without manual SSH interventions or risks of partial state corruption.

Before a dedicated VPS is provisioned, developers expose the local or staging backend using a zero-cost HTTPS tunnel (Option 1: Cloudflare Tunnel). The CD pipeline builds the Docker image and pushes to GHCR unconditionally, while the VPS SSH deployment step executes conditionally only when `VPS_HOST` secrets are configured.

Database migrations must run and verify schema health before the new API service version starts serving public traffic.

---

## Acceptance Criteria

- [x] GitHub Actions workflow `.github/workflows/cd-backend.yml` triggers on push to `main` with path filters (`apps/api/**`, `docker-compose.prod.yml`, `.github/workflows/cd-backend.yml`).
- [x] Multi-stage production Docker build produces a minimal distroless/scratch image under 30MB running as an unprivileged user.
- [x] Workflow authenticates with GHCR, tags the image with git SHA and `latest`, and pushes the image.
- [x] Pending database schema migrations (`apps/api/migrations`) are executed and verified before container cutover.
- [x] Deployment to VPS executes conditionally (when `secrets.VPS_HOST` is present) via SSH action or runner hook, pulling new image and reloading containers via `docker compose` with health check verification (`/healthz`).
- [x] Staging / pre-VPS workflows document using Cloudflare Tunnel (`cloudflared`) to expose the local containerized API to mobile and web clients.
- [x] Deployment secrets (`VPS_HOST`, `VPS_SSH_KEY`, `DB_PASSWORD`, etc.) are consumed exclusively via GitHub Secrets without leaking into build logs.

---

## Technical Notes

- Target path filters: `apps/api/**`, `docker-compose.prod.yml`, `.github/workflows/cd-backend.yml`.
- Follow `REQ-INFRA-001` (Single-Host Deployability) and `REQ-INFRA-041` (Minimal Attack Surface).
- Pre-VPS exposure (Option 1): Backend runs locally via `docker-compose.dev.yml` and is tunneled via `cloudflared tunnel --url http://localhost:8080`. Mobile and web applications point to the generated tunnel URL.
- Make VPS SSH deployment step conditional: `if: env.VPS_HOST != ''`.
- Ensure Docker build uses Buildx with GitHub Actions layer cache (`type=gha`) for fast incremental builds.
- Rollback or abort deployment if health checks fail.
- Do NOT introduce Kubernetes or multi-node control planes.

---

## Out of Scope

- Multi-node clustering or Kubernetes/Helm deployments (prohibited by REQ-INFRA-001).
- Frontend or mobile app delivery (handled in TASK-INFRA-006 and TASK-INFRA-007).
- Blue/green DNS routing switches.

---

## Definition of Done

- [x] Workflow file and Dockerfile committed and tested
- [x] Diagnostics clean (`moon run api:lint` or `go vet`)
- [x] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
