# Architecture

## Tech Stack

### Backend (`apps/api`)

| Layer | Technology |
|:---|:---|
| Language | Go (idiomatic, stdlib-first, single binary) |
| Router | Chi / Fiber (lightweight) |
| Database | PostgreSQL 17 (ACID, multi-tenant scoped by `cluster_id`) |
| Cache | Redis (low-latency read aggregates for public search) |
| Email (Dev) | Mailpit |
| Observability | OpenTelemetry → Jaeger |

### Mobile & Desktop (`apps/*`)

| Layer | Technology |
|:---|:---|
| Framework | Flutter 3.x (Dart) |
| State | Riverpod v3+ — `Notifier<State>` + `NotifierProvider` only |
| Navigation | GoRouter |
| Offline | Hive / Isar (local-first writes, background sync queues) |
| Push Alerts | FCM (Android) · Web Push API (Flutter Web / PWA) |

### Public Website (`apps/website`)

| Layer | Technology |
|:---|:---|
| Framework | Astro 5.x (Islands Architecture) |
| Styling | TailwindCSS |
| Interactive Islands | React (isolated to `<SearchBox client:load />` and distance filters only) |
| Rendering | 95% static HTML / SSR — zero client-side hydration overhead |

### Shared Packages (`packages/flutter`)

| Package | Rule |
|:---|:---|
| `domain` | Pure Dart — zero Flutter SDK, zero network imports |
| `utils` | Pure Dart — zero Flutter SDK, zero internal imports |
| `ui_kit` | Widgets only — zero business logic, zero network calls |
| All packages | `Result<T>` return type — never throw raw exceptions across boundaries |

### Toolchain

| Tool | Version / Role |
|:---|:---|
| [Moon](https://moonrepo.dev) | Monorepo task runner & dependency graph |
| pnpm | Node package manager (workspace root) |
| Biome | JS/TS linting & formatting |
| Melos | Flutter package workspace management |
| Docker Compose | Local infrastructure orchestration |

## Architecture Decisions

### Why not a cloud-native stack?
Lokalaku targets communities that cannot afford AWS, GCP, or Firebase lock-in. The entire system runs on a low-cost Linux VPS with nothing more than Docker Compose.

### Why Riverpod v3+ (not Bloc/GetX)?
`Notifier<State>` + `NotifierProvider` provides compile-time safety, code generation support, and no inheritance-based boilerplate. It aligns with the offline-first, testable architecture the apps require.

### Why Astro Islands for the website?
Local store search landing pages must be fully server-rendered for SEO. Only the live search box is hydrated client-side, keeping the global bundle near zero.

### Why strict `cluster_id` scoping?
Data sovereignty is non-negotiable. A merchant in one cluster must never see data from another cluster. Isolation is enforced at the database query and API middleware layers simultaneously.

### Why Go for the API?
Single binary deployment, excellent concurrency primitives, and minimal memory footprint — ideal for cheap infrastructure.

### Why Hive/Isar for offline storage?
Both support zero-dependency local persistence on Android with fast read/write. Hive serves lightweight config/cache; Isar handles structured relational offline data with indexing.

---

## Data Sovereignty & Multi-Tenancy

All database schemas and REST API endpoints strictly validate requests using `cluster_id`. Cross-cluster data leakage is prohibited.

**Exception:** Consumer-facing store and product discovery endpoints are exempt from cluster filtering — they operate on geographic radius and may return results from multiple clusters.

## Non-Consumer Account Lifecycle

All non-consumer accounts (Merchant, Courier, Wholesaler) follow:

```
pending_approval → active → suspended
```

Requests from `pending` or `suspended` accounts are rejected with a structured error.

## Authentication Flow

- Short-lived JWT access tokens (15 minutes)
- Long-lived opaque refresh tokens (30 days)
- Refresh tokens stored server-side (Redis), rotated on every use
- Invalidated on logout or password reset
- Phone OTP verification (6-digit, 5-minute expiry, rate-limited)
