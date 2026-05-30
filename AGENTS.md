# 🤖 LOKALAKU: AI AGENTS & CO-PILOT CONFIGURATION GUIDELINES (ZED NATIVE)

Welcome, AI Agent / Co-pilot. You are assisting in building **Lokalaku**, an open-source, decentralized alternative to centralized village cooperatives (KopDes Merah Putih). This is a **Polyglot Monorepo** containing Golang (API), Flutter (Apps), and Astro (Public Website).

To ensure architectural consistency, reduce code debt, and prevent cross-framework pollution, you **MUST** strictly follow the guidelines below based on the workspace context you are operating in.

---

## 🌍 GLOBAL ARCHITECTURAL PRINCIPLES (ALL AGENTS MUST READ)

1. **Zero Vendor Lock-In:** All systems must be deployable on a bare-metal VPS or Docker container. Avoid cloud-native proprietary APIs (e.g., Vercel-specific features, AWS-only tools).
2. **Offline-First for Operations:** Mobile apps (Merchant/Courier) must gracefully handle low/no internet scenarios using local caching.
3. **Data Sovereignty:** Data belongs to the specific village cluster (`village_cluster_id`). Ensure isolation between different village data.
4. **Efficiency Over Hype:** Write memory-efficient, low-allocation code. We target low-end devices and cheap infrastructure.

---

## ⚖️ CONTEXT RETRIEVAL ECONOMY & ZED RULES (TOKEN-SAVING)

To save API input tokens and prevent context bloating inside the Zed Assistant Panel, obey these execution rules:

* **No Blind Indexing:** Do NOT read or demand full external documentation files for simple syntax fixes, typos, formatting, or isolated UI styling.
* **Conditional Trigger:** You are ONLY permitted to request or query `/PRD.md` or stack-specific `GUARDRAILS.md` when:
    1. The human developer initiates a NEW subsystem, API design, or database migration.
    2. You encounter an ambiguous architectural decision regarding core business flows (e.g., Pool Buying metrics or offline data synchronization sync queues).
* **Targeted Diffs Only:** Do NOT rewrite hundreds of unchanged lines of code. Provide minimal code blocks or targeted updates.

---

## 🗂️ MONOREPO STRUCTURE

```
lokalaku-id/
├── apps/
│   ├── api/              🐹 Golang REST API
│   ├── website/          🚀 Astro public website
│   ├── consumer_app/     📱 Flutter — Android + Web/PWA
│   ├── merchant_app/     📱 Flutter — Android (Tablet + Phone)
│   ├── courier_app/      📱 Flutter — Android Phone
│   ├── wholesaler_app/   🖥️  Flutter — Desktop + Web
│   └── backoffice_web/   🌐 Flutter — Web (Superadmin)
└── packages/
    └── flutter/          📦 Shared Dart/Flutter packages
        ├── ui_kit/           Design system & shared widgets
        ├── domain/           Pure Dart entities & repository interfaces
        ├── core_network/     HTTP client & error handling
        ├── core_auth/        Auth, session & token lifecycle
        ├── data/             Repository implementations
        └── utils/            Formatters, validators, extensions
```

---

## 🛠️ CONTEXT-SPECIFIC AGENT INSTRUCTIONS

### 1. 🐹 Context: `/apps/api`
**Role:** High-Performance, Low-Allocation REST API Server.
* **Tech Stack:** Golang (Standard Library or lightweight router like Chi/Fiber), PostgreSQL, Redis (Caching Layer).
* **State Management & Concurrency:** Use native Go channels and mutexes carefully. Ensure ACID compliance for transactions, especially during `Pool_Orders` aggregation to prevent race conditions.
* **Local Boundaries:** Always fetch and obey `/apps/api/GUARDRAILS.md` for specific concurrency and memory constraints.
* **Prohibited:** Do NOT suggest heavy enterprise frameworks. Keep it single-binary friendly.
* **Code Style:** Idiomatic Go. Return errors explicitly. Handle `nil` checks thoroughly.

### 2. 📱 Context: `/apps` (Flutter Applications)
**Role:** Multi-role cross-platform applications with high UX responsiveness.
* **Tech Stack:** Flutter (Dart), Riverpod v3+ (state management), GoRouter (navigation).
* **Shared Packages:** All Flutter apps consume packages from `/packages/flutter/`. Always check existing packages before adding a new dependency directly to an app. Never duplicate logic that belongs in a shared package.
* **Local Boundaries:** Each app has its own `AGENTS.md` with app-specific rules. Always read it before making changes to that app.
* **Sub-Projects Rules:**
    * `/apps/merchant_app`: Responsive layout (Tablet & Phone) optimized for fast item-tapping and cash register flow (POS).
    * `/apps/courier_app`: Phone layout, highly optimized for portrait mode, map/GPS tracking efficiency, and background notification reliability.
    * `/apps/consumer_app`: Cross-platform for Android (Native APK) **and Web (Flutter Web)**. Android remains the primary target for end-consumers/villagers. Web build must be responsive (mobile-first) and deployed as a PWA where possible. Use Web Push API for browser-side notifications; native push (FCM) remains the primary channel on Android. Do NOT use platform-specific packages without a proper `kIsWeb` guard. Localized proximity browsing must degrade gracefully on web (no GPS hard-crash; prompt permission before use).
    * `/apps/wholesaler_app`: Flutter Desktop **and** Web app for Wholesale Operators and Factory Hubs. Desktop (macOS/Linux/Windows) is the primary target; Web build is a supported secondary target. Manages their product catalogue, monitors Pool Order commitments from merchants, and advances pool fulfillment status. Scoped strictly to the wholesaler's own products and assigned village clusters. Apply `kIsWeb` guards for any desktop-only API usage (e.g. file system access for bulk import).
    * `/apps/backoffice_web`: Platform Superadmin dashboard for Lokalaku operators only. Manages village cluster creation, wholesaler verification, platform-wide configuration, and cross-cluster health monitoring. Do NOT add wholesaler stock management or merchant/courier account flows here — those belong in `wholesaler_app` and the respective operator apps.
* **State Management:** Riverpod v3+ only. Use `Notifier<State>` + `NotifierProvider`. Do NOT use `StateNotifier`, Bloc, GetX, or Provider.
* **Prohibited:** Do NOT suggest embedding web views for core functionalities. All checkout and scanning flows must be native components.

### 3. 📦 Context: `/packages/flutter` (Shared Flutter/Dart Packages)
**Role:** Reusable building blocks shared across all Flutter apps. Managed as a Melos workspace.
* **Package responsibilities and strict dependency rules:** Always fetch and obey `/packages/flutter/AGENTS.md` before modifying any shared package.
* **Key rules (summary):**
    * `domain` and `utils` are pure Dart — zero Flutter SDK, zero internal imports.
    * `ui_kit` is widgets-only — zero business logic, zero network calls.
    * Packages never import from `apps/`. Apps never import from each other.
    * All repository methods return `Result<T>`. Never throw raw exceptions across package boundaries.
    * `publish_to: none` on every package `pubspec.yaml`.
* **Workspace commands (Moon — run from repo root):**
    * `moon run :get` — install dependencies across all Dart packages
    * `moon run :lint` — lint all packages (respects dependency order)
    * `moon run :test` — test all packages
    * `moon run domain:build-runner` / `moon run data:build-runner` — code generation
    * `moon project <name>` — inspect a package's task graph

### 4. 🚀 Context: `/apps/website`
**Role:** Super-fast, lightweight public-facing catalog and marketplace directory.
* **Tech Stack:** Astro Framework, HTML5, TailwindCSS, React (Strictly isolated for interactive elements only).
* **Local Boundaries:** Always fetch and obey `/apps/website/GUARDRAILS.md` to protect core SEO metrics.
* **SEO & Rendering Rule:** 95% of the website must be compiled into pure static HTML or Server-Side Rendered (SSR) on demand.
* **Islands Architecture:** You may ONLY inject React components for the Live Search Box (`<SearchBox client:load />`) or dynamic distance filters. The rest must be HTML-first without hydration overhead.
* **Prohibited:**
    * Do NOT suggest full-page React Client-Side Rendering (CSR).
    * Do NOT suggest Next.js-specific routing or caching methods.
    * Do NOT introduce heavy component libraries that bloat the client bundle size.

---

## 🔄 CROSS-LAYER INTEGRATION CONTRACTS

When generating code that connects multiple layers, always adhere to this routing data flow:

```text
📱 Flutter Apps & Website ──(REST API)──► [Golang API Core] ◄──(Server-Side Fetch)── 🚀 Astro Website
         │
         └── consumes ──► 📦 packages/flutter/* (shared packages)
```
