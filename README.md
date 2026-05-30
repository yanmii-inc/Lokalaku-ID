<div align="center">

# 🏘️ Lokalaku

**Hyper-local. Community-owned. Zero middlemen.**

An open-source, decentralized digital ecosystem that empowers rural communities by connecting wholesale hubs directly to village stores and end-consumers — eliminating predatory supply chains and restoring economic sovereignty to the people who need it most.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](#)
[![Moon](https://img.shields.io/badge/Moon-2.2.4-blueviolet)](https://moonrepo.dev)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go&logoColor=white)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](#)
[![Astro](https://img.shields.io/badge/Astro-5.x-FF5D01?logo=astro&logoColor=white)](#)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-336791?logo=postgresql&logoColor=white)](#)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](#)

</div>

---

## 🤔 Why We Built This

Village stores across rural Indonesia are stuck in a broken supply chain. A small warung that wants to restock cooking oil or rice has no direct access to factory pricing — they're forced to buy from layers of distributors, each adding their own margin. By the time goods reach the shelf, prices are inflated and margins for the store owner are razor-thin.

On the demand side, villagers have no visibility into what's available nearby or at what price. Without a shared platform, every store is isolated — unable to coordinate purchasing power with neighbors who need the same goods.

Additionally, existing digital commerce solutions aren't built for this context:
- 📶 Connectivity is unreliable — 2G/3G in the field is still the norm
- 📱 Devices are low-end — heavy apps simply don't run well
- ☁️ Cloud-first platforms are expensive and create vendor dependency that communities can't sustain

**Lokalaku exists to fix this.** By pooling demand across village stores, we unlock factory-direct wholesale pricing that no single warung could access alone. By connecting consumers to their nearest stores through a shared platform, we create a local digital economy that is transparent, fair, and entirely owned by the community it serves — running on infrastructure they can afford and control.

---

## 🌾 What Is Lokalaku?

Lokalaku is a **polyglot monorepo** with a single mission: give rural communities full control over their own local economy. It orchestrates an entire local supply chain — from factory-direct wholesale sourcing all the way to villagers buying rice at their neighborhood warung — through five purpose-built apps sharing a single, high-performance API core.

### Core Pillars

| Pillar | What It Means |
|:---|:---|
| 🔗 **Pool Buying (Hulu Engine)** | Merchants aggregate small orders into a single collective pool. When the wholesaler's minimum order quantity (MOQ) is reached, factory-direct pricing unlocks for everyone. |
| 🛒 **Proximity Retail (Hilir Engine)** | Consumers discover what's available near them, filtered by geographic cluster — no artificial price wars between neighboring stores. |
| 📴 **Offline-First Operations** | Merchant POS and courier apps commit to local storage first, syncing to the backend the moment connectivity returns. |
| 🏛️ **Data Sovereignty** | All data is strictly scoped to a `village_cluster_id`. One village's records can never bleed into another's. |
| 🚫 **Zero Vendor Lock-In** | Runs on any cheap Linux VPS with Docker Compose. No proprietary cloud APIs, no managed lock-in. |

---

## 🗺️ Ecosystem Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Lokalaku Ecosystem                              │
│                                                                      │
│  👤 Consumer          📱 consumer_app  ─────────────────────┐        │
│  🏪 Merchant          📱 merchant_app  ──────────────────────┤        │
│  🛵 Courier           📱 courier_app   ──────────────────────┤        │
│  🏭 Wholesaler        🖥  wholesaler_app ─────────────────────┤        │
│  🛡️  Superadmin        🌐 backoffice_web ─────────────────────┤        │
│  🌍 Public            🚀 website ──(SSR fetch)───────────────┤        │
│                                                              ▼        │
│                             ┌──────────────────────────────┐         │
│                             │       🐹 Golang API           │         │
│                             │  PostgreSQL · Redis · Jaeger  │         │
│                             └──────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 👥 User Roles

| Role | App | Core Responsibility |
|:---|:---|:---|
| **Consumer** (Warga) | `consumer_app` + `website` | Browse nearby stores, join pool previews, place everyday orders, track delivery live |
| **Merchant** (Warung) | `merchant_app` | Offline-capable POS for counter sales; commit to wholesale pool orders |
| **Courier** | `courier_app` | Claim pool-order batch deliveries; stream GPS telemetry; mark stops complete |
| **Wholesaler** | `wholesaler_app` | Manage product catalogue & MOQs; monitor pool commitments; advance fulfillment status |
| **Superadmin** | `backoffice_web` | Create village clusters; verify wholesalers; platform-wide health monitoring |

---

## 🗂️ Repository Structure

```
lokalaku-id/
│
├── apps/
│   ├── api/              🐹  Golang — High-performance REST API core
│   ├── website/          🚀  Astro — SEO-optimized public catalog (Islands Architecture)
│   ├── consumer_app/     📱  Flutter — Android APK + Web PWA for villagers
│   ├── merchant_app/     📱  Flutter — Android phone & tablet POS
│   ├── courier_app/      📱  Flutter — Android phone, portrait-optimized
│   ├── wholesaler_app/   🖥️   Flutter — Desktop + Web for wholesale operators
│   └── backoffice_web/   🌐  Flutter Web — Superadmin platform dashboard
│
├── packages/
│   └── flutter/          📦  Shared Dart/Flutter packages (Melos workspace)
│       ├── domain/           Pure Dart entities & repository interfaces
│       ├── data/             Repository implementations (Dio, Hive, Isar)
│       ├── core_network/     HTTP client, interceptors & error handling
│       ├── core_auth/        Auth, session & JWT token lifecycle
│       ├── ui_kit/           Design system & shared widgets
│       └── utils/            Formatters, validators, extensions
│
├── docker/               🐳  Service stack definitions
├── compose.yaml          🐳  Docker Compose entrypoint
├── package.json          📦  pnpm workspace root
└── .prototools           🔧  Toolchain version pins (Moon 2.2.4)
```

---

## 🛠️ Tech Stack

### Backend · `/apps/api`
| Layer | Technology |
|:---|:---|
| Language | Go (idiomatic, stdlib-first, single binary) |
| Router | Chi / Fiber (lightweight) |
| Database | PostgreSQL 17 (ACID, multi-tenant scoped by `village_cluster_id`) |
| Cache | Redis (low-latency read aggregates for public search) |
| Email (Dev) | Mailpit |
| Observability | OpenTelemetry → Jaeger |

### Mobile & Desktop · `/apps/*`
| Layer | Technology |
|:---|:---|
| Framework | Flutter 3.x (Dart) |
| State | Riverpod v3+ — `Notifier<State>` + `NotifierProvider` only |
| Navigation | GoRouter |
| Offline | Hive / Isar (local-first writes, background sync queues) |
| Push Alerts | FCM (Android) · Web Push API (Flutter Web / PWA) |

### Public Website · `/apps/website`
| Layer | Technology |
|:---|:---|
| Framework | Astro 5.x (Islands Architecture) |
| Styling | TailwindCSS |
| Interactive Islands | React (isolated to `<SearchBox client:load />` and distance filters only) |
| Rendering | 95% static HTML / SSR — zero client-side hydration overhead |

### Shared Packages · `/packages/flutter`
| Package | Rule |
|:---|:---|
| `domain` | Pure Dart — zero Flutter SDK, zero network imports |
| `utils` | Pure Dart — zero Flutter SDK, zero internal imports |
| `ui_kit` | Widgets only — zero business logic, zero network calls |
| All packages | Return `Result<T>` — never throw raw exceptions across boundaries |

### Toolchain
| Tool | Version / Role |
|:---|:---|
| [Moon](https://moonrepo.dev) | Monorepo task runner & dependency graph |
| pnpm | Node package manager (workspace root) |
| Biome | JS/TS linting & formatting |
| Melos | Flutter package workspace management |
| Docker Compose | Local infrastructure orchestration |

---

## 🔄 Pool Buying: How It Works

```
  Merchants individually commit stock quantities to an open Pool Order
                              │
                    ┌─────────▼─────────┐
                    │     Pool: OPEN     │  ← any merchant can commit
                    └─────────┬─────────┘
                              │  accumulated_qty >= wholesaler MOQ
                    ┌─────────▼─────────┐
                    │  Pool: LOCKED /   │  ← factory pricing unlocks
                    │  READY TO FULFIL  │     courier job created
                    └─────────┬─────────┘
                              │  courier delivers batch
                    ┌─────────▼─────────┐
                    │  Pool: FULFILLED  │  ← merchant POS stock updated
                    └───────────────────┘
                    (or CANCELLED with written reason to all merchants)
```

State transitions are **atomic ACID transactions** — no race conditions, no double-counting, even under simultaneous peak commits.

---

## 🚀 Getting Started

### Prerequisites

- [Moon](https://moonrepo.dev/docs/install) `2.2.4+`
- [pnpm](https://pnpm.io/installation) `10.30.0+`
- [Docker](https://docs.docker.com/get-docker/) with Compose plugin
- [Go](https://go.dev/dl/) `1.22+`
- [Flutter](https://docs.flutter.dev/get-started/install) `3.x`

### 1. Clone & Install

```bash
git clone https://github.com/your-org/lokalaku-id.git
cd lokalaku-id

# Install Node tooling dependencies
pnpm install

# Bootstrap Moon and all Dart/Flutter packages
moon run :get
```

### 2. Start Infrastructure

```bash
# Start PostgreSQL, Mailpit, and Jaeger (observability)
pnpm compose:up

# Optional: enable Redis, MinIO, or ClickHouse
# Uncomment the relevant lines in compose.yaml first
```

| Service | URL / Port |
|:---|:---|
| PostgreSQL | `localhost:5432` |
| Mailpit (UI) | `http://localhost:8025` |
| Jaeger (Tracing) | `http://localhost:16686` |
| Redis *(optional)* | `localhost:6379` |
| MinIO *(optional)* | `http://localhost:9101` |

### 3. Run the API

```bash
cd apps/api
go run ./cmd/server
```

### 4. Run a Flutter App

```bash
# Example: run the merchant app on a connected Android device
cd apps/merchant_app
flutter run
```

### 5. Run the Website

```bash
cd apps/website
pnpm dev
```

---

## 🧰 Monorepo Commands

All commands below are run from the **repository root**.

```bash
# Install all Dart/Flutter dependencies
moon run :get

# Lint everything
moon run :lint

# Run all tests
moon run :test

# Typecheck JS/TS (website)
pnpm typecheck

# Run code generation (domain & data layers)
moon run domain:build-runner
moon run data:build-runner

# Inspect a package's task graph
moon project <name>       # e.g. moon project domain

# Docker helpers
pnpm compose:up           # start services
pnpm compose:down         # stop services
pnpm compose:cleanup      # stop + wipe volumes

# Cleanup workspace
pnpm cleanup              # remove all deps, caches, and build artefacts
```

---

## 🏗️ Architecture Decisions

### Why not a cloud-native stack?
Lokalaku targets village cooperatives that cannot afford AWS, GCP, or Firebase lock-in. The entire system must run on a ₹500/month (or equivalent) Linux VPS with nothing more than Docker Compose.

### Why Riverpod v3+ (not Bloc/GetX)?
`Notifier<State>` + `NotifierProvider` provides compile-time safety, code generation support, and no inheritance-based boilerplate. It aligns with the offline-first, testable architecture the apps require.

### Why Astro Islands for the website?
Village search landing pages must be fully server-rendered for SEO (Google needs to index `lokalaku.in/desa-sukamaju` with zero JS). Only the live search box is hydrated client-side, keeping the global bundle near zero.

### Why strict `village_cluster_id` scoping?
Data sovereignty is non-negotiable. A merchant in Desa Sukamaju must never see, affect, or be affected by data from Desa Ciwidey. Isolation is enforced at the database query and API middleware layers simultaneously.

---

## 🤝 Contributing

Lokalaku is community-driven. Before contributing to any sub-project, please read:

- **Root:** [`AGENTS.md`](./AGENTS.md) — global architectural principles and monorepo rules
- **Root:** [`PRD.md`](./PRD.md) — full product requirements and business context
- **API:** [`apps/api/PRD.md`](./apps/api/PRD.md) — backend business rules and data contracts
- **Flutter Packages:** [`packages/flutter/AGENTS.md`](./packages/flutter/AGENTS.md) — strict package dependency rules
- **Per-App:** each `apps/*/AGENTS.md` — app-specific guidelines

> Please open an issue before starting significant work to align on direction.

---

## 📜 License

Lokalaku is open-source software released under the [MIT License](LICENSE).

---

<div align="center">

Built with ❤️ for rural communities across Indonesia.

*Lokalaku — Lokal, Berdaya, Mandiri.*

</div>
