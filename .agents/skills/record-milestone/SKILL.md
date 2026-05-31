---
name: record-milestone
description: Update or complete a Lokalaku milestone document after a batch of work ships. Records what changed, the decisions made and their rationale, deferred items, and lessons learned. Use when the user says "update the milestone", "mark M00X as done", "checkpoint our progress", or "fill in the milestone doc".
---

# Skill: Record Milestone

You are updating a milestone document for the Lokalaku project.
This is the human + agent memory layer — richer than git log, less formal than ADRs.
Follow these steps exactly.

## Step 1 — Read the milestone state

Read both:
- `docs/milestones/CHANGELOG.md` — identify the milestone ID and its current status.
- `docs/milestones/MXXX-<title>.md` — the specific milestone file to update.
- `docs/milestones/MILESTONE-TEMPLATE.md` — if creating a new milestone file from scratch.

## Step 2 — Determine what mode you are in

| Mode | Trigger | What to do |
|:---|:---|:---|
| **New milestone** | The user is starting to plan a new milestone | Create `docs/milestones/MXXX-<title>.md` from template; add row to CHANGELOG.md |
| **Checkpoint update** | The user wants to record progress mid-milestone | Update sections 3, 4, and 5 of the existing file |
| **Completing a milestone** | The user says it shipped | Fill all sections, set status to `Completed`, move CHANGELOG.md row to "Completed" table |

## Step 3 — Gather what changed

Ask the user (or infer from conversation context) about:

1. **What shipped?** — List the meaningful changes: new endpoints, new screens, schema changes, package additions. Not every commit — the significant shifts.
2. **What decisions were made?** — For each non-trivial decision: what was chosen, why, and what tradeoff was accepted. Does it need its own ADR? (If yes, remind the user to use the `write-adr` skill.)
3. **What was deferred?** — What was originally scoped but moved out, and where did it go?
4. **Lessons learned?** — What would you do differently? What worked well? (Even one sentence is valuable.)
5. **Follow-up actions** — New tasks created, new ADRs needed, new design docs needed?

If the user says "just checkpoint what we discussed", extract the answers from the conversation.

## Step 4 — Update the milestone file

Fill in or update these sections of `docs/milestones/MXXX-<title>.md`:

- **Section 3 — Key Changes:** A table row per meaningful change.
- **Section 4 — Decisions Made During This Milestone:** One subsection per decision. If an ADR already covers it, link to it rather than duplicating.
- **Section 5 — Deferred Work:** What moved out and where it went.
- **Section 6 — Lessons Learned:** At least one concrete observation.
- **Section 7 — Follow-Up Actions:** Checkboxes for each concrete next step.

Update the **Status** field in the file header if the milestone is now `Completed`.

## Step 5 — Update CHANGELOG.md

If the milestone is now `Completed`:
1. Move its row from the "Active Development" table to the "Completed" table.
2. Change the status emoji to ✅.

If it is still in progress, update the summary text in the "Active Development" row to reflect current state.

## Step 6 — Report back

Tell the user:
- What sections were updated and in which file
- Whether any new ADRs should be written (prompt them to use `write-adr` skill)
- Whether any new tasks should be created (prompt them to use `write-task` skill)
- Whether the milestone is now marked complete in CHANGELOG.md
