---
id: TASK-INFRA-003
title: "Moon task runner configuration"
milestone: INFRA
prd_ref: "—"
app: infra
status: todo
priority: high
complexity: S
github_issue: 4
dependencies: []
assigned_to: null
---

# TASK-INFRA-003: Moon task runner configuration

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** _Not applicable_

---

## Objective

Standardize `moon` tasks across the monorepo for common developer workflows: install, lint, test, and package commands for each package and app.

---

## Context

The repository uses Moon for Dart/Flutter orchestration. Centralized `moon` tasks reduce friction when contributors run tests, linting, or codegen. This task wires convenient top-level tasks and documents usage.

---

## Acceptance Criteria

- [ ] `moon` workspace has tasks for `:get`, `:lint`, `:test`, and per-package `build-runner` where applicable
- [ ] README documents common `moon` commands and how to run them locally
- [ ] CI workflows can call the new `moon` tasks

---

## Technical Notes

- Follow existing `moon` patterns in `.moon/` and `moon project <name>` commands.
- Avoid adding heavy global dependencies; prefer per-package tasks.

---

## Out of Scope

- Rewriting CI to use `moon` exclusively (only exposing tasks to be used by CI)

---

## Definition of Done

- [ ] `moon` tasks created and documented
- [ ] CI uses `moon` tasks in at least one pipeline job
- [ ] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
