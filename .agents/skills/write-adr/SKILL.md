---
name: write-adr
description: Write a new Architecture Decision Record (ADR) for the Lokalaku project. Use when the user asks to document an architectural choice, library selection, pattern decision, or design tradeoff — e.g. "write an ADR for X", "document why we chose Y", "record this decision".
---

# Skill: Write ADR

You are creating a new Architecture Decision Record for the Lokalaku project.
Follow these steps exactly, in order.

## Step 1 — Read the template

Read `docs/decisions/ADR-TEMPLATE.md` to load the canonical format.

## Step 2 — Determine the next ADR number

List the files in `docs/decisions/` and find the highest existing `NNN-` prefix.
The new ADR number is that value + 1, zero-padded to 3 digits (e.g. `004`).

## Step 3 — Gather context

If the user's prompt does not already answer these, ask before writing:

1. **What is the decision?** (e.g. "Use Chi router instead of Fiber")
2. **What context forced this decision?** (What problem, constraint, or requirement?)
3. **What alternatives were considered and why were they rejected?**
4. **What are the positive consequences? What are the tradeoffs?**
5. **Which PRD requirements does this relate to?** (e.g. `REQ-BG-004`) — or "none" if cross-cutting.
6. **Which apps or packages does it affect?**

If you can infer confident answers from the conversation context, do so without asking —
only ask about genuinely unknown fields.

## Step 4 — Create the ADR file

Create `docs/decisions/NNN-<kebab-title>.md` following the template exactly.

Rules for the filename:
- Lowercase, hyphen-separated words only.
- Concise but descriptive: `004-postgresql-multi-tenancy.md`, not `004-db.md`.

Fill in every section. Do not leave placeholder text. If a field is genuinely not applicable,
write `_N/A_` rather than leaving a template comment.

**Status** must be `Accepted` unless the user says it is still under discussion (`Draft`).

## Step 5 — Link the ADR

After creating the ADR file:

1. If there is an active milestone in `docs/milestones/CHANGELOG.md` (status "In Progress"),
   open that milestone's `.md` file and add the ADR to the **Linked ADRs** header field
   and to the **Decisions Made During This Milestone** section.

2. If the decision permanently enforces a rule across the codebase (e.g. "always use X, never Y"),
   note in your final message that the user should also reflect it in the relevant `AGENTS.md`.

## Step 6 — Report back

Tell the user:
- The file path created (`docs/decisions/NNN-<title>.md`)
- A one-sentence summary of what was decided and why
- Any follow-up actions (milestone linking, AGENTS.md update, future ADR to revisit)
