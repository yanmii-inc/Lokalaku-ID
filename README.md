<div align="center">

# Lokalaku

**Hyper-local. Community-owned. Zero middlemen.**

An open-source, decentralized digital ecosystem connecting wholesale hubs directly to neighborhood stores and end-consumers.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](#)
[![Moon](https://img.shields.io/badge/Moon-2.2.4-blueviolet)](https://moonrepo.dev)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go&logoColor=white)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](#)
[![Astro](https://img.shields.io/badge/Astro-5.x-FF5D01?logo=astro&logoColor=white)](#)

</div>

**Docs:** [Why](./docs/WHY.md) · [Architecture](./docs/ARCHITECTURE.md) · [Processes](./docs/PROCESSES.md) · [PRD](./PRD.md) · [Glossary](./docs/GLOSSARY.md) · [IDE Setup](./docs/IDE_SETUP.md)

---

## Ecosystem

```
 Consumer ──► consumer_app        │
 Merchant ──► merchant_app        ├──► Golang API (PostgreSQL · Redis)
 Courier  ──► courier_app         │
 Wholesaler─► wholesaler_app      │
 Superadmin─► backoffice_web      │
 Public   ──► website (Astro SSR) │
```

## Repository

```
apps/
├── api/              Go REST API
├── website/          Astro public catalog
├── consumer_app/     Flutter (Android + Web PWA)
├── merchant_app/     Flutter POS (phone + tablet)
├── courier_app/      Flutter delivery (phone)
├── wholesaler_app/   Flutter (Desktop + Web)
└── backoffice_web/   Flutter Web dashboard

packages/flutter/
├── domain/           Pure Dart entities & repo interfaces
├── data/             Repo implementations (Dio, Hive, Isar)
├── core_network/     HTTP client & error handling
├── core_auth/        Auth & session lifecycle
├── ui_kit/           Design system & widgets
└── utils/            Formatters, validators, extensions
```

---

## Getting Started

```bash
git clone https://github.com/your-org/lokalaku-id.git && cd lokalaku-id
pnpm install                # Node dependencies
moon run :get               # Dart/Flutter dependencies
pnpm compose:up             # PostgreSQL + Mailpit + Jaeger
```

| Service | URL / Port |
|:---|:---|
| PostgreSQL | `localhost:5432` |
| Mailpit | `http://localhost:8025` |
| Jaeger | `http://localhost:16686` |

```bash
cd apps/api && go run ./cmd/server            # Run API
cd apps/merchant_app && flutter run            # Run Flutter app
cd apps/website && pnpm dev                     # Run website
```

## Commands

| Command | Action |
|:---|:---|
| `moon run :test` | Run all tests |
| `moon run :lint` | Lint everything |
| `pnpm typecheck` | Typecheck website (JS/TS) |
| `moon run domain:build-runner` | Codegen (domain) |
| `moon run data:build-runner` | Codegen (data) |
| `pnpm compose:down` | Stop Docker services |
| `pnpm compose:cleanup` | Stop + wipe volumes |

---

## Contributing

Read [`AGENTS.md`](./AGENTS.md) for architectural principles and per-app/package rules. Open an issue before starting significant work.

## License

MIT
