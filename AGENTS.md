# 🤖 LOKALAKU: AI AGENTS & CO-PILOT CONFIGURATION GUIDELINES

Welcome, AI Agent / Co-pilot. You are assisting in building **Lokalaku**, an open-source, decentralized alternative to centralized village cooperatives (KopDes Merah Putih). This is a **Polyglot Monorepo** containing Golang (Backend), Flutter (Mobile & Admin Web), and Astro (Public Web SEO).

To ensure architectural consistency, reduce code debt, and prevent cross-framework pollution, you **MUST** strictly follow the guidelines below based on the workspace context you are operating in.

---

## 🌍 GLOBAL ARCHITECTURAL PRINCIPLES (ALL AGENTS MUST READ)

1. **Zero Vendor Lock-In:** All systems must be deployable on a bare-metal VPS or Docker container. Avoid cloud-native proprietary APIs (e.g., Vercel-specific features, AWS-only tools).
2. **Offline-First for Operations:** Mobile apps (Merchant/Courier) must gracefully handle low/no internet scenarios using local caching.
3. **Data Sovereignty:** Data belongs to the specific village cluster (`village_cluster_id`). Ensure isolation between different village data.
4. **Efficiency Over Hype:** Write memory-efficient, low-allocation code. We target low-end devices and cheap infrastructure.

---

## 🛠️ CONTEXT-SPECIFIC AGENT INSTRUCTIONS

### 1. 🐹 Context: `/backend-go` (Backend Core Engine)
**Role:** High-Performance, Low-Allocation REST API Server.
*   **Tech Stack:** Golang (Standard Library or lightweight router like Chi/Fiber), PostgreSQL, Redis (Caching Layer).
*   **State Management & Concurrency:** Use native Go channels and mutexes carefully. Ensure ACID compliance for transactions, especially during `Pool_Orders` aggregation to prevent race conditions.
*   **Prohibited:** Do NOT suggest heavy enterprise frameworks. Keep it single-binary friendly.
*   **Code Style:** Idiomatic Go. Return errors explicitly. Handle `nil` checks thoroughly.

### 2. 📱 Context: `/mobile-apps` (Operational Flutter Suite)
**Role:** Multi-role cross-platform applications with high UX responsiveness.
*   **Tech Stack:** Flutter (Dart).
*   **Sub-Projects Rules:**
    *   `/apps/merchant_app`: Responsive layout (Tablet & Phone) optimized for fast item-tapping and cash register flow.
    *   `/apps/courier_app`: Phone layout, highly optimized for portrait mode, map/GPS tracking efficiency, and background notification reliability.
    *   `/apps/consumer_app`: Built primarily for Android (Native APK) and lightweight mobile deployment. High reliance on background push notifications.
    *   `/apps/backoffice_web`: Dashboard for Village Admins and Wholesale Operators. Responsive for desktop browsers.
*   **State Management:** Use clean, predictable state management (e.g., Bloc or Riverpod). Avoid mixing UI and Business Logic.
*   **Prohibited:** Do NOT suggest embedding web views for core functionalities. All checkout and scanning flows must be native components.

### 3. 🚀 Context: `/public-web-astro` (SEO & Acquisition Engine)
**Role:** Super-fast, lightweight public-facing catalog and marketplace directory.
*   **Tech Stack:** Astro Framework, HTML5, TailwindCSS, React (Strictly isolated for interactive elements only).
*   **SEO & Rendering Rule:** 95% of the website must be compiled into pure static HTML or Server-Side Rendered (SSR) on demand. 
*   **Islands Architecture:** You may ONLY inject React components for the Live Search Box (`<SearchBox client:load />`) or dynamic distance filters. The rest must be HTML-first without hydration overhead.
*   **Prohibited:** 
    *   Do NOT suggest full-page React Client-Side Rendering (CSR).
    *   Do NOT suggest Next.js-specific routing or caching methods.
    *   Do NOT introduce heavy component libraries that bloat the client bundle size.

---

## 🔄 CROSS-LAYER INTEGRATION CONTRACTS

When generating code that connects multiple layers, always adhere to this routing data flow:

```text
📱 Flutter Apps & Web Admin ──(REST API)──► [Golang Backend Core] ◄──(Server-Side Fetch)── 🚀 Astro Public Web