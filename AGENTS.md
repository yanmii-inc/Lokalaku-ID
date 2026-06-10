# 🤖 LOKALAKU: AI AGENTS & CO-PILOT CONFIGURATION GUIDELINES

Welcome, AI Agent / Co-pilot. You are assisting in building **Lokalaku**, an open-source, decentralized alternative platform to give communities full control over their own local economy. It orchestrates an entire local supply chain — from factory-direct wholesale sourcing all the way to consumers buying goods at their neighborhood warung — through five purpose-built apps sharing a single, high-performance API core. This is a **Polyglot Monorepo** containing Golang (API), Flutter (Apps), and Astro (Public Website).

To ensure architectural consistency, reduce code debt, and prevent cross-framework pollution, you **MUST** strictly follow the guidelines below based on the workspace context you are operating in.

> **IDE:** All major IDEs supported. See [`docs/IDE_SETUP.md`](./docs/IDE_SETUP.md). You are running in **Zed** which auto-loads this file as project rules.

---

## 🌍 GLOBAL ARCHITECTURAL PRINCIPLES (ALL AGENTS MUST READ)

1. **Zero Vendor Lock-In:** All systems must be deployable on a bare-metal VPS or Docker container. Avoid cloud-native proprietary APIs (e.g., Vercel-specific features, AWS-only tools).
2. **Offline-First for Operations:** Mobile apps (Merchant/Courier) must gracefully handle low/no internet scenarios using local caching.
3. **Data Sovereignty:** Data belongs to the specific local cluster (`cluster_id`). Ensure strict isolation between different cluster datasets.
4. **Efficiency Over Hype:** Write memory-efficient, low-allocation code. We target low-end devices and cheap infrastructure.
5. **Behavioral Test Coverage:** Every new feature (`feat`) must ship with tests that cover its acceptance criteria. Changes to existing features or refactors must verify that existing tests still pass and adjust them to reflect the new behaviour. No `feat` commit is done without test files. No `fix`/`refactor` is done without running the test suite.

---

## ⚖️ CONTEXT RETRIEVAL ECONOMY (TOKEN-SAVING)

To save API input tokens and prevent context bloat, obey these execution rules:

* **No Blind Indexing:** Do NOT read or demand full external documentation files for simple syntax fixes, typos, formatting, or isolated UI styling.
* **Conditional Trigger:** Use the **Document Map** below to determine exactly which files to read. Reading more than the tier requires is wasteful. Reading less causes errors.
* **Targeted Diffs Only:** Do NOT rewrite hundreds of unchanged lines of code. Provide minimal code blocks or targeted updates.

---

## 🗺️ DOCUMENT MAP — INTELLIGENT ROUTING

**Before fetching any file, classify your task using the tiers below. Fetch only what the tier requires.**

---

### Tier 0 — Proceed immediately, no extra reads

Simple, self-contained changes with no domain ambiguity:
- Typos, formatting, import ordering, linter/vet errors
- Isolated UI colour token swaps or spacing adjustments
- Adding a null check or guard clause to existing logic
- Renaming a local variable

→ **Fetch nothing. Proceed.**

---

### Tier 1 — Local scope: read one local AGENTS.md

You are modifying code within a known app or package, and the rules of that context are all you need:
- Adding a screen, widget, or method to an existing feature
- Fixing a bug that is clearly contained within one app or package

| Working in | Read this file |
|:---|:---|
| `apps/api/` | `apps/api/AGENTS.md` (if it exists) |
| `apps/consumer_app/` | `apps/consumer_app/AGENTS.md` |
| `apps/merchant_app/` | `apps/merchant_app/AGENTS.md` |
| `apps/courier_app/` | `apps/courier_app/AGENTS.md` |
| `apps/wholesaler_app/` | `apps/wholesaler_app/AGENTS.md` |
| `apps/backoffice_web/` | `apps/backoffice_web/AGENTS.md` |
| `apps/website/` | `apps/website/AGENTS.md` |
| `packages/flutter/*` | `packages/flutter/AGENTS.md` |

→ Read **one file only**. Stop there.

---

### Tier 2 — New feature or endpoint: read local PRD + design doc

You are implementing something new within a known scope, or picking up a defined task:
- New API endpoint, new DB table, new Flutter screen tied to a PRD requirement
- Implementing a feature from a task in `docs/tasks/`

| Working in | Read these files |
|:---|:---|
| Go API work | `apps/api/PRD.md` + `apps/api/GUARDRAILS.md` |
| Any Flutter app feature | `apps/<app>/PRD.md` + `docs/design/NN-<feature>.md` (if exists) |
| Astro/website work | `apps/website/PRD.md` + `apps/website/GUARDRAILS.md` |
| Shared Flutter package | `packages/flutter/AGENTS.md` |
| Infra work (Docker, Compose, CI/CD, scripts) | `docs/infra/REQUIREMENTS.md` |

→ Read the **local PRD** for the affected app. Read the **design doc** if one covers this feature. Stop there.

---

### Tier 3 — Cross-cutting architecture: read root PRD + check ADRs

You are making a decision that affects multiple apps, the data model, or a platform-wide pattern:
- Choosing a library or dependency
- Modifying the Pool Order state machine, auth flow, or sync queue strategy
- Adding a new entity to `lokalaku_domain`
- Adding or removing a shared package

| Action | Read this |
|:---|:---|
| Understand full product scope | `PRD.md` (root) |
| Resolve ambiguous domain terminology | `docs/GLOSSARY.md` |
| Check if this decision was already made | `docs/decisions/ADR-*.md` |

→ **After completing the task:** create a new ADR in `docs/decisions/` if the architectural choice isn't already recorded.

---

### Tier 4 — Historical rationale: read ADRs + milestone docs

You need to understand why something was designed a certain way before extending it:
- "Why does auth use opaque refresh tokens and not long-lived JWTs?"
- "Why Hive and not SQLite for offline storage?"
- Reviewing a past milestone before adding a new feature on top of it

| Action | Read this |
|:---|:---|
| Find the architectural decision | `docs/decisions/ADR-*.md` |
| Understand milestone history and rationale | `docs/milestones/CHANGELOG.md` → then the specific `MXXX-*.md` |

→ Read the **specific ADR or milestone doc**. Do not read all of them.

---

### Tier 5 — Task planning: read task index + templates

You are decomposing PRD requirements into tasks, reviewing what work exists, or generating GitHub Issues:

| Action | Do this |
|:---|:---|
| Review all tasks and their status | Read `docs/tasks/TASK-INDEX.md` |
| Create a new task file | Copy `docs/tasks/TASK-TEMPLATE.md` |
| Push unlinked tasks to GitHub Issues | Run `python3 scripts/gh_create_issues.py --dry-run` first, then without `--dry-run` |

---

### Agent Skills — Reusable Workflows

These project-local skills encode the exact steps for common documentation tasks.
They are available in multiple IDEs (Zed, Claude Code, and others with custom prompts).

| Skill | Trigger phrases | What it does |
|:---|:---|:---|
| `write-adr` | "write an ADR for X", "document why we chose Y", "record this decision" | Reads the template, numbers the next ADR, creates the file, links it to the active milestone |
| `write-task` | "create a task for X", "break down REQ-XX", "add a work item" | Reads TASK-INDEX + template, creates the task file, updates the index row |
| `record-milestone` | "update the milestone", "mark M00X as done", "checkpoint our progress" | Updates the milestone doc + CHANGELOG.md with decisions, deferred work, and lessons learned |
| `reconcile` | "reconcile", "catch up the docs", "document what we just built" | Syncs documentation with code changes, identifies missing artifacts (Claude Code only) |

**Skill locations:**
- `.agents/skills/` — Universal skill definitions
- `.claude/skills/` — Claude Code-specific formats
- Zed auto-suggests skills when your prompt matches (invoke via `/`)

---

### Full Document Registry

| Document | Path | Tier |
|:---|:---|:---:|
| Global AI rules + routing (this file) | `AGENTS.md` | Auto-loaded |
| **Commit message convention** | **`docs/COMMIT_CONVENTION.md`** | **Always** |
| IDE setup guide | `docs/IDE_SETUP.md` | Reference |
| Domain glossary | `docs/GLOSSARY.md` | 3 |
| Ecosystem PRD (product vision) | `PRD.md` | 3 |
| **Infrastructure requirements (operational, not product)** | **`docs/infra/REQUIREMENTS.md`** | **2–3** |
| API business rules | `apps/api/PRD.md` | 2 |
| API concurrency + memory constraints | `apps/api/GUARDRAILS.md` | 2 |
| Per-app product requirements | `apps/<app>/PRD.md` | 2 |
| Per-app AI rules | `apps/<app>/AGENTS.md` | 1 |
| Shared packages rules | `packages/flutter/AGENTS.md` | 1 |
| Website SEO + bundle constraints | `apps/website/GUARDRAILS.md` | 2 |
| Feature flow designs | `docs/design/NN-<feature>.md` | 2 |
| Architecture Decision Records | `docs/decisions/NNN-<title>.md` | 3–4 |
| Milestone changelog index | `docs/milestones/CHANGELOG.md` | 4 |
| Specific milestone rationale | `docs/milestones/MXXX-<title>.md` | 4 |
| Task registry | `docs/tasks/TASK-INDEX.md` | 5 |
| Task template | `docs/tasks/TASK-TEMPLATE.md` | 5 |

---

## 🛠️ CONTEXT-SPECIFIC AGENT INSTRUCTIONS

### 1. 🐹 Context: `/apps/api`
**Role:** High-Performance, Low-Allocation REST API Server.
* **Tech Stack:** Golang (Standard Library or lightweight router like Chi/Fiber), PostgreSQL, Redis (Caching Layer).
* **State Management & Concurrency:** Use native Go channels and mutexes carefully. Ensure ACID compliance for transactions, especially during `Pool_Orders` aggregation to prevent race conditions.
* **Local Boundaries:** Always fetch and obey `/apps/api/GUARDRAILS.md` for specific concurrency and memory constraints.
* **Prohibited:** Do NOT suggest heavy enterprise frameworks. Keep it single-binary friendly.
* **Code Style:** Idiomatic Go. Return errors explicitly. Handle `nil` checks thoroughly.
* **Testing:**
    * Test files live alongside the code they test: `apps/api/internal/<pkg>/<file>_test.go`.
    * New handler/service/repo: write a `_test.go` covering the happy path and at least one error path.
    * Run: `go test ./apps/api/...` — must pass clean before committing.
    * For `fix`/`refactor`: run the full suite and adjust any tests that reflect the changed behaviour.

### 2. 📱 Context: `/apps` (Flutter Applications)
**Role:** Multi-role cross-platform applications with high UX responsiveness.
* **Tech Stack:** Flutter (Dart), Riverpod v3+ (state management), GoRouter (navigation).
* **Shared Packages:** All Flutter apps consume packages from `/packages/flutter/`. Always check existing packages before adding a new dependency directly to an app. Never duplicate logic that belongs in a shared package.
* **Local Boundaries:** Each app has its own `AGENTS.md` with app-specific rules. Always read it before making changes to that app.
* **Sub-Projects Rules:**
    * `/apps/merchant_app`: Responsive layout (Tablet & Phone) optimized for fast item-tapping and cash register flow (POS).
    * `/apps/courier_app`: Phone layout, highly optimized for portrait mode, map/GPS tracking efficiency, and background notification reliability.
    * `/apps/consumer_app`: Cross-platform for Android (Native APK) **and Web (Flutter Web)**. Android remains the primary target for end-consumers. Web build must be responsive (mobile-first) and deployed as a PWA where possible. Use Web Push API for browser-side notifications; native push (FCM) remains the primary channel on Android. Do NOT use platform-specific packages without a proper `kIsWeb` guard. Localized proximity browsing must degrade gracefully on web (no GPS hard-crash; prompt permission before use).
    * `/apps/wholesaler_app`: Flutter Desktop **and** Web app for Wholesale Operators and Factory Hubs. Desktop (macOS/Linux/Windows) is the primary target; Web build is a supported secondary target. Manages their product catalogue, monitors Pool Order commitments from merchants, and advances pool fulfillment status. Scoped strictly to the wholesaler's own products and assigned clusters. Apply `kIsWeb` guards for any desktop-only API usage (e.g. file system access for bulk import).
    * `/apps/backoffice_web`: Platform Superadmin dashboard for Lokalaku operators only. Manages cluster creation, wholesaler verification, platform-wide configuration, and cross-cluster health monitoring. Do NOT add wholesaler stock management or merchant/courier account flows here — those belong in `wholesaler_app` and the respective operator apps.
* **State Management:** Riverpod v3+ only. Use `Notifier<State>` + `NotifierProvider`. Do NOT use `StateNotifier`, Bloc, GetX, or Provider.
* **Prohibited:** Do NOT suggest embedding web views for core functionalities. All checkout and scanning flows must be native components.
* **Testing:**
    * Test files live in `apps/<app>/test/` mirroring the `lib/` structure: `lib/features/auth/login_notifier.dart` → `test/features/auth/login_notifier_test.dart`.
    * New screen/notifier/use-case: write a `_test.dart` covering state transitions and at least one error state.
    * Run: `flutter test` from the app directory (or `moon run <app>:test` from repo root).
    * For `fix`/`refactor`: run the suite and update any golden files or state expectations that changed.

### 3. 📦 Context: `/packages/flutter` (Shared Flutter/Dart Packages)
**Role:** Reusable building blocks shared across all Flutter apps. Managed as a Melos workspace.
* **Package responsibilities and strict dependency rules:** Always fetch and obey `/packages/flutter/AGENTS.md` before modifying any shared package.
* **Key rules (summary):**
    * `domain` and `utils` are pure Dart — zero Flutter SDK, zero internal imports.
    * `ui_kit` is widgets-only — zero business logic, zero network calls.
    * Packages never import from `apps/`. Apps never import from each other.
    * All repository methods return `Result<T>`. Never throw raw exceptions across package boundaries.
    * `publish_to: none` on every package `pubspec.yaml`.
* **Testing:**
    * Test files live in `packages/flutter/<pkg>/test/` mirroring the `lib/` structure.
    * New entity/repo method/utility: write a `_test.dart`. Pure Dart packages (`domain`, `utils`) must have pure Dart tests — no `flutter_test`, no widget binding.
    * Run: `moon run :test` — must pass clean. Run `moon run <pkg>:test` to test a single package.
    * For `fix`/`refactor`: run `moon run :test` and adjust tests that reflect the changed behaviour.
* **Workspace commands (Moon — run from repo root):**
    * `moon run :get` — install dependencies across all Dart packages
    * `moon run :lint` — lint all packages (respects dependency order)
    * `moon run :test` — test all packages
    * `moon run domain:build-runner` / `moon run data:build-runner` — code generation
    * `moon project <name>` — inspect a package's task graph

### 4. 🚀 Context: `/apps/website`
**Role:** Super-fast, lightweight public-facing catalog and marketplace directory.
* **Tech Stack:** Astro Framework, HTML5, TailwindCSS, React (Strictly isolated for interactive elements only).
* **Local Boundaries:** Always fetch and obey `/apps/website/GUARDRAILS.md` to protect core SEO metrics.
* **SEO & Rendering Rule:** 95% of the website must be compiled into pure static HTML or Server-Side Rendered (SSR) on demand.
* **Islands Architecture:** You may ONLY inject React components for the Live Search Box (`<SearchBox client:load />`) or dynamic distance filters. The rest must be HTML-first without hydration overhead.
* **Prohibited:**
    * Do NOT suggest full-page React Client-Side Rendering (CSR).
    * Do NOT suggest Next.js-specific routing or caching methods.
    * Do NOT introduce heavy component libraries that bloat the client bundle size.
* **Testing:** New interactive Islands (React components) must have `.test.ts` / `.spec.ts` files. SSR-only pages have no test requirement unless they contain logic. Run: `pnpm test` (when configured).

---

## 📝 COMMIT CONVENTION

Every commit to this repository must follow [`docs/COMMIT_CONVENTION.md`](docs/COMMIT_CONVENTION.md).

Key rules (read the full doc for examples and all footer trailers):

```
<type>(<scope>): <subject>   ← imperative, ≤72 chars, no period
```

| Applies to | Detail |
|:---|:---|
| **Types** | `feat` `fix` `docs` `refactor` `test` `chore` `perf` `ci` `revert` `style` |
| **Scopes** | `api` `consumer` `merchant` `courier` `wholesale` `backoffice` `website` `domain` `data` `core-auth` `core-network` `ui-kit` `utils` `infra` `docs` `workspace` |
| **Footers** | `Implements: REQ-XX-NNN` · `See: ADR-NNN` · `Closes: #NNN` · `BREAKING CHANGE: <desc>` |

Enforced automatically by `commitlint` (`.commitlintrc.json`). Templated by `.gitmessage`.

