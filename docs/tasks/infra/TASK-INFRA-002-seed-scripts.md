---
id: TASK-INFRA-002
title: "Seed scripts for test data"
milestone: INFRA
prd_ref: "—"
app: infra
status: todo
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

- [ ] Seed scripts exist (e.g., `scripts/seed_dev.sql` or `scripts/seed_dev.go`) and are documented
- [ ] Scripts are idempotent and safe to run repeatedly
- [ ] CI can run the seed step during integration test setup
- [ ] Example dataset includes users, accounts, sample products, and pool orders (minimal)

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

- [ ] Scripts added and documented
- [ ] Seed step used in CI integration test job
- [ ] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
