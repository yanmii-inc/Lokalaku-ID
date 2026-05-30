# 📋 PRD: Courier App — Delivery & Fulfillment App

> **Scope:** This document covers only the `courier_app` sub-project.
> For ecosystem-wide context, refer to the root [`/PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

| Attribute | Detail |
| :--- | :--- |
| **Target User** | Independent local delivery riders (Couriers) |
| **Platform** | Android phone |
| **Core Function** | Claim and complete delivery runs for community bulk orders within a village cluster |

---

## 2. User Stories

| ID | As a… | I want to… | So that… |
| :--- | :--- | :--- | :--- |
| US-CO-01 | Courier | See a list of available delivery jobs in my area | I can choose which batches to pick up |
| US-CO-02 | Courier | Claim an entire delivery run with multiple drop-off stops in one go | I can complete several stops in a single trip |
| US-CO-03 | Courier | Have my location updated automatically while I'm on a route | Merchants and consumers can track my progress |
| US-CO-04 | Courier | Get a notification when a new delivery job is available | I don't have to manually refresh the job list |
| US-CO-05 | Courier | Mark individual drop-off stops as delivered | The system stays accurate as I complete the route |

---

## 3. Functional Requirements

### REQ-CO-001 — Automatic Location Tracking
- While a courier has an active delivery route, their location is tracked automatically in the background so that merchants and consumers can see real-time progress.
- Location updates are sent to the platform periodically rather than continuously, to preserve battery life.
- Tracking stops automatically once all stops on the route are marked as delivered, or when the courier manually ends the session.
- On low battery, the app extends the update interval to further reduce power consumption.

### REQ-CO-002 — Batch Delivery Manifest
- Couriers can see all pending delivery jobs available within their village area, each showing the number of stops, the list of drop-off addresses, estimated distance, and the payout for the run.
- A courier can claim a full set of stops for one trip in a single action.
- Only one courier can claim a particular delivery run at a time — the moment one courier claims it, it disappears from everyone else's list.
- Once claimed, the full delivery manifest is saved on the device so the courier can access the stop list even without an internet connection.

### REQ-CO-003 — Drop-off Confirmation
- Each stop in a delivery run can be confirmed individually, either by tapping a button or capturing a photo as proof of delivery (the method can be configured per village cluster).
- Confirmations are saved on the device immediately and sent to the platform whenever a connection is available — couriers can keep completing stops even in areas with poor signal.

### REQ-CO-004 — Portrait-Optimised Layout
- All screens (job list, delivery details, active route) are designed for one-handed use on a phone held in portrait orientation.
- Map and route views use standard map tiles and are kept lightweight to avoid slowing down the device or consuming excessive mobile data.

---

## 4. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Battery Life** | Location tracking in the background must have a minimal impact on battery — a courier should be able to complete a full day's deliveries on a single charge of a typical mid-range Android phone. |
| **Offline Resilience** | Delivery manifests and stop lists are available on the device even without a connection. Couriers can confirm drop-offs offline and those confirmations will sync automatically when connectivity returns. |
| **Performance** | The job list must appear quickly, drawing from locally cached data. Location updates must run quietly in the background without making the app feel sluggish. |
| **Notification Reliability** | New job notifications are delivered via push alerts. If a push notification does not arrive (common in low-signal rural areas), the app automatically checks for new jobs the next time it is opened or brought to the foreground. |

---

## 5. Data Flows

The following describes what information moves between the app and the platform, and why:

- **Job list refresh:** When a courier opens the app or returns to the foreground, the app fetches available delivery jobs for their village area so the list is always current.
- **Claiming a job:** When a courier taps "Claim", the platform immediately marks that delivery run as taken. All other couriers see it removed from their list.
- **Location updates:** While on an active route, the courier's current location is periodically sent to the platform. This feeds the live tracking view seen by merchants and consumers.
- **Stop confirmations:** When a courier marks a stop as delivered, the confirmation is recorded locally first and then forwarded to the platform. If offline, it queues up and sends automatically once reconnected.
- **New job alerts:** The platform sends the courier a push notification whenever a new delivery job becomes available in their area. If push delivery fails, the app falls back to checking for new jobs on next open.

---

## 6. Out of Scope

- Consumer checkout and ordering → `consumer_app`
- Merchant point-of-sale and stock management → `merchant_app`
- Wholesaler stock entry and pool order management → `backoffice_web`
- Public-facing product catalogue and SEO storefront → `website`
