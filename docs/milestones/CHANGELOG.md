# 📅 Lokalaku — Milestone Changelog

> **What this is NOT:** a git log.  
> **What this IS:** a human- and agent-readable record of what changed, why it was decided that way,  
> and what tradeoffs were accepted at each significant milestone.
>
> For raw commit history: `git log --oneline`.  
> For architectural rationale: `docs/decisions/ADR-*.md`.  
> For the detailed story of a milestone: follow the link in the table below.

---

## How to Read This File

Each row links to a full milestone document in `docs/milestones/`.  
The milestone document contains:
- The full rationale behind decisions made during that period
- Tradeoffs discussed and alternatives rejected
- Links to the ADRs and design docs that emerged
- Any follow-up work deferred to future milestones

---

## Active Development

| ID | Title | Status | Period | Summary |
|:---|:---|:---|:---|:---|
| [M001](./M001-foundation-auth-system.md) | Foundation & Auth System | 🟡 In Progress | 2025 Q1 | Core API scaffolding, JWT + opaque refresh token architecture, OTP verification, account state machine |

---

## Completed

_No completed milestones yet._

---

## Roadmap (Planned)

| ID | Title | Status | Target | Summary |
|:---|:---|:---|:---|:---|
| M002 | Pool Buying Core | 📋 Planned | 2025 Q2 | Pool Order state machine, MOQ threshold logic, atomic ACID transitions |
| M003 | Merchant POS Offline | 📋 Planned | 2025 Q2 | Hive/Isar local storage, background sync queue, offline PIN auth |
| M004 | Consumer Discovery | 📋 Planned | 2025 Q3 | Proximity browsing, store listing API, OTP consumer registration |
| M005 | Courier Dispatch | 📋 Planned | 2025 Q3 | GPS telemetry, batch job manifest, background location |
| M006 | Wholesaler Dashboard | 📋 Planned | 2025 Q3 | Product catalogue, pool monitoring, pool advancement |
| M007 | Backoffice & Cluster Mgmt | 📋 Planned | 2025 Q4 | Village cluster CRUD, wholesaler verification, platform health |
| M008 | Public Website & SEO | 📋 Planned | 2025 Q4 | Astro SSR pages, Islands search, village cluster landing pages |
| M009 | Hardening & Infrastructure | 📋 Planned | 2026 Q1 | Observability, Docker Compose production stack, load testing |

---

## How to Record a New Milestone

1. Copy `docs/milestones/MILESTONE-TEMPLATE.md` to `docs/milestones/MXXX-<kebab-title>.md`.
2. Fill in all sections — especially **Decisions Made** and **Rationale**.
3. Add a row to the "Active Development" table above.
4. Reference any ADRs created (`docs/decisions/NNN-*.md`) in the milestone doc.
5. When shipped: move the row to "Completed" and set status to ✅.

## How to Record an ADR

Any non-trivial architectural decision (library choice, data model, auth strategy, sync strategy)
deserves an ADR. When in doubt, write one.

1. Copy `docs/decisions/ADR-TEMPLATE.md` to `docs/decisions/NNN-<kebab-title>.md`.
2. Fill in Context, Decision, Rationale, and Alternatives.
3. Link it from the relevant milestone doc and AGENTS.md Document Map if it becomes a standing rule.
