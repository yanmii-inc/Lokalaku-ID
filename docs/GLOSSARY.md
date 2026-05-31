# 📖 Lokalaku Domain Glossary

> **For agents:** Read this when you encounter ambiguous terminology, are naming new entities,  
> or need to understand a business concept before writing code.  
> **Routing tier:** 3 (cross-cutting / architectural work).

---

## Business Domain Terms

### Village Cluster (`village_cluster_id`)
The root unit of the Lokalaku platform. Represents a geographically bounded community (a desa or set of neighbouring hamlets). All data — accounts, products, orders, and transactions — is owned by exactly one village cluster and isolated from all others. This is the fundamental data sovereignty boundary.

**Exception:** Consumer-facing store and product discovery is exempt from cluster filtering. It operates on geographic radius (GPS proximity) and may return results from multiple clusters. Cluster scoping applies only to merchant operations, Pool Buying, courier dispatch, wholesaler assignments, and all administrative data.

### Pool Order (Pool Buying / Pembelian Kolektif)
A collective buying event initiated by a Wholesaler for a specific product. Multiple Merchants pledge individual quantities toward a shared Minimum Order Quantity (MOQ) threshold. When the threshold is met, factory-direct pricing unlocks and a single consolidated wholesale order is placed. Pool Orders follow a strict one-way state machine — see **Pool Status** below.

### Pool Commitment (Komitmen Pool)
One Merchant's individual pledge within an open Pool Order. Records the merchant's intended quantity and the timestamp of their commitment. A commitment cannot be unilaterally withdrawn once the pool reaches `locked_ready`.

### Pool Status (State Machine)
The lifecycle states of a Pool Order. Transitions are **one-way and atomic** (ACID transaction):

```
open ──► locked_ready ──► fulfilled
  └──────────────────────► cancelled
```

| State | Meaning |
|:---|:---|
| `open` | Accepting merchant commitments. MOQ not yet reached. |
| `locked_ready` | MOQ reached. Factory pricing unlocked. Awaiting courier assignment. |
| `fulfilled` | Delivery completed. Merchant POS stocks updated. |
| `cancelled` | Pool cancelled by Wholesaler. Written reason required. All committed merchants notified. |

### Hulu (Upstream Engine)
The supply chain layer from Factory/Wholesaler → Merchant. Governs Pool Buying, MOQ unlocking, and batch fulfillment. Managed via `wholesaler_app` and `merchant_app`.

### Hilir (Downstream Engine)
The supply chain layer from Merchant → Consumer. Governs retail proximity browsing, POS transactions, and last-mile delivery. Managed via `merchant_app`, `consumer_app`, `courier_app`, and `website`.

### MOQ (Minimum Order Quantity)
The minimum aggregate quantity a Wholesaler requires before factory pricing activates. Set per product by the Wholesaler. A Pool Order's progress is `accumulated_qty / moq`.

### Account Status
The lifecycle states of any non-consumer account:

| State | Meaning |
|:---|:---|
| `pending_approval` | Self-registered. Awaiting Superadmin review. No feature access. |
| `active` | Approved. Full role-based access granted. |
| `suspended` | Blocked by Superadmin. All sessions revoked. |

Consumer accounts skip `pending_approval` — they become `active` immediately after OTP verification.

### OTP (One-Time Password)
A 6-digit, time-limited (5-minute) numeric code sent via SMS to verify a phone number. Rate-limited to 3 requests per phone number per 10-minute window. Invalidated after first successful use.

### Offline Grace Session
A time-bounded (max 8 hours) continuation of a Merchant's POS session when their network token expires and the device is offline. The POS continues writing to Hive/Isar local storage. Syncs to backend when connectivity returns. Gated behind a locally-stored hashed PIN — never transmitted over the network.

### Background Sync Queue
An asynchronous queue (in `merchant_app` and `courier_app`) that holds uncommitted writes — POS transactions, GPS coordinates — while the device is offline. Drains automatically when a network signal becomes available.

### Audit Event
An immutable, append-only log record created by the API on every significant state change. Captures: who (`account_id`), what entity was affected, which `village_cluster_id`, what changed, and when. Never deletable or editable by application code.

---

## Roles

| Role Key | Bahasa Label | Primary App |
|:---|:---|:---|
| `consumer` | Warga (Villager) | `consumer_app`, `website` |
| `merchant` | Pemilik Warung (Store Owner) | `merchant_app` |
| `courier` | Kurir | `courier_app` |
| `wholesaler` | Grosir / Pedagang Grosir | `wholesaler_app` |
| `superadmin` | Operator Lokalaku | `backoffice_web` |

---

## Technical Terms

### Result\<T\>
The functional error-handling wrapper used across all Dart package boundaries. Repository methods never throw raw exceptions — they return `Result<T>` (either a success value or a typed failure). Defined in `lokalaku_domain`. All apps and packages must use this; never propagate raw `Exception` or `Error` across package boundaries.

### Design Tokens
Named constants in `lokalaku_ui_kit` that represent all visual values: colours (`AppColors`), typography (`AppTypography`), and spacing (`AppSpacing`). Raw Flutter primitives (`Colors.*`, hardcoded hex values, raw `TextStyle(...)`) are prohibited in all Flutter code.

### PWA (Progressive Web App)
The web deployment target for `consumer_app`. Supports Web Push notifications, offline caching via service worker, and mobile-first responsive layout. GPS proximity browsing must degrade gracefully — prompt for permission before use, never hard-crash if permission is denied or GPS is unavailable.

### Islands Architecture
Astro's rendering pattern used in `apps/website`. 95%+ of pages are compiled to static HTML with zero client-side JavaScript. React components are only mounted as isolated "islands" for features that require interactivity — specifically the Live Search Box (`<SearchBox client:load />`).

---

## Naming Conventions

| Item | Convention | Example |
|:---|:---|:---|
| Dart packages | `lokalaku_<name>` | `lokalaku_domain` |
| Dart files | `snake_case.dart` | `pool_order_repository.dart` |
| Dart classes | `PascalCase` | `PoolOrder`, `MerchantScreen` |
| Screen widgets | `*Screen` / `*_screen.dart` | `PoolDashboardScreen` |
| Notifiers | `*Controller` / `*_controller.dart` | `AuthController` |
| Domain entities | No suffix | `PoolOrder`, `Merchant`, `Account` |
| Go packages | `lowercase` | `poolorder`, `auth` |
| Go files | `snake_case.go` | `pool_order_handler.go` |
| ADR files | `NNN-<kebab-title>.md` | `003-jwt-refresh-token.md` |
| Milestone files | `MXXX-<kebab-title>.md` | `M001-foundation-auth.md` |
| Task files | `TASK-<DOMAIN>-NNN-<kebab-title>.md` | `TASK-API-001-project-scaffold.md` |
