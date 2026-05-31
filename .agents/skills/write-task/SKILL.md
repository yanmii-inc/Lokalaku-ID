---
name: write-task
description: Create a new atomic task file for the Lokalaku project from a PRD requirement, feature description, or milestone scope. Writes a TASK-*.md file with proper frontmatter and updates TASK-INDEX.md. Use when the user says "create a task for X", "add a work item", "break down REQ-XX", or "decompose this feature into tasks".
---

# Skill: Write Task

You are creating one or more task files for the Lokalaku project.
Follow these steps exactly, in order.

## Step 1 — Read the index and template

Read both files before doing anything else:
- `docs/tasks/TASK-INDEX.md` — to find the next available task number per domain and understand milestone grouping.
- `docs/tasks/TASK-TEMPLATE.md` — to load the canonical frontmatter format and section structure.

## Step 2 — Determine the domain code and milestone

From the user's request, identify:

| Field | How to determine it |
|:---|:---|
| **Domain code** | `API`, `PKG`, `MERCHANT`, `COURIER`, `CONSUMER`, `WHOLESALE`, `BACKOFFICE`, `WEBSITE`, `INFRA` — pick the one that owns the work |
| **Next task number** | Find the highest existing `TASK-<DOMAIN>-NNN` for that domain in `TASK-INDEX.md`, then increment by 1 |
| **Milestone** | Which `MXXX` does this belong to? If unclear, ask the user |
| **PRD reference** | Which `REQ-XX-NNN` from `PRD.md` or `apps/<app>/PRD.md` does this satisfy? Use `—` if purely technical |

If creating multiple tasks from one request (e.g. "break down the pool buying feature"),
create each as a separate file and add all to the index.

## Step 3 — Gather task details

For each task, you need:

1. **Objective** — one sentence: what does this task produce?
2. **Acceptance criteria** — at minimum 3 specific, checkable conditions.
3. **Technical notes** — file paths, patterns to follow, things NOT to do, commands to run.
4. **Out of scope** — what explicitly does this task NOT cover?
5. **Dependencies** — which other `TASK-IDs` must complete first? (List as `[]` if none.)
6. **Priority** — `high | medium | low`
7. **Complexity** — `S` (hours) / `M` (1–2 days) / `L` (3–5 days) / `XL` (sprint)

Infer these from context where possible. Ask only for what you genuinely cannot infer.

## Step 4 — Create the task file(s)

For each task, create `docs/tasks/<domain-lowercase>/TASK-<DOMAIN>-<NNN>-<kebab-title>.md`.

- Domain subfolder must be lowercase: `api/`, `pkg/`, `merchant/`, etc.
- Create the subfolder if it does not exist.
- Fill in the YAML frontmatter completely. Set `github_issue: null`.
- Do not leave any placeholder comments in the file body.

## Step 5 — Update TASK-INDEX.md

Add a row to the correct milestone table in `docs/tasks/TASK-INDEX.md`:

```
| [TASK-DOMAIN-NNN](./domain/TASK-DOMAIN-NNN-title.md) | Title | REQ-XX-NNN | 🔴/🟠/🟡 | S/M/L/XL | 📋 | — |
```

Priority emoji: 🔴 high, 🟠 medium, 🟡 low.

If the milestone section does not yet exist in the index, create it with a header and table.

## Step 6 — Report back

Tell the user:
- The file path(s) created
- A brief summary of acceptance criteria
- The command to push to GitHub when ready:
  `python3 scripts/gh_create_issues.py --dry-run` (preview) then without `--dry-run` (create)
