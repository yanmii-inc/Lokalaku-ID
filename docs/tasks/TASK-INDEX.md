# 📋 Lokalaku — Task Index

> **For agents:** Read this when planning work, decomposing PRD requirements into tasks,  
> or checking what is already in progress. Use `TASK-TEMPLATE.md` to create new task files.  
> Run `python3 scripts/gh_create_issues.py` to sync unlinked tasks to GitHub Issues.  
> **Routing tier:** 5 (task planning and work breakdown).

---

## Domain Codes

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

## Status Legend

| Symbol | Status | Meaning |
|:---:|:---|:---|
| 📋 | `todo` | Defined, not started |
| 🔄 | `in-progress` | Active development |
| ✅ | `done` | Implemented and verified |
| ⏸️ | `deferred` | Moved to a later milestone |
| ❌ | `cancelled` | No longer needed |

## Complexity Legend

| Code | Meaning |
|:---:|:---|
| `S` | Hours |
| `M` | 1–2 days |
| `L` | 3–5 days |
| `XL` | Sprint (5+ days) |

---

## M001 — Foundation & Auth System

> [Milestone doc](../milestones/M001-foundation-auth-system.md) · [Design doc](../design/01-auth-flow.md)

| Task | Title | PRD Ref | Priority | Size | Status | GH |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| [TASK-API-001](./api/TASK-API-001-project-scaffold.md) | Go project scaffold & Chi router | — | 🔴 | M | 📋 | — |
| [TASK-API-002](./api/TASK-API-002-postgres-schema-auth.md) | PostgreSQL schema: accounts, sessions, OTP, audit | REQ-BG-001 | 🔴 | M | 📋 | — |
| [TASK-API-003](./api/TASK-API-003-jwt-auth-endpoints.md) | JWT auth endpoints (login, refresh, logout) | REQ-BG-004 | 🔴 | L | 📋 | — |
| [TASK-API-004](./api/TASK-API-004-otp-verification.md) | OTP issuance & verification endpoint | REQ-BG-006 | 🔴 | M | 📋 | — |
| [TASK-API-005](./api/TASK-API-005-account-state-machine.md) | Account status state machine middleware | REQ-BG-005 | 🔴 | M | 📋 | — |
| [TASK-PKG-001](./pkg/TASK-PKG-001-domain-entities-auth.md) | `domain` entities: Account, Role, Session, AuthToken | — | 🔴 | S | 📋 | — |
| [TASK-PKG-002](./pkg/TASK-PKG-002-core-auth-package.md) | `core_auth`: token storage, refresh timer, offline PIN | REQ-BG-004 | 🔴 | XL | 📋 | — |
| [TASK-PKG-003](./pkg/TASK-PKG-003-core-network-interceptor.md) | `core_network`: auth interceptor & 401 retry | REQ-BG-004 | 🔴 | M | 📋 | — |

---

## M002 — Pool Buying Core

> [Milestone doc](../milestones/CHANGELOG.md) · Design doc: _(to be created)_

| Task | Title | PRD Ref | Priority | Size | Status | GH |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| TASK-API-006 | PostgreSQL schema: pool orders + commitments | REQ-BG-002 | 🔴 | M | 📋 | — |
| TASK-API-007 | Pool order CRUD endpoints | REQ-BG-002 | 🔴 | L | 📋 | — |
| TASK-API-008 | Atomic pool state transition (open → locked_ready) | REQ-BG-002 | 🔴 | L | 📋 | — |
| TASK-MERCHANT-001 | Pool Buying progress dashboard screen | REQ-ME-002 | 🟠 | L | 📋 | — |
| TASK-WHOLESALE-001 | Pool Order monitoring view | REQ-WS-002 | 🟠 | L | 📋 | — |
| TASK-WHOLESALE-002 | Pool advancement actions (locked_ready, fulfilled) | REQ-WS-003 | 🟠 | M | 📋 | — |

---

## M003 — Merchant POS Offline

> [Milestone doc](../milestones/CHANGELOG.md) · Design doc: `docs/design/02-offline-sync-queue.md` _(to be created)_

| Task | Title | PRD Ref | Priority | Size | Status | GH |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| TASK-MERCHANT-002 | Isar local product inventory schema | REQ-ME-001 | 🔴 | M | 📋 | — |
| TASK-MERCHANT-003 | POS checkout — local-first write + Hive sync queue | REQ-ME-001 | 🔴 | XL | 📋 | — |
| TASK-MERCHANT-004 | Background sync queue drain service | REQ-ME-001 | 🔴 | L | 📋 | — |
| TASK-MERCHANT-005 | Offline PIN challenge screen + bcrypt local storage | REQ-ME-004 | 🔴 | M | 📋 | — |
| TASK-MERCHANT-006 | Offline grace session timer + background refresh | REQ-ME-004 | 🔴 | M | 📋 | — |

---

## M004 — Consumer Discovery

> [Milestone doc](../milestones/CHANGELOG.md)

| Task | Title | PRD Ref | Priority | Size | Status | GH |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| TASK-API-009 | Store & product discovery endpoints (geo radius) | REQ-BG-001 | 🔴 | L | 📋 | — |
| TASK-API-010 | Consumer OTP registration (phone-only, instant active) | REQ-CS-003 | 🔴 | M | 📋 | — |
| TASK-CONSUMER-001 | Unauthenticated store browse + proximity sort | REQ-CS-002 | 🟠 | L | 📋 | — |
| TASK-CONSUMER-002 | Consumer OTP login/register screen | REQ-CS-003 | 🟠 | M | 📋 | — |

---

## How to Add a New Task

1. Pick the domain code + next available number for that domain.
2. Copy `docs/tasks/TASK-TEMPLATE.md` to `docs/tasks/<domain>/TASK-<CODE>-<NNN>-<kebab-title>.md`.
3. Fill in all frontmatter fields. Leave `github_issue: null`.
4. Add a row to this index under the correct milestone.
5. Run `python3 scripts/gh_create_issues.py` to create the GitHub issue and auto-fill the link.

## How to Update a Task Status

1. Open the task file and update the `status` field in the frontmatter.
2. Update the Status column in the table above.
3. If `done`, close the GitHub issue linked in the `github_issue` field.
