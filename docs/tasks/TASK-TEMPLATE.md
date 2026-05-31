---
id: TASK-DOMAIN-NNN
title: "Short human-readable title"
milestone: MXXX
prd_ref: "REQ-XX-NNN"
app: api
status: todo
priority: high
complexity: M
github_issue: null
dependencies: []
assigned_to: null
---

# TASK-DOMAIN-NNN: [Title]

> **Milestone:** [MXXX — Title](../milestones/MXXX-title.md)  
> **PRD Reference:** [REQ-XX-NNN](../../PRD.md)  
> **Design Doc:** [docs/design/NN-feature.md](../design/NN-feature.md) _(if applicable)_

---

## Objective

_One or two sentences. What does this task produce? What is the user-visible or system-level outcome?_

---

## Context

_Why does this task exist? What must the agent know before starting?  
Link to relevant ADRs, design docs, or PRD sections._

---

## Acceptance Criteria

_Specific, verifiable conditions. A reviewer can check each one independently._

- [ ] AC1: ...
- [ ] AC2: ...
- [ ] AC3: ...

---

## Technical Notes

_Implementation hints, constraints, and patterns to follow.  
Be specific enough that an agent can start without additional clarification._

- Follow patterns in: `...`
- Do NOT: `...`
- Related files: `...`
- Run after completing: `...`

---

## Out of Scope

_Explicitly list what this task does NOT include, to prevent scope creep._

- Not responsible for: ...

---

## Definition of Done

- [ ] Code written and self-reviewed
- [ ] Unit tests added or updated
- [ ] Diagnostics clean (`moon run :lint` or `go vet`)
- [ ] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
