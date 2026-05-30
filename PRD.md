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
*   **Requirement (`consumer_app` & `website`):** Retail item listings are explicitly decentralized. Warga can view what is available in their immediate vicinity. Stores are prioritized and filtered based on **geographic proximity and cluster membership**, intentionally preventing artificial "price wars" between neighboring community stores.

---

## 4. FUNCTIONAL REQUIREMENTS BY MODULE

### 4.1 `/apps/api` (Core API Engine)
*   **REQ-BG-001 (Multi-Tenancy Isolation):** All database schemas and REST API endpoints must strictly validate requests using a validated `village_cluster_id`. Cross-cluster data leakage is prohibited.
*   **REQ-BG-002 (Transactional Atomicity):** The state transition of `Pool_Orders` from `open` to `locked_ready` must be treated as an atomic ACID transaction to avoid race conditions under heavy concurrent store commits.
*   **REQ-BG-003 (Cache Layer Delivery):** Expose optimized read-only data aggregates (average local commodity prices, active store directories) to a low-latency caching database (Redis) to feed the public search engine seamlessly.

### 4.2 `/mobile-apps/apps/merchant_app` (Store POS & Supply)
*   **REQ-ME-001 (Offline-First POS Checkout):** Inventory deductions and over-the-counter receipts must be write-committed to local hardware storage (Hive/Isar) immediately. Syncing with backend servers must run asynchronously via a background sync queue when network signals normalize.
*   **REQ-ME-002 (B2B Pool Participation):** Provide a real-time progress dashboard displaying active wholesale pools in their cluster, allowing the merchant to commit stock orders to the pool with a single tap.

### 4.3 `/mobile-apps/apps/courier_app` (Localized Fulfillment)
*   **REQ-CO-001 (Background GPS Telemetry):** Intermittently batch and upload coordinate parameters (`latitude`, `longitude`) when a route is actively claimed, optimizing battery life for low-end field devices.
*   **REQ-CO-002 (Batch Job Manifest):** Allow couriers to claim entire `Pool_Orders` containing multiple drop-off points within the same village cluster to maximize single-trip fuel efficiency.

### 4.4 `/mobile-apps/apps/consumer_app` (Warga App)
*   **REQ-CS-001 (Local Digital Ledger):** Give consumers an intuitive, low-friction cart and checkout interface to buy daily goods from nearby stores. Deliver live order status changes via FCM (native Android) and the Web Push API (Flutter Web / PWA). The web build must be responsive (mobile-first) and deployable as a PWA. GPS-based proximity browsing must degrade gracefully on web — prompt for permission; never hard-crash if denied or unavailable.

### 4.5 `/apps/wholesaler_app` (Wholesale Operator Dashboard)
*   **REQ-WS-001 (Product Catalogue):** Wholesalers must be able to list products with pricing and minimum order quantities, scoped exclusively to the village clusters they are approved to supply.
*   **REQ-WS-002 (Pool Order Monitoring):** Provide a real-time view of merchant commitments per pool, with a clear indicator of progress toward the minimum order threshold.
*   **REQ-WS-003 (Pool Advancement):** Wholesalers must be able to advance a pool to `locked_ready` or mark it as `fulfilled`. Cancellations require a written reason communicated to all committed merchants.

### 4.6 `/apps/backoffice_web` (Platform Superadmin Dashboard)
*   **REQ-SA-001 (Village Cluster Management):** Superadmins must be able to create, configure, and archive village clusters. Clusters define the geographic and data boundaries for all platform activity.
*   **REQ-SA-002 (Wholesaler Verification):** Wholesaler registrations must be held in a pending state until a superadmin reviews and approves them, including assigning permitted village clusters.
*   **REQ-SA-003 (Platform Health Oversight):** Provide a cross-cluster dashboard showing ecosystem-wide activity, anomalies, and account counts. Superadmins must be able to suspend or deactivate any account on the platform.

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
