# Skill: write-task

Create a new task file and register it in the task index.

**Trigger phrases:** "create a task for X", "break down REQ-XX", "add a work item", "add a task", "write a task"

---

## Steps

### 1. Read the task index

Read `docs/tasks/TASK-INDEX.md` to:
- Identify which milestone this task belongs to (default: the first milestone listed with `📋 todo` or `🔄 in-progress` tasks, or the active milestone from `docs/milestones/CHANGELOG.md`)
- Find the highest existing task number for the target domain code (e.g. if `TASK-API-005` exists, next API task is `TASK-API-006`)

**Domain codes:**
| Code | Scope |
|:---|:---|
| `API` | `apps/api` (Golang backend) |
| `PKG` | `packages/flutter/*` (shared Dart packages) |
| `MERCHANT` | `apps/merchant_app` |
| `COURIER` | `apps/courier_app` |
| `CONSUMER` | `apps/consumer_app` |
| `WHOLESALE` | `apps/wholesaler_app` |
| `BACKOFFICE` | `apps/backoffice_web` |
| `WEBSITE` | `apps/website` |
| `INFRA` | Docker, CI/CD, deployment |

### 2. Derive inputs from context

Use the current conversation, PRD references, and design docs to populate:

- **id** — `TASK-<CODE>-<NNN>` (zero-padded three digits)
- **title** — short human-readable description
- **milestone** — e.g. `M001`
- **prd_ref** — `REQ-XX-NNN` if traceable, otherwise `"—"`
- **app** — the primary app or package being modified
- **priority** — `high` / `medium` / `low` (default `high` if tied to a blocking PRD requirement)
- **complexity** — `S` (hours) / `M` (1–2 days) / `L` (3–5 days) / `XL` (sprint)
- **dependencies** — list of `TASK-*` IDs that must complete first, or `[]`

If `prd_ref` or scope is ambiguous, ask one question before writing.

### 3. Determine the file path

Subdirectory mapping:
| Domain | Subdirectory |
|:---|:---|
| `API` | `docs/tasks/api/` |
| `PKG` | `docs/tasks/pkg/` |
| `MERCHANT` | `docs/tasks/merchant/` |
| `COURIER` | `docs/tasks/courier/` |
| `CONSUMER` | `docs/tasks/consumer/` |
| `WHOLESALE` | `docs/tasks/wholesale/` |
| `BACKOFFICE` | `docs/tasks/backoffice/` |
| `WEBSITE` | `docs/tasks/website/` |
| `INFRA` | `docs/tasks/infra/` |

File path: `docs/tasks/<subdirectory>/TASK-<CODE>-<NNN>-<kebab-title>.md`

Create the subdirectory if it doesn't exist.

### 4. Write the task file

Use `docs/tasks/TASK-TEMPLATE.md` as the structure. Fill in all sections:

- **Objective** — one or two sentences: what does this task produce? What is the user-visible or system-level outcome?
- **Context** — why does this task exist? Link to ADRs, design docs, PRD sections that constrain it.
- **Acceptance Criteria** — specific, independently verifiable conditions. Minimum three ACs. Always include one AC that is test-specific: e.g. "Unit tests cover the happy path and at least one error/edge case."
- **Technical Notes** — implementation hints, constraints, prohibited patterns, related files, commands to run after completing.
- **Out of Scope** — explicitly list what this task does NOT include. Name the task(s) that own those pieces.
- **Definition of Done** — use the stack-appropriate checklist below. Never omit the test line.

  **Go API task DoD:**
  - [ ] Code written and self-reviewed
  - [ ] `*_test.go` written — happy path + at least one error path
  - [ ] `go test ./apps/api/...` passes
  - [ ] `go vet ./apps/api/...` passes
  - [ ] `TASK-INDEX.md` status updated to `done`
  - [ ] GitHub issue closed

  **Flutter app task DoD:**
  - [ ] Code written and self-reviewed
  - [ ] `*_test.dart` written in `test/` mirroring `lib/` structure
  - [ ] `flutter test` (or `moon run <app>:test`) passes
  - [ ] `moon run :lint` passes
  - [ ] `TASK-INDEX.md` status updated to `done`
  - [ ] GitHub issue closed

  **Shared Flutter package task DoD:**
  - [ ] Code written and self-reviewed
  - [ ] `*_test.dart` written in `packages/flutter/<pkg>/test/`
  - [ ] `moon run :test` passes (all packages)
  - [ ] `moon run :lint` passes
  - [ ] `TASK-INDEX.md` status updated to `done`
  - [ ] GitHub issue closed

  **For `fix`/`refactor` tasks** (instead of new test): "Existing tests verified and adjusted to reflect changed behaviour — `<test command>` passes clean."

Set `github_issue: null` — it will be filled by the sync script.

### 5. Add a row to TASK-INDEX.md

In `docs/tasks/TASK-INDEX.md`, find the correct milestone section (e.g. `## M001`). Append a new table row:

```
| [TASK-<CODE>-<NNN>](./<subdirectory>/TASK-<CODE>-<NNN>-<kebab-title>.md) | <title> | <prd_ref> | 🔴/🟠/🟡 | <complexity> | 📋 | — |
```

Priority emoji: 🔴 high · 🟠 medium · 🟡 low.

If the milestone section doesn't exist yet in TASK-INDEX.md, add it with a `## MXXX — <Title>` heading and an empty table matching the existing column format.

### 6. Remind about GitHub sync

After writing, tell the user:
```
Run: python3 scripts/gh_create_issues.py --dry-run
Then: python3 scripts/gh_create_issues.py
to create the GitHub Issue and back-fill the github_issue field.
```

### 7. Report

Tell the user:
- File created: `docs/tasks/<subdirectory>/TASK-<CODE>-<NNN>-<kebab-title>.md`
- TASK-INDEX.md row added under milestone `<MXXX>`
- Suggested commit: `docs(docs): add TASK-<CODE>-<NNN> <title>`
