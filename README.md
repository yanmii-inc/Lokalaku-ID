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
| API Server | `http://localhost:8080` |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| Mailpit UI | `http://localhost:8025` |

### Local Development Infrastructure (Docker Compose)

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Manage the local stack:
```bash
# Start all dev services (API, PostgreSQL, Redis, Mailpit)
docker compose -f docker-compose.dev.yml up -d --build

# View logs
docker compose -f docker-compose.dev.yml logs -f

# Stop services
docker compose -f docker-compose.dev.yml down

# Reset environment and wipe database volumes
docker compose -f docker-compose.dev.yml down -v

# Run database migrations and seed test data manually
./scripts/seed.sh
```

### Seed Test Accounts (Password for all: `Password123!`)

| Role | Phone | Email | Cluster |
|:---|:---|:---|:---|
| **Superadmin** | `+6281111111111` | `admin@lokalaku.id` | *(Global / None)* |
| **Backoffice Admin** | `+6281666666666` | `admin.sukamaju@lokalaku.id` | Desa Sukamaju (`sukamaju-001`) |
| **Merchant** | `+6281222222222` | `warung.budi@lokalaku.id` | Desa Sukamaju (`sukamaju-001`) |
| **Wholesaler** | `+6281333333333` | `grosir.jaya@lokalaku.id` | *(Global / None)* |
| **Courier** | `+6281444444444` | `kurir.agus@lokalaku.id` | *(Global / None)* |
| **Consumer** | `+6281555555555` | `warga.siti@lokalaku.id` | *(Global / None)* |

```bash
cd apps/api && go run ./cmd/server            # Run API locally
cd apps/merchant_app && flutter run            # Run Flutter app
cd apps/website && pnpm dev                     # Run website
```

## Commands

### Common Moon tasks (run from repo root)

| Command | Action |
|:---|:---|
| `moon run :get` | Install all Dart/Flutter dependencies |
| `moon run :lint` | Lint all projects (Dart: `flutter analyze`, Go: `go vet`) |
| `moon run :test` | Test all projects |
| `moon run :build` | Build all projects |

### Go API tasks

| Command | Action |
|:---|:---|
| `moon run api:get` | Download Go module dependencies |
| `moon run api:lint` | Run `go vet ./...` on the API |
| `moon run api:test` | Run `go test ./...` on the API |
| `moon run api:build` | Compile the API server binary (dry-run to `/dev/null`) |
| `moon run api:run` | Start the API server in development mode |

### Flutter package tasks

| Command | Action |
|:---|:---|
| `moon run domain:build-runner` | Codegen: freezed + json_serializable (domain) |
| `moon run data:build-runner` | Codegen: json_serializable (data) |
| `moon project <name>` | Inspect a package's task graph |

### Docker Compose

| Command | Action |
|:---|:---|
| `docker compose -f docker-compose.dev.yml up -d` | Start dev stack (API, Postgres, Redis, Mailpit) |
| `docker compose -f docker-compose.dev.yml logs -f` | Follow service logs |
| `docker compose -f docker-compose.dev.yml down` | Stop Docker dev services |
| `docker compose -f docker-compose.dev.yml down -v` | Stop + wipe dev volumes |
| `pnpm typecheck` | Typecheck website (JS/TS) |

---

## Contributing

Read [`AGENTS.md`](./AGENTS.md) for architectural principles and per-app/package rules. Open an issue before starting significant work.

## License

MIT
