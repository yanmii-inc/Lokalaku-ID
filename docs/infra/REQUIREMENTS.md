# 🏗️ Lokalaku — Infrastructure Requirements

> **What this is:** the operational requirements for the platform — deployment, observability,
> data durability, security baselines, and resource budgets.
>
> **What this is NOT:** the product PRD (`PRD.md`, user/app-facing `REQ-XX-NNN`), nor the place to
> record *which* technology was chosen. Technology choices and their rejected alternatives live in
> ADRs (`docs/decisions/ADR-*.md`). This doc states *what must be true*; the ADR states *how we chose
> to satisfy it and why*.
>
> **ID convention:** `REQ-INFRA-NNN`. Stable — these change when an operational goal changes, not when
> tooling changes. Swapping a technology updates an ADR, not a requirement here.
>
> **Routing tier:** 2 for implementing an infra requirement · 3 for the decision behind it.

---

## How requirements relate to the rest of the system

```
REQ-INFRA-NNN   the constraint that must hold        ← this file
      │
      ▼
ADR-NNN         the technology chosen + alternatives  ← docs/decisions/
      │
      ▼
TASK-INFRA-NNN  the work to implement it              ← docs/tasks/infra/
      │
      ▼
GUARDRAILS      the standing rule it implies          ← docs/infra/GUARDRAILS.md (TBD)
```

A commit implementing an infra requirement carries `Implements: REQ-INFRA-NNN`, and `See: ADR-NNN`
if a decision backs it.

---

## 1. Deployment & Portability

- **REQ-INFRA-001 (Single-Host Deployability):** The entire production stack must be deployable on a
  single low-cost Linux VPS using Docker Compose alone. No multi-node cluster, no managed control
  plane, and no orchestration system that requires more than one machine to start. _(Aligns with
  AGENTS.md Global Principle 1 — Zero Vendor Lock-In.)_
- **REQ-INFRA-002 (No Proprietary Cloud Dependency):** No component may depend on a proprietary
  cloud-vendor API as a hard requirement to run (e.g. AWS-only services, Vercel-specific features,
  Firebase Admin as the only auth path). Any such integration must be optional and behind an
  interface with a self-hostable default.
- **REQ-INFRA-003 (Reproducible Builds):** Every service must build from source to a single
  self-contained artifact (Go single binary; Flutter build output; Astro static/SSR bundle) with
  pinned toolchain versions (`.prototools`, lockfiles). A clean clone must build identically.

---

## 2. Service Topology

- **REQ-INFRA-010 (Core Service Set):** The baseline stack is PostgreSQL (primary datastore),
  plus the API binary. These must start with a single `docker compose up`.
- **REQ-INFRA-011 (Optional Profiles):** Redis (cache/refresh-token store), MinIO (object storage),
  and observability tooling must be opt-in via Compose profiles, not required for a minimal dev or
  single-tenant deployment to function.
- **REQ-INFRA-012 (Dev Mail Capture):** Local/dev environments must capture outbound email rather
  than send it externally, so OTP and verification flows are testable without a real SMTP provider.

---

## 3. Observability

- **REQ-INFRA-020 (Distributed Tracing):** The API must emit OpenTelemetry traces. In any deployment
  with the observability profile enabled, traces must be collectable and viewable. Tracing must
  degrade to a no-op (zero crashes, negligible overhead) when the collector is absent.
- **REQ-INFRA-021 (Structured Logging):** All services must emit structured (machine-parseable) logs
  to stdout/stderr — never to files the container can't rotate. Log lines must include enough context
  (request id, route, status, duration) to debug without attaching a debugger.
- **REQ-INFRA-022 (Health & Readiness):** Every long-running service must expose a health endpoint
  suitable for a container healthcheck and a load balancer.

---

## 4. Data Durability & Tenancy

- **REQ-INFRA-030 (Persistent Volumes):** All stateful services must write to named Docker volumes
  that survive container recreation. `compose down` (without `--volumes`) must never lose data.
- **REQ-INFRA-031 (Backup-Restore Path):** There must be a documented, scriptable path to back up and
  restore the PostgreSQL volume without proprietary tooling.
- **REQ-INFRA-032 (Cluster Data Isolation at Rest):** Infra configuration must not undermine the
  application-level `cluster_id` isolation (`REQ-BG-001`) — e.g. no shared cache keys that leak
  cross-cluster aggregates.

---

## 5. Security Baseline

- **REQ-INFRA-040 (Secret Handling):** Secrets (DB credentials, JWT signing keys, SMTP creds) must be
  supplied via environment / Docker secrets, never committed to the repo. `google-services`, key
  files, and archives are git-ignored by policy.
- **REQ-INFRA-041 (Minimal Attack Surface):** Production images must be minimal (`distroless`/`scratch`
  for the Go binary). No shell or package manager in the final image unless a documented need exists.
- **REQ-INFRA-042 (Network Exposure):** Only the API/web entrypoints and intentionally-public services
  may bind to host ports. Datastores and internal services stay on the internal Compose network.

---

## 6. CI/CD

- **REQ-INFRA-050 (Commit Hygiene Gate):** CI must enforce the commit convention
  (`docs/COMMIT_CONVENTION.md`) and reject code-touching commits lacking traceability footers,
  mirroring the local `commit-msg` hook.
- **REQ-INFRA-051 (Build & Lint Gate):** CI must build all artifacts and run `moon :lint` / `go vet`
  before merge to `main`.

---

## How to Add an Infra Requirement

1. Pick the next `REQ-INFRA-NNN` in the relevant section (gaps of 10 between sections leave room).
2. State *what must be true* — a constraint, not a technology. If you're naming a tool, you're
   probably writing an ADR, not a requirement.
3. If a technology choice satisfies it, record that choice in an ADR and cross-link both ways.
4. Reference it from any `TASK-INFRA-NNN` that implements it (`prd_ref: REQ-INFRA-NNN`).
