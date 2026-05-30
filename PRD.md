# 📋 PRODUCT REQUIREMENT DOCUMENT (PRD): LOKALAKU ECOSYSTEM

## 1. EXECUTIVE SUMMARY & VISION
**Lokalaku** is an open-source, decentralized, hyper-local digital ecosystem built to act as an autonomous alternative to centralized village cooperatives. The core mission is to empower rural communities by connecting local wholesale hubs directly to village stores and end-consumers.

By eliminating predatory middlemen, streamlining community bulk purchasing (**Pool Buying**), and providing low-cost operational tools, Lokalaku fosters data sovereignty, price stability, and economic resilience in regions with volatile network infrastructure.

---

## 2. THE ECOSYSTEM LANDSCAPE (TARGET AUDIENCE & ROLES)

To fully grasp the scope, the system orchestrates interactions between four distinct user segments:

| Role | Segment | Primary Interface | Core Function |
| :--- | :--- | :--- | :--- |
| **Wholesaler** | B2B Bulk Supplier / Factory Hub | `wholesaler_app` | Supplies grocery items at scale with strict Minimum Order Quantities (MOQ). Monitors pool commitments and advances fulfillment. |
| **Merchant** | Local Village Warung / Retail Shop | `merchant_app` | Purchases stock via Pool Buying and acts as a localized cash register (POS) for villagers. |
| **Courier** | Independent Local Delivery Rider | `courier_app` | Transports items from Wholesale Hubs to Merchants, or from Merchants to Consumers. |
| **Consumer** | End-Retail Villagers / Warga | `consumer_app` & `website` | Browses local inventories, tracks community bulk pools, and places everyday orders. |
| **Superadmin** | Lokalaku Platform Operator | `backoffice_web` | Onboards village clusters, verifies wholesalers, manages platform-wide configuration and health. |

---

## 3. CORE PRODUCT ARCHITECTURE & VALUE PROPOSITIONS

### 3.1 The Hulu (Upstream) Engine: Pool Buying Aggregation
The cornerstone of Lokalaku’s supply chain efficiency. Small village stores (`Merchants`) cannot afford factory-direct wholesale pricing individually due to high MOQs.
*   **Requirement:** The system must aggregate separate store orders into a singular `Pool_Order` tied to a specific geographic `village_cluster_id`.
*   **Threshold Logic:** When the collective order quantity reaches or exceeds the Wholesaler's MOQ (`accumulated_qty >= target_qty`), the factory pricing unlocks, the pool status shifts to `locked_ready`, and a batch fulfillment process is triggered.
*   **Impact:** Merchants gain corporate-level purchasing power without holding massive financial risk or excess inventory.

### 3.2 The Hilir (Downstream) Engine: Proximity-Based Retail & POS
*   **Requirement (`merchant_app`):** Must feature a lightweight, lightning-fast Point-of-Sale (POS) interface optimized for quick over-the-counter cash transactions. It must maintain accurate local item indexes even when completely cut off from the backend server.
*   **Requirement (`consumer_app` & `website`):** Retail item listings are explicitly decentralized. Warga can view what is available in their immediate vicinity. Stores are discovered and sorted purely by **geographic proximity** — `village_cluster_id` is an operational boundary and must never restrict what a consumer can browse or order from. A consumer near a village border must be able to see and interact with the closest merchants regardless of which cluster those merchants belong to.

---

## 4. FUNCTIONAL REQUIREMENTS BY MODULE

### 4.1 `/apps/api` (Core API Engine)
*   **REQ-BG-001 (Multi-Tenancy Isolation):** All database schemas and REST API endpoints must strictly validate requests using a validated `village_cluster_id`. Cross-cluster data leakage is prohibited. **Exception:** Consumer-facing store and product discovery endpoints are explicitly exempt from cluster filtering — they operate on geographic radius and may return results from multiple clusters. Cluster scoping applies to merchant operations, Pool Buying aggregation, courier dispatch, wholesaler assignments, and all administrative data isolation.
*   **REQ-BG-002 (Transactional Atomicity):** The state transition of `Pool_Orders` from `open` to `locked_ready` must be treated as an atomic ACID transaction to avoid race conditions under heavy concurrent store commits.
*   **REQ-BG-003 (Cache Layer Delivery):** Expose optimized read-only data aggregates (average local commodity prices, active store directories) to a low-latency caching database (Redis) to feed the public search engine seamlessly.
*   **REQ-BG-004 (Role-Based Authentication):** The API must issue short-lived JWT access tokens (15 minutes) and long-lived opaque refresh tokens (30 days) upon successful login. Every protected endpoint must validate the JWT and enforce role boundaries — a credential issued for one role must never grant access to another role's resources. Refresh tokens must be stored server-side (Redis), rotated on every use, and immediately invalidated on logout or password reset.
*   **REQ-BG-005 (Account Lifecycle):** All non-consumer accounts (Merchant, Courier, Wholesaler) must pass through a `pending_approval` or `pending_verification` state before receiving an active session. The API must enforce this state machine: `pending → active → suspended`. Requests from `pending` or `suspended` accounts must be rejected with a structured error that clients can distinguish from generic auth failures.
*   **REQ-BG-006 (OTP Verification):** The API must support phone number verification via a 6-digit, time-limited OTP (valid 5 minutes) delivered by SMS. OTP issuance must be rate-limited to 3 requests per phone number per 10-minute window. The verification endpoint must invalidate the OTP after first use.

### 4.2 `/mobile-apps/apps/merchant_app` (Store POS & Supply)
*   **REQ-ME-001 (Offline-First POS Checkout):** Inventory deductions and over-the-counter receipts must be write-committed to local hardware storage (Hive/Isar) immediately. Syncing with backend servers must run asynchronously via a background sync queue when network signals normalize.
*   **REQ-ME-002 (B2B Pool Participation):** Provide a real-time progress dashboard displaying active wholesale pools in their cluster, allowing the merchant to commit stock orders to the pool with a single tap.
*   **REQ-ME-003 (Registration & Approval Gate):** Merchants must be able to self-register by submitting store details and a verified phone number. The account must remain in `pending_approval` state — with no active session granted — until a superadmin approves it. The app must communicate approval status clearly and poll for status changes.
*   **REQ-ME-004 (Offline PIN Auth for POS Continuity):** When a merchant's session token expires during an active POS shift, the app must present a local PIN challenge rather than interrupting the sales flow with a full login screen. The PIN must be stored locally in hashed form and never transmitted to the server. A successful PIN verification must trigger a background token refresh; if the device is offline, a time-bounded offline grace session (maximum 8 hours) must be granted so that POS transactions can continue writing to local storage until connectivity is restored.

### 4.3 `/mobile-apps/apps/courier_app` (Localized Fulfillment)
*   **REQ-CO-001 (Background GPS Telemetry):** Intermittently batch and upload coordinate parameters (`latitude`, `longitude`) when a route is actively claimed, optimizing battery life for low-end field devices.
*   **REQ-CO-002 (Batch Job Manifest):** Allow couriers to claim entire `Pool_Orders` containing multiple drop-off points within the same village cluster to maximize single-trip fuel efficiency.
*   **REQ-CO-003 (Registration & Approval Gate):** Couriers must be able to self-register by submitting personal details (KTP number) and vehicle information alongside a verified phone number. The account must remain in `pending_approval` state until approved by a superadmin. The app must not grant access to job listings until the account is active.
*   **REQ-CO-004 (Proactive Token Refresh for Telemetry Continuity):** When a courier has an active route, the auth layer must proactively refresh the access token before it expires (trigger at ≤3 minutes remaining) rather than waiting for a 401 response. If a refresh fails mid-route, GPS coordinates must be buffered locally and retransmitted with exponential backoff once connectivity is restored. No location data may be silently discarded.

### 4.4 `/mobile-apps/apps/consumer_app` (Warga App)
*   **REQ-CS-001 (Local Digital Ledger):** Give consumers an intuitive, low-friction cart and checkout interface to buy daily goods from nearby stores. Deliver live order status changes via FCM (native Android) and the Web Push API (Flutter Web / PWA). The web build must be responsive (mobile-first) and deployable as a PWA. GPS-based proximity browsing must degrade gracefully on web — prompt for permission; never hard-crash if denied or unavailable.
*   **REQ-CS-002 (Unauthenticated Discovery):** Store listings, product details, and proximity browsing must be fully accessible without an account. Authentication must only be required at the point of a transactional action (adding to cart, checking out). The app must never block discovery behind a login wall.
*   **REQ-CS-003 (Phone OTP Registration & Login):** Consumers must be able to create an account using only a phone number, verified via OTP. No password is required to register. Returning users may authenticate via OTP or, if they have set one, a password. Account activation must be immediate — no approval step.

### 4.5 `/apps/wholesaler_app` (Wholesale Operator Dashboard)
*   **REQ-WS-001 (Product Catalogue):** Wholesalers must be able to list products with pricing and minimum order quantities, scoped exclusively to the village clusters they are approved to supply.
*   **REQ-WS-002 (Pool Order Monitoring):** Provide a real-time view of merchant commitments per pool, with a clear indicator of progress toward the minimum order threshold.
*   **REQ-WS-003 (Pool Advancement):** Wholesalers must be able to advance a pool to `locked_ready` or mark it as `fulfilled`. Cancellations require a written reason communicated to all committed merchants.
*   **REQ-WS-004 (Business Registration & Verification):** Wholesalers must be able to self-register by submitting business credentials (NIB), contact details, and the village clusters they intend to supply. The account must enter `pending_verification` state until a superadmin reviews and approves it, including assigning permitted clusters. No product listing or pool monitoring features are accessible until the account is active.
*   **REQ-WS-005 (Email-Based Auth & Password Reset):** Wholesalers authenticate using email and password. The app must support a self-service password reset flow via a time-limited, single-use email link (valid 30 minutes). A successful password reset must revoke all existing sessions for that account.

### 4.6 `/apps/backoffice_web` (Platform Superadmin Dashboard)
*   **REQ-SA-001 (Village Cluster Management):** Superadmins must be able to create, configure, and archive village clusters. Clusters define the operational, administrative, and data boundaries for merchant registration, Pool Buying, courier dispatch, and wholesaler assignments. They must not be used as a discovery filter for consumer-facing features — consumer browsing and ordering are governed by geographic proximity, not cluster membership.
*   **REQ-SA-002 (Wholesaler Verification):** Wholesaler registrations must be held in a pending state until a superadmin reviews and approves them, including assigning permitted village clusters.
*   **REQ-SA-003 (Platform Health Oversight):** Provide a cross-cluster dashboard showing ecosystem-wide activity, anomalies, and account counts. Superadmins must be able to suspend or deactivate any account on the platform.
*   **REQ-SA-004 (Operator Session Security):** Superadmin accounts are provisioned manually — there is no self-registration flow. Sessions must be non-persistent: the refresh token is stored in `sessionStorage` and cleared when the browser tab is closed. The session must auto-expire after 30 minutes of UI inactivity, with a 2-minute warning shown before expiry. After 5 consecutive failed login attempts, the account must be locked for 30 minutes.

### 4.7 `/apps/website` (SEO & Acquisition Engine)
*   **REQ-PW-001 (Zero-JS Pre-rendering):** Generate structural directory landing pages for every active village cluster (`lokalaku.in/desa-sukamaju`). All initial markup must be completely server-side rendered or pre-compiled into standard semantic HTML text to allow rapid search engine indexing.
*   **REQ-PW-002 (Isolated Interactive Search):** Implement an active, decoupled Live Search component using the Astro Islands Architecture (`client:load`). The input box should poll background endpoints dynamically to fetch instant product/store availability without triggering a full page reload or bloating the global site payload.

---

## 5. NON-FUNCTIONAL REQUIREMENTS & BOUNDARIES

### 5.1 Environmental Performance
*   **Low-Signal Resiliency:** Applications must gracefully handle sudden transitions between 2G, 3G, 4G, and offline states. Outbound API timeouts must fail gracefully with meaningful user retry signals instead of crashing app runtimes.
*   **Low-End Hardware Optimization:** Mobile UIs must target 60FPS fluid animations on older Android chipsets. Keep bundle sizes small by avoiding non-essential large assets or redundant third-party package dependencies.

### 5.2 Deployment Independence
*   The entire software infrastructure must remain free of proprietary cloud dependencies. The end goal is a deployment manifest that can spin up the full infrastructure ecosystem on an unmanaged, affordable Linux VPS using basic Docker Compose definitions.

---

## 6. SYSTEM DATAFLOW MATRIX

```text
[Superadmin creates cluster] ──► backoffice_web ──► Approves Wholesaler
                                                            │
[Wholesaler logs stock]      ──► wholesaler_app ────────────┘
                                       │                    Persisted via Golang API
[Merchants join pool]        ──► merchant_app  ─────────────┤
                                                            │
                                              ▼ (MOQ reached: pool locked)
                                    [locked_ready] ──► Notify courier_app
                                                            │
[Delivery fulfilled]         ──► Merchant POS updated ──► Consumer tracks live
```
