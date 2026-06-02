# Skill: reconcile

You coded during a brainstorming session. This skill reconstructs the documentation trail
from what actually changed — so traceability becomes a byproduct of committing, not upfront friction.

**Trigger phrases:** "reconcile", "catch up the docs", "document what we just built",
"before I commit", "sync the docs", "what did we change?", "reconcile this session"

---

## When to invoke

- Code in the working tree was written during chat/exploration without following the forward workflow
- `git diff` or `git status` shows code changes with no corresponding docs/tasks/ADRs updated
- You're about to `git commit` and know the linkage footers would be empty

---

## Steps

### 1. Read the diff

Run (or read from context if already available):
```
git diff HEAD          # all unstaged changes
git diff --cached      # all staged changes
git status             # new untracked files
```

Group changed files by path prefix:

| Path prefix | Domain | REQ prefix | Scope (commit) |
|:---|:---|:---|:---|
| `apps/api/**` | Backend API | `REQ-BG-` | `api` |
| `apps/merchant_app/**` | Merchant POS | `REQ-ME-` | `merchant` |
| `apps/courier_app/**` | Courier | `REQ-CO-` | `courier` |
| `apps/consumer_app/**` | Consumer | `REQ-CS-` | `consumer` |
| `apps/wholesaler_app/**` | Wholesaler | `REQ-WS-` | `wholesale` |
| `apps/backoffice_web/**` | Superadmin | `REQ-SA-` | `backoffice` |
| `apps/website/**` | Public site | `REQ-PW-` | `website` |
| `packages/flutter/domain/**` | Domain entities | cross-cutting | `domain` |
| `packages/flutter/data/**` | Repositories | cross-cutting | `data` |
| `packages/flutter/core_auth/**` | Auth lifecycle | cross-cutting | `core-auth` |
| `packages/flutter/core_network/**` | HTTP client | cross-cutting | `core-network` |
| `packages/flutter/ui_kit/**` | Design system | cross-cutting | `ui-kit` |
| `packages/flutter/utils/**` | Utilities | cross-cutting | `utils` |
| `docs/**` | Documentation | — | `docs` |
| `docker/`, `compose.yaml`, `**/Dockerfile`, `scripts/`, `.github/workflows/**` | Infra | `REQ-INFRA-` | `infra` |
| Root config files | Workspace | — | `workspace` |

> **Infra requirements live in `docs/infra/REQUIREMENTS.md`, NOT `PRD.md`.** The PRD is product/user-facing
> (`REQ-BG-`, `REQ-ME-`, …); infra requirements are operational (deployment, observability, durability,
> security baselines). When a change is infra and lacks a `REQ-INFRA-NNN`, the "PRD delta" in steps 3a/5
> means a new entry in `docs/infra/REQUIREMENTS.md` — same ID convention, different file.

---

### 2. Classify each change by tier

For each file group, assign a tier:

**Tier 0** — skip, no docs needed:
- Whitespace, formatting, import ordering, lint/vet fixes
- Config-only changes (`.gitignore`, `.air.toml`, biome config, etc.)
- Dependency version bumps with no behaviour change

**Tier 1** — task needed (if none exists):
- Bug fix clearly contained within one app
- Small addition to an existing feature (new widget variant, new helper method)
- Renaming, moving files within the same package

**Tier 2** — task + PRD ref needed:
- New file in `lib/features/**` (Flutter) or a new endpoint handler file (Go)
- New DB table or migration
- New screen, new API route, new repository method
- New Flutter widget category in `ui_kit`

**Tier 3** — ADR needed (in addition to task + PRD ref):
- A new dependency introduced in any `pubspec.yaml` or `go.mod`
- A new shared package created under `packages/flutter/`
- A change to a cross-cutting pattern (how tokens are stored, how errors are modelled, how sync queue works)
- A data model or API contract change that affects multiple apps
- Any deviation from a decision already recorded in an ADR (this is a **violation** — see step 4)

---

### 3. Scan existing docs for coverage

For each Tier 1–3 change:

**a) Requirement coverage** — find if an existing requirement describes the changed behaviour.
- For **product/app** changes: read the relevant `PRD.md` (root or per-app) for a matching `REQ-XX-NNN`.
- For **infra** changes (`docker/`, `compose.yaml`, `Dockerfile`, `scripts/`, `.github/workflows/`): read `docs/infra/REQUIREMENTS.md` for a matching `REQ-INFRA-NNN`. Do **not** look in PRD.md for these.
- If covered: note the REQ ID — it becomes an `Implements:` footer
- If NOT covered: mark as **requirement delta needed** — a new `REQ-XX-NNN` in the relevant `PRD.md`, or a new `REQ-INFRA-NNN` in `docs/infra/REQUIREMENTS.md` for infra changes

**b) ADR coverage** (Tier 3 only) — list files in `docs/decisions/[0-9]*.md` and scan headings for relevance.
- If covered by an existing ADR: note the ADR number — it becomes a `See:` footer
- If NOT covered: mark as **ADR needed**

**c) Task coverage** — read `docs/tasks/TASK-INDEX.md`. Find a row whose description maps to this change.
- If a matching task exists with status `🔄 in-progress` or `📋 todo`: note the TASK-ID
- If no matching task: mark as **task needed**
- If a matching task exists with status `✅ done`: confirm this change closes it

**d) Test coverage check** — for each Tier 1–3 code change, check whether corresponding test files exist in the working tree (staged or unstaged):

Test file patterns per stack:
- Go API (`apps/api/**`): `*_test.go` co-located with the changed file in the same package
- Flutter apps (`apps/*/lib/**`): `*_test.dart` in `apps/<app>/test/` mirroring the `lib/` path
- Flutter packages (`packages/flutter/**`): `*_test.dart` in `packages/flutter/<pkg>/test/`
- Website (`apps/website/**`): `*.test.ts` / `*.spec.ts` alongside or in a `__tests__/` directory

Classification:
- Change is a **new feature (`feat` type)** + no test files found → mark as **tests needed (blocking)**
- Change is a **fix/refactor/perf** + no test files touched → mark as **tests to verify (non-blocking)** — remind to run the suite
- Test files found → mark as covered

**e) ADR violation check** — read the `AGENTS.md` prohibitions and all existing ADRs for the affected domain.
Flags to raise immediately (block commit and require resolution):
- Use of `StateNotifier`, `StateNotifierProvider`, `Bloc`, `GetX`, or `Provider` in Flutter code — violates ADR-001
- Raw exception thrown across a package boundary instead of `Result<T>` — violates `packages/flutter/AGENTS.md`
- Business logic in `ui_kit` or network calls in `domain`/`utils` — violates package responsibility rules
- Cloud-native proprietary API calls (Firebase Admin SDK, Vercel-specific, AWS-only) in `apps/api` — violates AGENTS.md Global Principle 1
- CSR page added to `apps/website` outside Islands — violates `apps/website/GUARDRAILS.md`

If a violation is found: **stop, report it explicitly, and ask the user to fix it before reconciling.**
Do not write any documentation for code that violates a standing rule — document it only after the violation is resolved.

---

### 4. Build and present the Reconciliation Report

Before writing anything, present a summary to the user for confirmation. Format:

```
## Reconciliation Report

### Changes detected
- [scope] <brief description of what changed> (Tier N)
- ...

### Violations (must fix before committing)
- ❌ <violation description> — conflicts with <ADR-NNN / rule source>

### Missing artifacts
- [ ] ADR needed: <decision title> — <one-line rationale>
- [ ] PRD delta needed: <new behaviour description> → propose REQ-<prefix>-<next-number> in <PRD file>
- [ ] Task needed: TASK-<CODE>-<NNN> — <title>
- [ ] Task to close: TASK-<CODE>-<NNN> (<TASK-ID>) is now done

### Tests
- [ ] ⛔ Tests needed (feat — blocking): <file(s) to create, e.g. apps/api/internal/auth/otp_test.go>
- [ ] ⚠  Tests to verify (fix/refactor — run suite): `<test command>`

### Already covered (no action needed)
- ✅ REQ-XX-NNN covers <change>
- ✅ ADR-NNN covers <change>
- ✅ TASK-<CODE>-<NNN> maps to <change>

### Proposed commit(s)
1. `<type>(<scope>): <subject>`
   Footers: Implements: REQ-XX-NNN · See: ADR-NNN · Closes: #NNN
```

Then ask: **"Confirm? (yes / skip ADR / skip task / edit)"**
Wait for the user's response before writing anything.

---

### 5. Execute: write missing artifacts

Based on user confirmation, execute in this order:

1. **Requirement delta** — if new behavior has no REQ:
   - **Product/app change:** open the relevant per-app `PRD.md`, find the next `REQ-<prefix>-<NNN>`, add a bullet under the correct module section in the existing sentence style.
   - **Infra change:** open `docs/infra/REQUIREMENTS.md`, find the next `REQ-INFRA-<NNN>` in the relevant section, add an entry following the "what must be true, not which technology" rule. If the change is actually a *technology choice among alternatives*, it belongs in an ADR — write that instead (step 2), and only add an infra requirement if the underlying constraint isn't already captured.
   - Note the new REQ ID for commit footers

2. **ADR** — invoke the `write-adr` skill steps directly (do not ask the user to run `/write-adr` separately — execute those steps inline here)

3. **Task** — invoke the `write-task` skill steps directly (do not ask the user to run `/write-task` separately — execute those steps inline here)
   - If closing an existing task: update its `status` frontmatter to `done` and update `TASK-INDEX.md` status column to `✅`

---

### 6. Compose the commit message

After all artifacts are written, compose the commit message following `docs/COMMIT_CONVENTION.md`:

```
<type>(<scope>): <subject>

[body — only if the subject alone doesn't explain the why, a tradeoff exists, or migration steps are needed]

Implements: REQ-XX-NNN        ← one per satisfied requirement
See: ADR-NNN                  ← one per relevant ADR
Closes: #NNN                  ← if a GitHub issue exists (from TASK file's github_issue field)
Co-authored-by: Claude <noreply@anthropic.com>
```

Rules:
- If code + docs changed together, they go in **one commit** (a feature is not done until it's documented)
- If multiple unrelated features were built in the same session, **split into separate commits** — propose the split to the user
- Type is determined by the dominant change: `feat` if new capability, `fix` if bug correction, `refactor` if restructure only
- If a cross-cutting pattern changed: add `BREAKING CHANGE:` footer with migration instructions

Present the commit message for user review. Do NOT run `git commit` until the user explicitly says to.

---

### 7. Report what was produced

List everything created or modified:
- New files created (ADRs, task files, PRD sections)
- Files updated (TASK-INDEX.md, milestone doc, PRD.md)
- Proposed commit message (with reminder that the user must approve before it runs)
- If `github_issue: null` in any task file: remind to run `python3 scripts/gh_create_issues.py`
