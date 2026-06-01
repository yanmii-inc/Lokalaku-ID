# Skill: record-milestone

Update a milestone doc and the CHANGELOG with decisions, deferred work, and lessons learned.
Optionally mark a milestone as completed.

**Trigger phrases:** "update the milestone", "mark M00X as done", "checkpoint our progress", "record milestone", "close the milestone", "milestone retrospective"

---

## Steps

### 1. Identify the target milestone

- If the user named a specific milestone (e.g. "mark M001 as done"), use that.
- Otherwise, read `docs/milestones/CHANGELOG.md` and find the `🟡 In Progress` row in "Active Development". Use that milestone.
- Read the full milestone doc (e.g. `docs/milestones/M001-foundation-auth-system.md`).

### 2. Gather evidence of what happened

Run these reads in parallel:

**a) New ADRs this milestone**
List all files in `docs/decisions/[0-9]*.md`. Cross-reference against links already in section 4 of the milestone doc — anything not yet linked is new.

**b) Task progress**
Read `docs/tasks/TASK-INDEX.md`. For the target milestone section, note tasks that moved to ✅ `done` since the last checkpoint.

**c) Deferred work**
From the current conversation context (if invoked mid-session) or by reading the milestone doc's existing "Deferred Work" section — identify items that were scoped in but won't ship with this milestone.

**d) Code signals (if available)**
If the user describes what changed, or if `git diff` / `git log` results are in context, extract the meaningful behaviour changes (not every commit — only shifts in API contracts, data model, or UX).

### 3. Update the milestone doc

Open the milestone file and update the following sections. Preserve all existing content — append or fill gaps; do not overwrite.

**Section 3 — Key Changes**
Add rows for any meaningful changes not yet recorded. Format:
```
| `<area>` | <what changed> | <notes / ADR link> |
```

**Section 4 — Decisions Made During This Milestone**
For each ADR found in step 2a that isn't already listed, add a `### Decision:` block:
```
### Decision: <Short Label>
- **Context:** <one line>
- **Choice:** <one line>
- **Rationale:** <one line>
- **Tradeoffs:** <one line>
- **ADR:** [ADR-NNN](../decisions/NNN-title.md)
```

**Section 5 — Deferred Work**
For each deferred item, add a row:
```
| <item description> | [MXXX — Title](./MXXX-title.md) or "TBD" | <reason> |
```

**Section 6 — Lessons Learned**
If the user provides retrospective input, record it here. If marking as completed and this section is still empty, prompt:
> "Before closing the milestone: what would you do differently, or what worked especially well?"
Wait for input before writing this section.

**Section 7 — Follow-Up Actions**
Add any new action items surfaced during this session. Check off any that are now complete.

### 4. If marking as COMPLETED

**a)** In the milestone doc header, update:
```
**Status:** `Completed`
**Period:** <original start> → <today's date YYYY-MM-DD>
```

**b)** In `docs/milestones/CHANGELOG.md`:
- Remove the row from the "Active Development" table
- Add it to the "Completed" table with status `✅` and a one-line summary of what shipped

**c)** In `docs/tasks/TASK-INDEX.md`:
- Verify all tasks under this milestone are ✅ `done` or ⏸️ `deferred`. Flag any that are still `📋 todo` or `🔄 in-progress` — the milestone cannot close cleanly with undone undeferred tasks.

### 5. If starting a NEW milestone (optional follow-up)

If the user says "and start M00X", after closing the current one:
1. Copy `docs/milestones/MILESTONE-TEMPLATE.md` to `docs/milestones/MXXX-<kebab-title>.md`
2. Fill in **Status: In Progress**, **Period: <today> → Ongoing**, and **Apps Affected** from context
3. Add a row in `CHANGELOG.md` "Active Development" with status `🟡 In Progress`

### 6. Report

Tell the user:
- Which sections were updated in the milestone doc
- Whether CHANGELOG.md was updated (and how — moved to Completed, or new active milestone added)
- Any tasks that are still open and blocking a clean close (if marking complete)
- Suggested commit: `docs(docs): checkpoint MXXX <milestone title>`
  - Add `See: ADR-NNN` footer for each ADR linked during this session
