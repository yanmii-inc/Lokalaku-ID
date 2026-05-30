# 📋 PRD: Public Web — Village Catalog & Discovery Site

> **Scope:** This document covers only the `website` sub-project.
> For ecosystem-wide context, refer to the root [`../../PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

The Public Web is the discovery front door for Lokalaku. It serves prospective consumers and villagers who have not yet installed any app — reaching them through search engines, shared links, and direct browser visits. Its primary value is making every village's stores and products findable and browsable without any friction.

| Attribute | Detail |
| :--- | :--- |
| **Target Users** | First-time visitors discovering Lokalaku via search · Any villager browsing without the app installed |
| **Primary Platform** | Web browser (desktop and mobile) |
| **Core Function** | A fast, publicly accessible village catalog: every active village cluster has its own page that search engines can index, and visitors can browse and search without installing anything |

Speed is a core product requirement. A slow page is a broken page for villagers on limited mobile data.

---

## 2. User Stories

| ID | As a… | I want to… | So that… |
| :--- | :--- | :--- | :--- |
| US-PW-01 | First-time visitor | Find local stores in my village by searching online | I discover Lokalaku organically |
| US-PW-02 | Visitor | See a list of products available near me without installing an app | I can browse before committing to a download |
| US-PW-03 | Visitor | Search for a specific product or store instantly | I don't have to scroll through every listing |
| US-PW-04 | Search engine crawler | Read fully rendered content on the very first page load | The page ranks for local commerce keywords |

---

## 3. Functional Requirements

### REQ-PW-001 — Pre-Built Village Landing Pages

Every active village cluster has its own public page at `lokalaku.in/desa-{slug}`. Each page lists the cluster's active stores (name, category, and location hint) and featured products.

**The page is fully built before any visitor arrives** — all content is present the moment the browser receives the page, with no waiting for data to appear afterward. Search engines can read and index every store name, product name, and category on the first load.

When a new village cluster is added to the platform, its page is generated automatically without requiring a full site rebuild.

### REQ-PW-002 — Live Search

Visitors can type a product name or store name into the search box and see matching results appear immediately, **without the page reloading**. A loading indicator is shown while results are being fetched. Results appear in a dropdown overlay; clicking a result takes the visitor to the relevant listing.

The search box is the **only** interactive element on the page that requires browser-side scripting. All other page content — store listings, product cards, navigation — is purely static and requires no script to display.

### REQ-PW-003 — Proximity Filter (Optional)

Visitors may optionally allow the site to use their location to sort nearby stores first. This feature is entirely optional:

- The page works fully without it.
- If the visitor denies location access, no error is shown and the default listing order is preserved.
- Location is never requested automatically — the visitor must explicitly trigger the filter.

### REQ-PW-004 — Lightweight & Fast

The site must not load unnecessary scripts, stylesheets, or design component libraries. Every kilobyte added to a page is a deliberate choice. Speed is a product requirement: village visitors on slow mobile connections must be able to use the site without frustration.

Only the live search box may load interactive scripting in the browser. Everything else is plain, pre-built content.

---

## 4. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Page Load Speed** | The main content of a village page must appear within 2.5 seconds on a standard mobile connection. User interactions (tapping, typing) must feel immediate — under 100 milliseconds. The layout must not visibly shift or jump after the initial load. |
| **Search Discoverability** | Every page must have a unique title, a unique plain-language description, a shareable preview image, and a stable canonical web address. These are required for search engines to index and rank each village's page correctly. |
| **Accessibility** | Pages must use standard content structure (headings, navigation landmarks, article regions) so that screen readers and keyboard-only navigation work correctly. All images must have descriptive text alternatives. Search results must be navigable by keyboard. |
| **Deployment Simplicity** | The built site is a folder of files. Any standard web server can host it — no special application runtime is needed in production. On-demand page generation is permitted only for village pages not yet pre-built (for example, a newly added cluster before the next scheduled build). |
| **Page Weight** | The total download size of a village landing page — all content, styling, and scripting combined — must remain small enough to load quickly even on a limited data connection. Images are excluded from this budget but must be appropriately compressed. |

---

## 5. Information Flows

**At page build time (before any visitor arrives):**
The Public Web fetches store listings and product data for every active village cluster from the Platform Engine. This happens entirely on the build server — visitors never see or trigger this fetch. The result is a set of pre-built pages ready to be served instantly. No visitor credentials or private information are involved.

**At visitor request — live search:**
When a visitor types in the search box, their browser sends the search term to the Platform Engine and receives matching store and product results. These results are served from the high-speed data layer (see REQ-BG-003 in the Platform Engine PRD) so that many simultaneous searches are handled without putting strain on permanent records. The result appears in the browser without reloading the page.

**Direction of data:**
The Public Web is **strictly read-only**. It fetches data to display — it never creates, modifies, or deletes anything in the Platform Engine.

---

## 6. Out of Scope

*   Consumer checkout and cart — handled by the Consumer App
*   Merchant point-of-sale — handled by the Merchant App
*   Village admin and stock management — handled by the Backoffice Web
*   Business logic and data rules — handled by the Platform Engine (`api`)
