# ADR-002: Hive + Isar for Offline-First Local Storage (Merchant & Courier Apps)

**Status:** `Accepted`  
**Date:** 2025-01-01  
**Decider(s):** Project Lead  
**Context Area:** `apps/merchant_app`, `apps/courier_app`

---

## Context

`REQ-ME-001` mandates that `merchant_app` POS transactions are committed to local storage immediately and synced to the backend asynchronously. `REQ-ME-004` requires a local offline grace session (up to 8 hours) when the device loses connectivity mid-shift. `REQ-CO-004` requires that courier GPS coordinates are buffered locally if a token refresh fails mid-route.

Both apps must:
- Write to persistent local storage **without a network connection**.
- Survive process restarts (app killed mid-shift, device rebooted) without data loss.
- Run efficiently on low-end Android hardware (512 MB RAM, slow eMMC storage).
- Support a **background sync queue** that drains automatically when connectivity returns.

A pure in-memory state solution (e.g., a `Notifier` holding a `List`) is unacceptable — data loss on process kill is guaranteed.

---

## Decision

Use **Hive** for simple key-value and sequential-write persistence (sync queue entries, offline session PIN hash, cached catalogue data snapshots, GPS coordinate buffers).

Use **Isar** for the merchant's local product inventory and transaction log, where structured query capabilities are needed (filter by category, sort by stock level, fast ID lookups during POS checkout).

Both databases are stored in app-specific, sandboxed local directories. No data is shared across apps. The sync queue pattern is: write to local DB → confirm to UI → drain to backend when online → delete local entry on 2xx.

---

## Rationale

- **Hive:** Zero native dependencies, pure Dart, extremely fast for sequential appends (sync queue). Low memory overhead on low-end hardware. Ideal for the courier GPS coordinate buffer and the merchant sync queue.
- **Isar:** Native-speed NoSQL with a full typed query API and Flutter-friendly code generation (`build_runner`). Handles the merchant's offline product catalogue (which needs search, sort, and filtering during live POS sessions).
- **Both are proven in production:** Widely deployed in Flutter apps on low-end Android. Memory footprint is minimal. No proprietary cloud dependency (aligns with zero-vendor-lock-in principle).
- **Alignment with offline-first mandate:** Writes from the UI layer are synchronous — no async gap between a POS button tap and local persistence. The network sync happens completely independently.

---

## Consequences

### Positive
- POS transactions survive network outages, app crashes, and device reboots.
- Merchant can operate fully offline for up to 8 hours (Offline Grace Session).
- Sync queue implementation is simple: read entries from Hive → POST to API → delete on 2xx → retry with exponential backoff on failure.
- Courier GPS buffer drains silently in the background with no user interruption.

### Negative / Tradeoffs
- Two local database libraries increase the package surface compared to a single solution.
- Isar requires native compilation — `flutter pub get` must complete and a build step must run before first use.
- Local data is device-bound. If a merchant switches devices mid-shift, un-synced offline records are on the old device. Mitigation: aggressive sync trigger on every app resume + 8-hour maximum grace window.
- Isar schema migrations must be planned whenever `domain` entities change (handled via `moon run data:build-runner`).

### Neutral
- The sync queue pattern is implemented in `apps/merchant_app` and `apps/courier_app` respectively — not in shared packages, because the queue payloads and retry logic differ per app.

---

## Alternatives Considered

| Option | Why Rejected |
|:---|:---|
| **SQLite (`sqflite`)** | Manual SQL schema management. No type-safe query API. Higher cognitive overhead than Isar for a write-heavy, offline-first Flutter app. |
| **Drift (formerly Moor)** | Good SQL abstraction, but heavier than needed. Isar is faster for the write-heavy POS workload. Drift's SQL migration DSL adds complexity without commensurate benefit here. |
| **SharedPreferences** | Not designed for structured data. No transaction support. Categorically unacceptable for financial POS records. |
| **Pure in-memory state** | Data lost on process kill. Fails `REQ-ME-001` outright. |
| **Realm (MongoDB Atlas Device Sync)** | Proprietary (MongoDB). Conflicts with zero-vendor-lock-in principle. Atlas Sync would introduce a cloud dependency. |
| **ObjectBox** | Comparable to Isar, but Isar has a larger Flutter-specific community and tighter build_runner integration at the time of this decision. |

---

## Related

- **PRD Requirement(s):** `REQ-ME-001`, `REQ-ME-004`, `REQ-CO-004`
- **Design Doc:** _(offline sync queue design doc — to be created as `docs/design/02-offline-sync-queue.md`)_
- **Glossary:** [Offline Grace Session](../GLOSSARY.md), [Background Sync Queue](../GLOSSARY.md)
- **Milestone:** [M001 — Foundation & Auth System](../milestones/M001-foundation-auth-system.md) _(decision recorded)_, [M003 — Merchant POS Offline](../milestones/CHANGELOG.md) _(implemented)_
- **Supersedes:** _none_
- **Superseded by:** _none_
