# Lokalaku Project Rules for JetBrains AI Assistant

This file defines project-specific guidelines for AI assistants working in JetBrains IDEs (IntelliJ IDEA, GoLand, PyCharm, WebStorm, etc.).

## Task Complexity Documentation Tiers

Before making changes, read documentation based on task complexity:

### Tier 0 — No documentation needed
- Simple fixes: typos, formatting, import ordering, linter errors
- Isolated UI tweaks: colors, spacing adjustments
- Adding null checks or guard clauses
- Local variable renaming

### Tier 1 — Read one AGENTS.md file
Working within a single app or package? Read that context file:

| Working directory | Documentation file |
|:---|:---|
| `apps/api/` | `apps/api/AGENTS.md` |
| `apps/consumer_app/` | `apps/consumer_app/AGENTS.md` |
| `apps/merchant_app/` | `apps/merchant_app/AGENTS.md` |
| `apps/courier_app/` | `apps/courier_app/AGENTS.md` |
| `apps/wholesaler_app/` | `apps/wholesaler_app/AGENTS.md` |
| `apps/backoffice_web/` | `apps/backoffice_web/AGENTS.md` |
| `apps/website/` | `apps/website/AGENTS.md` |
| `packages/flutter/` | `packages/flutter/AGENTS.md` |

### Tier 2 — New features or endpoints
Implementing new features or tasks from `docs/tasks/`? Read:

- Per-app PRD: `apps/<app>/PRD.md` or `apps/api/PRD.md`
- Design doc if exists: `docs/design/NN-<feature>.md`

### Tier 3 — Cross-cutting architectural changes
Making decisions affecting multiple apps, data models, or platform patterns? Read:

- `PRD.md` (root) — full product scope
- `docs/decisions/ADR-*.md` — existing architectural decisions

## Core Architectural Principles

1. **Zero Vendor Lock-In**: Systems must be deployable on bare-metal VPS or Docker. Avoid cloud-native proprietary APIs (Vercel, AWS-only tools).

2. **Offline-First Operations**: Mobile apps (Merchant/Courier) must gracefully handle low/no internet via local caching.

3. **Data Sovereignty**: Data belongs to specific local cluster (`cluster_id`). Strict isolation between clusters.

4. **Efficiency Over Hype**: Write memory-efficient, low-allocation code. Target low-end devices and cheap infrastructure.

5. **Behavioral Test Coverage**:
   - Every `feat` requires tests covering acceptance criteria
   - `fix`/`refactor` requires verifying existing tests pass
   - No `feat` commit without test files

## Monorepo Structure

```
lokalaku-id/
├── apps/
│   ├── api/              Golang REST API
│   ├── website/          Astro public website
│   ├── consumer_app/     Flutter (Android + Web/PWA)
│   ├── merchant_app/     Flutter (Android tablet + phone)
│   ├── courier_app/      Flutter (Android phone)
│   ├── wholesaler_app/   Flutter (Desktop + Web)
│   └── backoffice_web/   Flutter Web (Superadmin)
└── packages/
    └── flutter/          Shared Dart packages
        ├── ui_kit/           Design system & widgets
        ├── domain/           Pure Dart entities
        ├── core_network/     HTTP client & error handling
        ├── core_auth/        Auth & token lifecycle
        ├── data/             Repository implementations
        └── utils/            Formatters, validators
```

## Tech Stack Guidelines

### Go API (`apps/api/`)
- **Language**: Go (stdlib-first, single binary)
- **Router**: Chi or Fiber (lightweight)
- **Database**: PostgreSQL 17
- **Cache**: Redis (read aggregates for search)
- **Style**: Idiomatic Go, explicit error returns, thorough `nil` checks
- **Prohibited**: Heavy enterprise frameworks, cloud-native APIs
- **Testing**: `*_test.go` alongside code, run `go test ./apps/api/...`

### Flutter Apps (`apps/*`)
- **Framework**: Flutter 3.x
- **State Management**: Riverpod v3+ (`Notifier<State>` + `NotifierProvider` only)
- **Navigation**: GoRouter
- **Offline**: Hive/Isar (local-first writes, background sync)
- **Prohibited**: `StateNotifier`, Bloc, GetX, Provider, web views for core features
- **Testing**: `*_test.dart` mirroring lib structure, run `flutter test` or `moon run <app>:test`

### Shared Packages (`packages/flutter/`)
- **Rules**:
  - `domain` and `utils`: Pure Dart, zero Flutter SDK
  - `ui_kit`: Widgets only, zero business logic
  - Packages never import from `apps/`; apps never import each other
  - All repository methods return `Result<T>`, never throw exceptions across boundaries
  - All packages: `publish_to: none`
- **Testing**: Pure Dart packages use `dart test`, not `flutter_test`
- **Commands**: Run `moon run :test` for all packages

### Website (`apps/website`)
- **Framework**: Astro 5.x with Islands Architecture
- **Styling**: TailwindCSS
- **Rendering**: 95% static HTML/SSR for SEO
- **Interactive**: Only `<SearchBox client:load />` and distance filters use React
- **Prohibited**: Full-page React CSR, Next.js-specific routing, heavy component libraries

## Commit Convention

Follow `docs/COMMIT_CONVENTION.md`. Format:

```
<type>(<scope>): <subject>

[body - explain WHY]

Implements: REQ-XX-NNN
See: ADR-NNN
Closes: #NNN
```

**Types**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `revert`, `style`

**Scopes**:
- Apps: `api`, `consumer`, `merchant`, `courier`, `wholesale`, `backoffice`, `website`
- Packages: `domain`, `data`, `core-auth`, `core-network`, `ui-kit`, `utils`
- Other: `infra`, `docs`, `workspace`

## Workflow Commands

From repository root:

```bash
# Install dependencies
moon run :get              # All Dart/Flutter packages
pnpm install               # Node tooling

# Linting
moon run :lint             # All packages

# Testing
moon run :test             # All packages
go test ./apps/api/...     # Go API
flutter test               # Current Flutter app

# Code generation
moon run domain:build-runner
moon run data:build-runner

# Infrastructure
pnpm compose:up            # Start services
pnpm compose:down          # Stop services
```

## Key Behavioral Rules

### Mobile Apps
- **Offline-first**: Write to local storage immediately, sync in background
- **Low-signal resiliency**: Graceful handling of 2G/3G/offline transitions
- **60FPS target**: Optimize for older Android chipsets

### API
- **Multi-tenancy**: Strict `cluster_id` validation (except consumer discovery endpoints)
- **ACID compliance**: Pool Order state transitions must be atomic transactions
- **Role-based auth**: JWT (15min) + opaque refresh tokens (30 days, server-side, rotated)

### Data Flow
```
Flutter Apps & Website
    ↓ (REST API)
Go API Core
    ↓ (Server-Side Fetch)
Astro Website
```

Flutter apps consume from `packages/flutter/*`. Apps never import each other.

## Additional Resources

- **Commit convention**: `docs/COMMIT_CONVENTION.md`
- **Product requirements**: `PRD.md` (root) or per-app PRDs
- **Glossary**: `docs/GLOSSARY.md`
- **Architecture decisions**: `docs/decisions/ADR-*.md`
- **Tasks**: `docs/tasks/TASK-INDEX.md`
- **Milestones**: `docs/milestones/CHANGELOG.md`

## AI Agent Skills

The project includes reusable workflows for AI agents:

- `write-adr` — Document architectural decisions
- `write-task` — Create and track tasks
- `record-milestone` — Update milestone documentation

Skills are located in `.agents/skills/` with detailed instructions.