# 📝 Lokalaku Commit Message Convention

> **Single source of truth** for all commit message formatting in this monorepo.
> Applies to every contributor and every AI agent, regardless of IDE or tool.
>
> Enforced by: `commitlint` (CI) · Templated by: `.gitmessage` · Followed by: `AGENTS.md`

---

## Quick Reference

```
<type>(<scope>): <subject>
│      │          └─ imperative, ≤72 chars, no period
│      └────────── app or package name (see scope table)
└───────────────── feat | fix | docs | refactor | test | chore | perf | ci | revert

[blank line]
[optional body — what & why, wrapped at 72 chars]

[blank line]
[optional footers]
Implements: REQ-XX-NNN
See: ADR-NNN
Refs: #issue
Closes: #issue
BREAKING CHANGE: <description>
```

---

## Format

```
<type>(<scope>): <subject>

[body]

[footers]
```

- **Subject line** = type + scope + subject. Must be ≤ 72 characters total.
- **Blank line** separates subject from body, and body from footers.
- **Body and footers** are optional. Add them when they carry information not obvious from the subject.

---

## Types

| Type | When to use |
|:---|:---|
| `feat` | A new user-visible feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation only — no code change |
| `refactor` | Code restructure with no behaviour change and no bug fix |
| `test` | Adding or updating tests only |
| `chore` | Tooling, dependencies, build scripts, config — no production code |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |
| `revert` | Reverts a previous commit (auto-format: `revert: <original subject>`) |
| `style` | Whitespace, formatting, lint-only — no logic change |

---

## Scopes

Scopes map 1-to-1 with apps and packages in the monorepo.
**Always use the scope that owns the changed code.**

| Scope | Path | Notes |
|:---|:---|:---|
| `api` | `apps/api` | Golang API — endpoints, middleware, DB schema |
| `consumer` | `apps/consumer_app` | Flutter — villager app (Android + PWA) |
| `merchant` | `apps/merchant_app` | Flutter — warung POS (Android tablet + phone) |
| `courier` | `apps/courier_app` | Flutter — delivery app (Android phone) |
| `wholesale` | `apps/wholesaler_app` | Flutter — wholesaler dashboard (Desktop + Web) |
| `backoffice` | `apps/backoffice_web` | Flutter — superadmin web panel |
| `website` | `apps/website` | Astro — public SEO site |
| `domain` | `packages/flutter/domain` | Pure Dart entities, repo interfaces, Result\<T\> |
| `data` | `packages/flutter/data` | Repository implementations |
| `core-auth` | `packages/flutter/core_auth` | Token lifecycle, PIN challenge, refresh timer |
| `core-network` | `packages/flutter/core_network` | HTTP client, interceptors, error models |
| `ui-kit` | `packages/flutter/ui_kit` | Design tokens, shared widgets |
| `utils` | `packages/flutter/utils` | Formatters, validators, extensions |
| `infra` | `docker/`, `compose.yaml`, `scripts/` | Docker, deployment, shell scripts |
| `docs` | `docs/` | Design docs, ADRs, milestones, tasks, glossary |
| `workspace` | Root config | Moon, pnpm, biome, `.prototools`, root `AGENTS.md` |

**Multi-scope commits:** If a single commit legitimately touches two scopes (e.g. `api` + `core-network` for a new endpoint + its client interceptor), use the primary scope and mention the secondary in the body. Prefer splitting into separate commits when feasible.

---

## Subject Line Rules

1. **Imperative mood:** "Add X", "Fix Y", "Remove Z" — not "Added", "Fixed", "Removes"
2. **≤ 72 characters total** (type + scope + subject combined)
3. **No trailing period**
4. **Start lowercase** after the colon — but acronyms (OTP, JWT, POS, PIN, GPS, MOQ, ACID) may stay uppercase within the subject
5. **Be specific:** "fix(merchant): prevent double-write on POS submit" not "fix(merchant): fix bug"
6. **No ticket numbers in the subject** — put them in the footer as `Closes: #NNN`

---

## Body Rules

Include a body when the subject alone does not explain:
- **Why** the change was made (not what — the diff shows what)
- A non-obvious constraint or tradeoff
- A migration step the next developer must perform
- Context a reviewer needs that isn't in the code

Wrap at **72 characters per line**. Use plain prose — no bullet lists unless listing truly parallel items.

---

## Footer Trailers

Footers appear after a blank line following the body (or subject if there is no body).
Each trailer is on its own line.

| Trailer | When to use | Example |
|:---|:---|:---|
| `Implements:` | Commit satisfies a PRD requirement | `Implements: REQ-BG-004` |
| `See:` | References an ADR or design doc | `See: ADR-003` |
| `Refs:` | Related GitHub issue (not closing it) | `Refs: #42` |
| `Closes:` | GitHub issue this commit resolves | `Closes: #42` |
| `Co-authored-by:` | Pair or AI-assisted authorship | `Co-authored-by: Claude <noreply@anthropic.com>` |
| `BREAKING CHANGE:` | Public API or contract change | `BREAKING CHANGE: refresh token is now rotated on every use` |

`BREAKING CHANGE:` triggers a **major** version bump in semantic versioning and must include a description of what breaks and how to migrate.

---

## Examples

### ✅ Good — simple feature, no body needed
```
feat(api): add OTP issuance endpoint with rate limiting
```

### ✅ Good — bug fix with body explaining why
```
fix(merchant): prevent double-submit on POS checkout button

The checkout button remained active while the async write to Hive
was in progress. A second tap would enqueue a duplicate sync queue
entry. Disabled the button on first tap and re-enabled it only
after the local write confirms.

Closes: #87
```

### ✅ Good — cross-cutting change with ADR and PRD references
```
feat(core-auth): add proactive token refresh timer for couriers

Access token is now refreshed at ≤3 minutes remaining, rather than
waiting for a 401. Prevents telemetry interruption mid-route when
the GPS coordinate buffer is active.

Implements: REQ-CO-004
See: ADR-003
Closes: #61
```

### ✅ Good — docs change
```
docs(docs): add ADR-003 for JWT refresh token strategy
```

### ✅ Good — breaking change
```
refactor(core-auth): rotate refresh token on every use

Server-side refresh tokens are now single-use. Each successful
refresh call invalidates the current token and issues a new one.
Clients must persist the new token returned in the refresh response.

BREAKING CHANGE: clients storing the refresh token must update it
after every successful refresh call — the old token is immediately
invalidated. No action needed if using the core_auth package.

See: ADR-003
```

### ❌ Bad — vague subject
```
fix: stuff
```

### ❌ Bad — past tense, no scope, too long
```
Added the new offline PIN challenge screen and also fixed a bug where the timer wasn't stopping correctly on logout
```

### ❌ Bad — scope doesn't match path
```
feat(flutter): add pool dashboard  ← use "merchant" not "flutter"
```

---

## AI Agent Instructions

> **Copy this section** into any AI tool's system prompt or context when you need it to write commit messages for this project.

---

You are writing a Git commit message for the Lokalaku monorepo.
Always follow the Conventional Commits format with Lokalaku-specific scopes.

**Format:**
```
<type>(<scope>): <subject>

[optional body]

[optional footers]
```

**Types:** `feat` | `fix` | `docs` | `refactor` | `test` | `chore` | `perf` | `ci` | `revert` | `style`

**Valid scopes:** `api` | `consumer` | `merchant` | `courier` | `wholesale` | `backoffice` | `website` | `domain` | `data` | `core-auth` | `core-network` | `ui-kit` | `utils` | `infra` | `docs` | `workspace`

**Subject rules:**
- Imperative mood: "Add X" not "Added X"
- ≤ 72 characters total (type + scope + subject)
- Start lowercase after the colon; acronyms (OTP, JWT, POS, PIN, GPS, MOQ) may stay uppercase
- No trailing period
- No ticket numbers — those go in footers

**Add a body when:** the subject alone doesn't explain why the change was made, there is a non-obvious tradeoff, or a migration step is required.

**Footer trailers to include when applicable:**
- `Implements: REQ-XX-NNN` — if the commit satisfies a PRD requirement
- `See: ADR-NNN` — if an architecture decision record is relevant
- `Closes: #NNN` — if a GitHub issue is resolved
- `BREAKING CHANGE: <description>` — if a public contract changes

**Output:** Return only the raw commit message text. No markdown fences, no explanation, no commentary.

---

## Setup

### Git commit template (recommended for all contributors)

Run once per clone to get the `.gitmessage` template in your editor when you `git commit`:

```bash
git config commit.template .gitmessage
```

Or set it globally for all your projects:

```bash
git config --global commit.template /path/to/lokalaku-id/.gitmessage
```

### Automated enforcement (commitlint)

Install once:

```bash
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

Lint the last commit:

```bash
pnpm exec commitlint --from HEAD~1 --to HEAD
```

Lint in CI (add to your pipeline):

```bash
pnpm exec commitlint --from origin/main --to HEAD
```

To enforce on every local commit via a git hook, add this to `.husky/commit-msg`:

```bash
pnpm exec commitlint --edit "$1"
```
