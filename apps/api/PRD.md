# 📋 PRD: Platform Engine — Core Business Logic & Data Layer

> **Scope:** This document covers only the `api` sub-project.
> For ecosystem-wide context, refer to the root [`../../PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

The Platform Engine is the central authority for all business rules in the Lokalaku ecosystem. It is not a user-facing product; it is the service that every app depends on to read and write data correctly and safely.

| Served By | Core Function |
| :--- | :--- |
| **Consumer App** | Enables consumers to browse stores and products, place orders, track delivery status, and receive real-time order alerts on their device |
| **Merchant App** | Enables merchants to manage their product inventory, record point-of-sale transactions, join collective pool orders, and receive status updates |
| **Courier App** | Enables couriers to receive assigned delivery routes, report their location, and update stop completion status |
| **Backoffice Web** | Enables village admins and wholesale operators to oversee accounts, configure products, manage pool orders, and view operational summaries |
| **Public Web** | Provides read-only store and product listings used to build the public discovery site; the public web never writes data through the Platform Engine |

---

## 2. Business Rules & Guarantees

### REQ-BG-001 — Village Data Isolation

Data belonging to one village cluster is **never visible to or mixed with** data from another. Every request made to the Platform Engine is validated against the village associated with the authenticated user's session. Any attempt to access another village's records is rejected outright. This guarantee is the foundation of data sovereignty across the Lokalaku network.

### REQ-BG-002 — Reliable Pool Order Processing

When merchants collectively reach the minimum order quantity for a pool, the system guarantees the pool transitions to its next state **correctly — with no double-counting and no lost commitments** — even when many merchants submit at the same moment. The pool follows a one-way state path:

```
Open ──► Ready to Fulfil ──► Fulfilled
  └──────────────────────► Cancelled
```

Any action that would skip or reverse a step in this path is rejected. This ensures wholesale suppliers always receive accurate, consolidated demand figures.

### REQ-BG-003 — Fast Data Delivery

Frequently read information — store directories, product prices, and pool order summaries — is served from a **high-speed data layer** so that apps and the public web feel responsive even under heavy usage. The permanent data store remains the single source of truth; the high-speed layer is refreshed automatically whenever the underlying records change. If the high-speed layer is unavailable, requests fall back to the permanent store transparently.

### REQ-BG-004 — Real-Time Notifications

Immediately after a relevant event occurs (a pool order reaching its threshold, an order being dispatched, a delivery being completed), the Platform Engine dispatches an alert to the right users on the right device type. App users on Android receive native push alerts; users on a browser receive web push alerts. Notification delivery is handled separately from the business action itself — a failed notification never rolls back a completed order.

### REQ-BG-005 — Role-Based Access

Every authenticated session carries a defined role: `consumer`, `merchant`, `courier`, `village admin`, or `wholesale operator`. The Platform Engine checks this role before processing any action. A merchant cannot access admin functions; a courier cannot modify product listings; a consumer cannot commit a pool order on behalf of a merchant. These boundaries are enforced at the platform level, not left to individual apps.

### REQ-BG-006 — Immutable Audit Trail

Every change to orders, products, and accounts produces a permanent record capturing: who made the change, which village it belongs to, what was changed, and when. These records are **append-only** — application code can never edit or delete them. This trail exists for accountability, dispute resolution, and operational review.

---

## 3. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Performance** | Frequently accessed data (served from the high-speed layer) must respond near-instantly. All other responses must complete quickly enough that apps feel smooth — even on busy market days or during a pool order deadline rush. |
| **Reliability under Load** | The pool order commitment flow must remain correct and consistent when many merchants submit simultaneously. No data loss or inconsistency is acceptable under peak concurrency. |
| **Deployment Independence** | The entire Platform Engine must run on any standard Linux server or container with minimal configuration. It must not depend on any proprietary cloud service, managed database, or vendor-specific infrastructure. The goal is that any village cooperative can self-host it on affordable hardware. |
| **Operational Visibility** | The platform must emit structured, machine-readable operational logs — including timestamps, which village cluster was involved, and how long each operation took — so that issues can be diagnosed quickly. A health indicator must be available to confirm the service is running. |
| **Lean Footprint** | The service must run within the memory constraints of low-cost server hardware. It is designed for efficiency, not for high-end cloud infrastructure. |

---

## 4. Key Data Entities

| Entity | Plain-Language Description |
| :--- | :--- |
| **Village Cluster** | The root unit of the platform. Represents a geographically bounded community. All data — accounts, products, orders — belongs to exactly one village cluster and cannot cross into another. |
| **Account** | A registered user with a single role. The role determines what the account holder can see and do across the entire platform. |
| **Product** | An item offered by a wholesale supplier to merchants within a village cluster. Includes the current price and the minimum order quantity required to unlock group pricing. |
| **Pool Order** | A collective buying event. Multiple merchants pledge individual quantities toward a shared threshold. Once the threshold is reached, the pool moves forward as a single consolidated wholesale order. |
| **Pool Commitment** | One merchant's individual pledge within a pool order, recording how much they intend to buy and when they committed. |
| **Transaction** | A completed point-of-sale sale recorded by a merchant. The platform guarantees each transaction is recorded exactly once, even if submitted again due to a network retry. |
| **Audit Event** | A permanent, uneditable record of a significant change: what entity was affected, who made the change, which village it belongs to, and the exact time it occurred. |

---

## 5. Information Flows

The following describes what data moves between each part of the ecosystem and why.

**Consumer App → Platform Engine**
Consumers send login credentials and receive a secure session. They request store and product listings for their village. They submit orders and query order status. They receive real-time push alerts when their order status changes.

**Merchant App → Platform Engine**
Merchants send login credentials and receive a secure session scoped to their role. They push inventory updates and synchronise point-of-sale records. They view available pool orders and submit their quantity commitments. They receive alerts when a pool they joined reaches its threshold or changes status.

**Courier App → Platform Engine**
Couriers receive their assigned delivery route and stop list. They push location updates and mark stops as completed. They receive alerts for new route assignments.

**Backoffice Web → Platform Engine**
Village admins and wholesale operators manage accounts, products, and pool orders. They view aggregated dashboards covering village activity and order pipelines. All writes are validated against their role before taking effect.

**Public Web → Platform Engine**
At the time village pages are built, the public web fetches store listings and product data for each active village cluster. This fetch happens entirely server-side — no visitor credentials or private data are involved. The public web is strictly read-only and never modifies anything in the Platform Engine.

---

## 6. Out of Scope

*   Frontend rendering and user interface — handled by Flutter apps and the Public Web
*   SMS or WhatsApp notifications — future roadmap item
*   Payment gateway integration — future roadmap item
