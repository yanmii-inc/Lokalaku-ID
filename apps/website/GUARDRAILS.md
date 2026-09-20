# 🛡️ Guardrails: Public Website (Astro)

> **Role:** High-speed, lightweight public village catalog & marketplace directory (`apps/website`).  
> **Audience:** First-time visitors, prospective consumers, and search engine crawlers.

---

## 1. Core Architectural Constraints

1. **HTML-First Rendering (≥95% Static):**
   - The entire page structure (headers, navigation, village cluster listings, product catalogs, footers) must be compiled to pure static HTML at build time or server-rendered on demand.
   - Zero client-side JavaScript should be required to display and read the village store and product catalog.

2. **Strict Islands Architecture (`client:*`):**
   - Interactive client-side components must be strictly isolated into **Astro Islands**.
   - Only dynamic elements requiring real-time user input (such as `<SearchBox client:load />` or optional geolocation distance sort) may include client-side JS.
   - **Prohibited:** Full-page React Client-Side Rendering (CSR), Single-Page App (SPA) routers, or wrapping entire page layouts in React components.

3. **Client Bundle Size Budgets:**
   - **Initial Page JS Budget:** Total critical JavaScript transferred on initial load must be **under 50 KB (gzipped)**.
   - **No Heavy UI Framework Bloat:** Do not import UI libraries that ship monolithic runtimes (e.g. MUI, Ant Design, Chakra UI). Use utility CSS (TailwindCSS) and custom minimal accessible components.

4. **SEO & Crawlability:**
   - Every active village cluster page (`/desa-[slug]`) must contain fully-formed semantic HTML (`<h1>`, meta description, OpenGraph tags, structured JSON-LD data for LocalBusiness/Product).
   - Search crawlers must be able to index store names, addresses, and catalog items without executing client-side JavaScript.

5. **Vendor Independence:**
   - Avoid platform-proprietary deployment dependencies (e.g., Vercel or Netlify proprietary edge adapters).
   - Output must compile to static HTML/assets (`output: 'static'`) deployable to any standard web server (Nginx, Caddy, Docker container, GitHub Pages, or Cloudflare Pages).

---

## 2. Cache Control & Asset Header Rules

Assets served by the website must respect the following caching headers:

| Asset Type | Pattern | Cache-Control Header |
|:---|:---|:---|
| **Fingerprinted Assets** | `/_astro/*`, `*.hash.js`, `*.hash.css` | `public, max-age=31536000, immutable` |
| **Static Images & Fonts** | `/images/*`, `/fonts/*` | `public, max-age=2592000, stale-while-revalidate=86400` |
| **HTML Entrypoints** | `/*.html`, `/` | `public, max-age=0, must-revalidate` |
| **Manifests & Configs** | `manifest.json`, `robots.txt`, `sitemap.xml` | `public, max-age=3600, must-revalidate` |

---

## 3. Verification & Guardrail Checks

During CI/CD and local builds:
- Verify that `dist/` contains valid `.html` files for pre-rendered pages.
- Verify that the total uncompressed and gzipped JS in `dist/_astro/` remains strictly within performance budgets.
