# 📋 PRD: wholesaler_app — Wholesale Operator App

> **Scope:** This document covers only the `wholesaler_app` sub-project.
> For ecosystem-wide context, refer to the root [`/PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

| Attribute | Detail |
| :--- | :--- |
| **Target Users** | Wholesale Operators — factory hubs, distributors, and bulk suppliers serving village clusters |
| **Primary Platforms** | Desktop app (macOS, Linux, Windows) — primary · Web browser — secondary |
| **Core Function** | List products with minimum order quantities, monitor merchant pool commitments, and advance pool orders through to fulfillment |

Wholesalers are the **hulu (upstream)** anchor of the Lokalaku supply chain. They set the terms — price tiers and minimum order quantities — that make community bulk purchasing possible. This dashboard is their primary control surface.

---

## 2. User Stories

| ID | As a… | I want to… | So that… |
| :--- | :--- | :--- | :--- |
| US-WS-01 | Wholesaler | List my products with a price and minimum order quantity | Merchants in my village clusters can see and join my bulk offers |
| US-WS-02 | Wholesaler | See how many units merchants have collectively committed to for each product | I know when a pool is close to unlocking |
| US-WS-03 | Wholesaler | Be notified when a pool reaches its minimum order quantity | I can act on it immediately without manually checking |
| US-WS-04 | Wholesaler | Mark a pool order as ready for delivery or as fulfilled | The couriers and merchants are informed and the supply chain moves forward |
| US-WS-05 | Wholesaler | View a history of all past pool orders and their outcomes | I can track sales performance and plan future stock |
| US-WS-06 | Wholesaler | Manage which village clusters I supply to | I only appear in the relevant local markets |
| US-WS-07 | Wholesaler | Update or deactivate a product listing | My catalogue stays accurate and relevant |

---

## 3. Functional Requirements

### REQ-WS-001 — Product Catalogue Management
*   Wholesalers can create, edit, and deactivate product listings.
*   Each listing must include: product name, description, unit of measurement, price per unit, and minimum order quantity to unlock that price.
*   A product can be assigned to one or more village clusters the wholesaler supplies. It is not visible outside those clusters.
*   Deactivated products are hidden from merchants but their historical pool order records are preserved.

### REQ-WS-002 — Pool Order Monitoring
*   For each active product listing, display a live summary of the open pool: how many units have been committed by merchants, the target minimum quantity, and a progress indicator.
*   When a pool reaches its minimum order quantity, it is visually highlighted and the wholesaler receives a notification.
*   The wholesaler can view the full list of committing merchants and their individual quantities for each pool.

### REQ-WS-003 — Pool Order Advancement
*   The wholesaler can manually mark a pool as ready for delivery once the minimum is met. This triggers courier notifications.
*   The wholesaler can mark a pool as fulfilled once goods have been dispatched.
*   A pool may be cancelled with a mandatory written reason, which is communicated to all committed merchants.
*   All status changes are permanently recorded and cannot be altered after the fact.

### REQ-WS-004 — Sales History & Reporting
*   Wholesalers can view a chronological history of all pool orders — completed, cancelled, and in progress.
*   Each record shows the product, total quantity fulfilled, number of merchants involved, and the date range.
*   Summary metrics are shown at the top: total pools fulfilled this month, total units moved, and top-performing products.

### REQ-WS-005 — Cluster Assignment
*   Wholesalers can see which village clusters they are approved to supply.
*   Requesting access to additional clusters requires approval from a platform superadmin.
*   Products cannot be listed in a cluster the wholesaler is not approved for.

### REQ-WS-006 — Desktop & Web Layout
*   The primary experience is a native desktop application with a sidebar for navigation and a main content area.
*   The web build must replicate the same layout and functionality as the desktop app. Features that are only possible on desktop (such as local file access for bulk product import) must be hidden or replaced with a browser-compatible alternative on the web build.
*   Both builds must be fully usable at viewport widths of 1024 px and above.

---

## 4. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Access Control** | Each wholesaler account only sees their own products and pools. No cross-wholesaler data is ever visible. |
| **Auditability** | All changes to product listings and pool order statuses are permanently logged with the actor's identity and timestamp. |
| **Notifications** | Pool threshold alerts must reach the wholesaler promptly — delays undermine the time-sensitive nature of fulfillment coordination. |
| **Reliability** | Pool order status changes must be applied consistently. Two simultaneous actions on the same pool must not produce conflicting states. |

---

## 5. Data Flows

*   Wholesaler logs into the platform with their verified wholesaler account.
*   Product listings created here become visible to merchants in the assigned village clusters via the `merchant_app`.
*   Merchant pool commitments (made in `merchant_app`) are aggregated and reflected in real time on this dashboard.
*   When the wholesaler advances a pool to "ready for delivery", the `courier_app` receives a notification of a new delivery job.
*   Fulfillment updates flow back to the `merchant_app` and `consumer_app` so all parties have current order status.
*   The platform superadmin (`backoffice_web`) controls which clusters this wholesaler is approved to supply.

---

## 6. Out of Scope

*   Over-the-counter consumer sales → `merchant_app`
*   Delivery routing and GPS tracking → `courier_app`
*   Consumer browsing and ordering → `consumer_app`
*   Village cluster creation and wholesaler approval → `backoffice_web`
*   Public SEO storefront → `website`
