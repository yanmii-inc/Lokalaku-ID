---
id: TASK-INFRA-004
title: "Git hooks for lint, format, and vet"
milestone: INFRA
prd_ref: "—"
app: infra
status: todo
priority: high
complexity: S
github_issue: 5
dependencies: []
assigned_to: null
---

# TASK-INFRA-004: Git hooks for lint, format, and vet

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** _Not applicable_

---

## Objective

Install repository-level git hooks (e.g., via Husky or `pre-commit`) to run linters, formatters, and vet checks before commits and pushes to catch issues early.

---

## Context

Automated hooks reduce CI cycle time by preventing easily-detected problems from reaching CI. Keep hooks fast and opt-in for contributors who prefer not to use them.

---

## Acceptance Criteria

- [ ] Pre-commit hook runs formatters (dart/flutter format, prettier where applicable)
- [ ] Pre-push or pre-commit runs lint and `go vet` for Go code
- [ ] Hook installation documented (`npm install`/`pnpm install` step or `husky install`)

---

## Technical Notes

- Keep hooks lightweight; CI must still run full checks.
- Prefer cross-platform tooling where possible.

---

## Out of Scope

- Enforcing hooks for CI (CI must run checks independently)

---

## Definition of Done

- [ ] Hooks added and documented
- [ ] CI remains authoritative for final checks
- [ ] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
