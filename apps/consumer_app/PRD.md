# 📋 PRD: Consumer App — Warga Shopping App

> **Scope:** This document covers only the `consumer_app` sub-project.
> For ecosystem-wide context, refer to the root [`/PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

| Attribute | Detail |
| :--- | :--- |
| **Target User** | End-retail villagers (Warga) |
| **Platforms** | Android phone app (primary) · Web browser (secondary) |
| **Core Function** | Browse nearby store inventories, place orders for daily goods, and track order status in real time |

---

## 2. User Stories

| ID | As a… | I want to… | So that… |
| :--- | :--- | :--- | :--- |
| US-CS-01 | Consumer | Browse items available in stores near me | I can find what I need without travelling |
| US-CS-02 | Consumer | Add items to a cart and check out | I can place an order quickly |
| US-CS-03 | Consumer | Receive a notification when my order status changes | I know when to expect my delivery |
| US-CS-04 | Consumer | Open the app in my browser without installing anything | I can access Lokalaku on any device |
| US-CS-05 | Consumer | Choose whether to share my location before browsing nearby stores | My location is never accessed without my consent |

---

## 3. Functional Requirements

### REQ-CS-001 — Cart & Checkout
- Provide an intuitive, low-friction cart and checkout experience for buying daily goods from nearby stores.
- Cart contents are saved on the device automatically. If the consumer closes the app or loses connection before confirming an order, their cart is still there when they return.

### REQ-CS-002 — Order Status Notifications
- Consumers receive real-time notifications whenever their order status changes (e.g. confirmed, out for delivery, delivered).
- Notifications are delivered to the phone app or the browser, whichever the consumer is using.
- Tapping the notification takes the consumer directly to their order.

### REQ-CS-003 — Nearby Store Discovery
- By default, the browse view shows stores within the consumer's village cluster.
- Location-based sorting (showing the closest stores first) is strictly opt-in: the consumer is asked for permission before their location is used. If permission is declined or unavailable, the app shows the full cluster listing — it never freezes or crashes.

### REQ-CS-004 — Works on Android and Browser
- The consumer experience is consistent whether using the Android app or a web browser — the same features are available on both.
- Features unavailable on one platform are handled gracefully on the other, with no broken screens or errors shown to the user.

### REQ-CS-005 — Installable from the Browser
- Consumers using the browser version can add the app to their phone's home screen directly from the browser, without visiting an app store.
- The browser version loads quickly even on slow mobile connections.
- The layout works on any screen size, down to a basic smartphone.

---

## 4. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Speed** | The app feels fast and responsive on entry-level Android smartphones. |
| **Resilience** | If the platform is temporarily unreachable, the app shows a clear message and a retry option — it never crashes silently. |
| **Offline Access** | Cart contents and order history remain viewable even without an internet connection. |
| **Accessibility** | All buttons, links, and form elements are labelled so that screen readers can describe them to users with visual impairments. |
| **Lightweight** | The app avoids unnecessarily large components that would slow down loading or increase data usage for users on limited mobile data. |

---

## 5. Data Flows

- **Store discovery:** When a consumer opens the browse screen, the platform sends them a list of stores in their village cluster. If location permission has been granted, stores are sorted by proximity.
- **Placing an order:** When the consumer confirms their cart, the order details are sent to the platform and a confirmation is returned to the consumer's screen.
- **Order tracking:** Whenever a merchant or courier updates an order's status, the platform immediately notifies the consumer's app or browser. The update appears as a notification and refreshes the order screen.
- **Village data isolation:** All data shown to a consumer — stores, products, and orders — belongs exclusively to their village cluster. No data from other clusters is ever surfaced.

---

## 6. Out of Scope

- Merchant POS features → `merchant_app`
- Courier tracking map → `courier_app`
- Public SEO catalog → `website`
- Admin / wholesaler dashboard → `backoffice_web`
