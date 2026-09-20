---
id: TASK-INFRA-002
title: "Seed scripts for test data"
milestone: INFRA
prd_ref: "—"
app: infra
status: done
priority: high
complexity: M
github_issue: 3
dependencies: []
assigned_to: null
---

# TASK-INFRA-002: Seed scripts for test data

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** _Not applicable_

---

## Objective

Provide idempotent seed scripts and tooling to populate development and CI databases with realistic test data suitable for integration and end-to-end tests.

---

## Context

Tests and local development need reproducible data. Seed scripts should be runnable from the repo root and support multiple environments (dev, test). Integrates with the Docker Compose setup from TASK-INFRA-001.

---

## Acceptance Criteria

- [x] Seed scripts exist (`scripts/seed_dev.sql` and `scripts/seed.sh`) and are documented
- [x] Scripts are idempotent (`ON CONFLICT DO NOTHING`) and safe to run repeatedly
- [x] CI can run the seed step during integration test setup (`./scripts/seed.sh`)
- [x] Example dataset includes village clusters and test accounts across all roles (`superadmin`, `backoffice_admin`, `merchant`, `wholesaler`, `courier`, `consumer`)

---

## Technical Notes

- Prefer SQL files or small Go/Python programs over fragile ad-hoc scripts.
- Keep sensitive values out of checked-in scripts; use env vars for secrets.
- Make the seed step callable from `Makefile` or `scripts/` for CI reuse.

---

## Out of Scope

- Large production data dumps or anonymization tools

---

## Definition of Done

- [x] Scripts added and documented
- [x] Seed step tested via unit tests (`seed_test.go`)
- [x] `TASK-INDEX.md` status updated to `done`
- [x] GitHub issue closed (#3)

