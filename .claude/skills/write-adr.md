# Skill: write-adr

Write a new Architecture Decision Record for Lokalaku.

**Trigger phrases:** "write an ADR for X", "document why we chose Y", "record this decision", "add an ADR"

---

## Steps

### 1. Find the next ADR number

List files matching `docs/decisions/[0-9]*.md`, sort them, and take the highest three-digit prefix.
Next number = highest + 1, zero-padded to three digits (e.g. 003 → 004).

### 2. Derive inputs from context

Use the current conversation and any provided arguments to fill in:

- **Title** — short, noun-phrase decision name (e.g. "Hive for Offline Sync Queue")
- **Context Area** — `apps/api` | `apps/<name>` | `packages/flutter` | `Cross-cutting`
- **Context** — what forced the decision; constraints (offline-first, low-end devices, zero vendor lock-in)
- **Decision** — the exact library, pattern, data structure, or API design chosen
- **Rationale** — each reason tied to a Global Architectural Principle in `AGENTS.md` or a PRD requirement
- **Consequences** — positive, negative/tradeoffs, neutral
- **Alternatives Considered** — a table of rejected options with reasons
- **Related PRD Requirement(s)** — `REQ-XX-NNN` if applicable (use `—` if none)

If any required field is genuinely ambiguous, ask one targeted question before writing. Do not leave placeholders.

### 3. Find the active milestone

Read `docs/milestones/CHANGELOG.md`. Find the row with status `🟡 In Progress` in the "Active Development" table. Note its ID (e.g. `M001`) and file path (e.g. `docs/milestones/M001-foundation-auth-system.md`).

### 4. Write the ADR file

Create `docs/decisions/<NNN>-<kebab-title>.md` using the structure from `docs/decisions/ADR-TEMPLATE.md`.

Set:
- `**Status:** \`Accepted\``
- `**Date:**` today's date in `YYYY-MM-DD` format
- `**Decider(s):** AI-assisted + reviewed by <user name if known, otherwise "project lead">`
- `**Milestone:**` link to the active milestone file found in step 3

### 5. Link from the active milestone

Open the active milestone doc. In section **"4. Decisions Made During This Milestone"**, add a new `### Decision:` entry:

```
### Decision: <Short Label>
- **Context:** <one line>
- **Choice:** <one line>
- **Rationale:** <one line>
- **Tradeoffs:** <one line>
- **ADR:** [ADR-<NNN>](../decisions/<NNN>-<kebab-title>.md)
```

### 6. Update AGENTS.md Document Map (if standing rule)

If the decision introduces a project-wide constraint that all agents must respect (e.g. a new prohibited library, a new required pattern), add a row to the **Full Document Registry** table in `AGENTS.md` pointing to the new ADR at Tier 3.

Only do this for cross-cutting rules — not for single-app decisions.

### 7. Report

Tell the user:
- The file created: `docs/decisions/<NNN>-<kebab-title>.md`
- Whether `AGENTS.md` was updated
- The next step: commit with `docs(docs): add ADR-<NNN> <title>` and footer `See: ADR-<NNN>`
