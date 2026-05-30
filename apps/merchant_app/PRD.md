# 📋 PRD: Merchant App — Store POS & Wholesale Supply App

> **Scope:** This document covers only the `merchant_app` sub-project.
> For ecosystem-wide context, refer to the root [`/PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

| Attribute | Detail |
| :--- | :--- |
| **Target Users** | Local Village Merchants (Warung/Retail) · Wholesalers (secondary entry point) |
| **Platforms** | Android tablet (primary) · Android phone |
| **Core Function** | Over-the-counter point-of-sale for consumer sales, plus community bulk-buying participation for restocking at wholesale prices |

---

## 2. User Stories

| ID | As a… | I want to… | So that… |
| :--- | :--- | :--- | :--- |
| US-ME-01 | Merchant | Tap items quickly to build a consumer sale receipt | I can serve customers fast at the counter |
| US-ME-02 | Merchant | Complete a checkout transaction while offline | The store doesn't stop running when internet drops |
| US-ME-03 | Merchant | See a live progress bar for active Pool Buying in my cluster | I know how close the group order is to unlocking wholesale pricing |
| US-ME-04 | Merchant | Commit my stock order to a Pool with a single tap | I don't waste time on complex ordering flows |
| US-ME-05 | Merchant | Have my local inventory automatically update on the platform when connectivity resumes | I always have an accurate record without any manual effort |

---

## 3. Functional Requirements

### REQ-ME-001 — Offline-First POS
- Every sale, inventory deduction, and receipt is recorded on the device immediately — no internet connection is required to complete a transaction.
- When the device comes back online, all transactions recorded during the offline period are automatically sent to the platform in the background. No action is needed from the merchant.
- No transaction data is ever lost during connectivity outages.
- The POS remains fully usable at all times: item search, receipt generation, and cash calculation all work without internet.

### REQ-ME-002 — Pool Buying Dashboard
- The merchant can see all active community bulk-buying rounds (Pools) open in their village cluster, including:
  - The item name and the total quantity committed so far versus the minimum needed to unlock wholesale pricing.
  - A visual progress bar showing how close the group is to the target.
  - The current status of each Pool: collecting orders, ready to fulfil, or completed.
- The merchant can enter the quantity they want and join a Pool with a single confirmation tap.
- When a Pool reaches its minimum and is ready to fulfil, the merchant receives a real-time notification on their device.

### REQ-ME-003 — Tablet & Phone Layout
- On a tablet, the POS screen shows a split view: the product catalogue on one side and the current receipt on the other, so merchants can build receipts without switching screens.
- Product tiles are large enough to tap quickly and accurately, even at a busy counter.
- On a phone, the layout follows a simple single-pane flow: browse items, review the cart, then issue the receipt.

### REQ-ME-004 — Local Product Catalogue
- The merchant's full product list — including names, prices, and stock levels — is saved on the device so it can be searched instantly at any time, with or without internet.
- The catalogue is refreshed automatically from the platform whenever a connection is available.
- The POS checkout flow is never blocked waiting for product information to load from the internet.

---

## 4. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Speed** | Adding an item to a receipt feels instantaneous — there is no visible delay at the counter. |
| **Resilience** | The app handles transitions between poor, good, and no connectivity without losing any data or crashing. |
| **Storage** | The app manages its own device storage efficiently; old completed receipts are cleaned up automatically after 90 days. |
| **Security** | Transaction and inventory data stored on the device is protected and inaccessible to other apps on the same device. |

---

## 5. Data Flows

- **POS transactions:** Sales and receipts are first saved on the merchant's device. Once connected, the platform receives a copy of each transaction and updates the central inventory record accordingly.
- **Pool Buying:** The platform sends the merchant a list of active Pools in their cluster, including live progress totals. When the merchant commits a quantity, that commitment is sent to the platform, which updates the Pool's running total and notifies all participants when the threshold is reached.
- **Inventory sync:** When the merchant's device reconnects, updated stock levels are sent to the platform so that the consumer app and backoffice dashboard reflect accurate availability.
- **Pool status notifications:** When a Pool changes status — for example, when it reaches its minimum order quantity — the platform pushes a real-time notification to the merchant's device.
- **Village data isolation:** All Pools, products, and transactions visible to the merchant belong exclusively to their village cluster. No cross-cluster data is ever exposed.

---

## 6. Out of Scope

- Consumer-facing browsing & ordering → `consumer_app`
- Delivery routing & GPS tracking → `courier_app`
- Village-wide admin controls → `backoffice_web`
- Public SEO catalog → `website`
