# IDE and Editor Setup for Lokalaku AI Workflow

This guide helps you configure AI assistants in various IDEs and editors to work effectively with the Lokalaku codebase.

## Supported IDEs and Editors

| IDE/Editor | Status | Configuration Files |
|:---|:---:|:---|
| **Zed** | ✅ Primary | `AGENTS.md`, `.agents/skills/*` |
| **VSCode** | ✅ Supported | `.vscode/settings.json`, `.vscode/extensions.json` |
| **Cursor** | ✅ Supported | `.cursor/rules/commit-messages.mdc` |
| **Claude Code** | ✅ Supported | `.claude/skills/*` |
| **Neovim** | ✅ Supported | `avante.md` |
| **JetBrains IDEs** | ✅ Supported | `.aiassistant/rules/project-guidelines.md` |

## Quick Start for Each IDE

### Zed (Primary - ZED NATIVE)

Zed has the most complete integration with the Lokalaku workflow.

**Features:**
- Automatic skill suggestions (`write-adr`, `write-task`, `record-milestone`)
- Document Map routing system for efficient context retrieval
- Token-optimized agent behavior

**Setup:**
1. Open the Lokalaku project in Zed
2. The `AGENTS.md` file is automatically loaded as project context
3. Use the skills system via `/` commands or let Zed suggest them

### Visual Studio Code

**Setup:**

1. Install recommended extensions:
   ```bash
   # VSCode will prompt to install these from .vscode/extensions.json
   - Astro
   - Biome
   - Tailwind CSS IntelliSense
   - Markdown Table Prettify
   - Docker
   - EditorConfig
   - Go
   - Even Better TOML
   ```

2. Configure AI assistant (Copilot Chat, Cody, or similar) to read:
   - `AGENTS.md` for general guidelines
   - `avante.md` for project instructions (this is IDE-agnostic)

3. Use the tier-based documentation system (see below)

### Cursor

**Setup:**

1. Cursor has built-in AI with project rules in `.cursor/rules/`
2. The commit message convention is already configured
3. For general project context, Cursor will read `AGENTS.md`

4. Use the tier-based documentation system (see below)

### Claude Code

**Setup:**

1. Claude Code uses `.claude/skills/` for reusable workflows
2. Available skills:
   - `write-adr` — Document architectural decisions
   - `write-task` — Create and track tasks
   - `record-milestone` — Update milestone documentation
   - `reconcile` — Sync documentation with code changes

3. Invoke skills by name: "Use the write-adr skill for..."

4. Claude will automatically load relevant documentation based on context

### Neovim with avante.nvim

**Setup:**

1. Install [avante.nvim](https://github.com/yetone/avante.nvim):

   ```lua
   -- Using lazy.nvim
   {
     "yetone/avante.nvim",
     event = "VeryLazy",
     opts = {
       -- Your avante.nvim configuration
     },
   }
   ```

2. The `avante.md` file in the project root provides project-specific instructions

3. avante.nvim will automatically load `avante.md` as context for AI operations

4. Use the tier-based documentation system (see below)

### JetBrains IDEs (IntelliJ IDEA, GoLand, PyCharm, WebStorm, etc.)

**Setup:**

1. Enable AI Assistant plugin (if not already enabled)
   - Go to `Settings → Tools → AI Assistant`

2. Configure project rules:
   - Go to `Settings → Tools → AI Assistant → Rules`
   - The `.aiassistant/rules/project-guidelines.md` file will be auto-detected
   - Alternatively, manually create rules from this file

3. Rule types:
   - **Always** — Automatically applied to all chat sessions
   - **Manually** — Invoke via `@rule:project-guidelines` or `#rule:project-guidelines`
   - **By model decision** — AI decides when to apply

4. Use the tier-based documentation system (see below)

## Tier-Based Documentation System

All IDEs benefit from the same documentation routing system. This saves tokens and prevents context bloat.

### How It Works

Before starting any task, classify it into a tier:

| Tier | Description | What to Read |
|:---|:---|:---|
| **Tier 0** | Simple, self-contained changes | Nothing (proceed) |
| **Tier 1** | Within one app/package | One `AGENTS.md` file |
| **Tier 2** | New feature/endpoint | Per-app PRD + design doc |
| **Tier 3** | Cross-cutting architecture | Root PRD + ADRs |
| **Tier 4** | Historical rationale | Specific ADR/milestone |
| **Tier 5** | Task planning | Task index + templates |

### Tier 0 — Proceed Immediately

No documentation needed for:
- Typos, formatting, import ordering, linter/vet errors
- Isolated UI color token swaps or spacing adjustments
- Adding null checks or guard clauses
- Renaming local variables

### Tier 1 — Local Scope

Read one `AGENTS.md` file based on where you're working:

| Working in | Read this file |
|:---|:---|
| `apps/api/` | `apps/api/AGENTS.md` |
| `apps/consumer_app/` | `apps/consumer_app/AGENTS.md` |
| `apps/merchant_app/` | `apps/merchant_app/AGENTS.md` |
| `apps/courier_app/` | `apps/courier_app/AGENTS.md` |
| `apps/wholesaler_app/` | `apps/wholesaler_app/AGENTS.md` |
| `apps/backoffice_web/` | `apps/backoffice_web/AGENTS.md` |
| `apps/website/` | `apps/website/AGENTS.md` |
| `packages/flutter/*` | `packages/flutter/AGENTS.md` |

### Tier 2 — New Feature or Endpoint

Read:
- Per-app PRD: `apps/<app>/PRD.md` or `apps/api/PRD.md`
- Design doc if exists: `docs/design/NN-<feature>.md`

### Tier 3 — Cross-Cutting Architecture

Read:
- `PRD.md` (root) — full product scope
- `docs/decisions/ADR-*.md` — check existing decisions

After completing the task, create a new ADR if the decision isn't already recorded.

### Tier 4 — Historical Rationale

Read the specific ADR or milestone doc:
- `docs/decisions/ADR-*.md` — find by topic
- `docs/milestones/MXXX-*.md` — milestone rationale

### Tier 5 — Task Planning

Read:
- `docs/tasks/TASK-INDEX.md` — review all tasks
- `docs/tasks/TASK-TEMPLATE.md` — for creating new tasks

## Core Architectural Principles (All IDEs)

All AI assistants should respect these principles:

1. **Zero Vendor Lock-In**: Deploy on bare-metal VPS or Docker. No cloud-native proprietary APIs.

2. **Offline-First Operations**: Mobile apps handle low/no internet via local caching.

3. **Data Sovereignty**: Data belongs to `cluster_id`. Strict isolation between clusters.

4. **Efficiency Over Hype**: Memory-efficient, low-allocation code. Target low-end devices.

5. **Behavioral Test Coverage**: Every `feat` needs tests. `fix`/`refactor` requires verifying tests.

## Tech Stack Quick Reference

### Go API (`apps/api/`)
- Language: Go (stdlib-first)
- Router: Chi or Fiber
- Database: PostgreSQL 17
- Cache: Redis
- Testing: `go test ./apps/api/...`

### Flutter Apps (`apps/*`)
- Framework: Flutter 3.x
- State: Riverpod v3+ only
- Navigation: GoRouter
- Offline: Hive/Isar
- Testing: `flutter test` or `moon run <app>:test`

### Shared Packages (`packages/flutter/`)
- `domain`/`utils`: Pure Dart, zero Flutter SDK
- `ui_kit`: Widgets only, zero business logic
- All repo methods return `Result<T>`
- Testing: `moon run :test`

### Website (`apps/website`)
- Framework: Astro 5.x with Islands Architecture
- Styling: TailwindCSS
- Rendering: 95% static HTML/SSR
- Interactive: Only search box and filters use React

## Commit Convention

All IDEs should follow the same commit format:

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

Full details in `docs/COMMIT_CONVENTION.md`.

## Common Commands

From repository root:

```bash
# Dependencies
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

## Additional Resources

- **Commit convention**: `docs/COMMIT_CONVENTION.md`
- **Product requirements**: `PRD.md` (root) or per-app PRDs
- **Glossary**: `docs/GLOSSARY.md`
- **Architecture decisions**: `docs/decisions/ADR-*.md`
- **Tasks**: `docs/tasks/TASK-INDEX.md`
- **Milestones**: `docs/milestones/CHANGELOG.md`

## AI Agent Skills (Reusable Workflows)

The project includes reusable workflows available in all IDEs:

- `write-adr` — Document architectural decisions
- `write-task` — Create and track tasks
- `record-milestone` — Update milestone documentation
- `reconcile` — Sync documentation with code changes (Claude Code only)

Skills are located in `.agents/skills/` with detailed instructions.

## Adding Support for New IDEs

To add support for a new IDE:

1. Create IDE-specific configuration files in the appropriate directory
2. Reference the existing documentation: `AGENTS.md`, `avante.md`, `.aiassistant/rules/project-guidelines.md`
3. Ensure the tier-based documentation system is explained
4. Add the IDE to the supported list in this file

## Getting Help

- For IDE-specific issues, refer to your IDE's documentation
- For Lokalaku workflow questions, refer to `AGENTS.md` and the relevant PRD
- For architectural questions, check `docs/decisions/ADR-*.md` first