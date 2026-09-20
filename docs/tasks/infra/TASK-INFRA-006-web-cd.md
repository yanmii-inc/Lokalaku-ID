---
id: TASK-INFRA-006
title: "Web CD pipeline (Astro website & Flutter Backoffice on PR merge)"
milestone: INFRA
prd_ref: "REQ-INFRA-054"
app: infra
status: done
priority: high
complexity: M
github_issue: null
dependencies: ["TASK-INFRA-003"]
assigned_to: null
---

# TASK-INFRA-006: Web CD pipeline (Astro website & Flutter Backoffice on PR merge)

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** [REQ-INFRA-052, REQ-INFRA-054](../../infra/REQUIREMENTS.md)  
> **Design Doc:** _Not applicable_

---

## Objective

Build an automated Continuous Deployment (CD) workflow in GitHub Actions that triggers when a pull request modifying `apps/website` or `apps/backoffice_web` is merged into `main`, compiling production web releases and deploying them to the web hosting layer with proper asset caching.

---

## Context

Lokalaku provides a public web presence (`apps/website`, built with Astro) and an operator dashboard (`apps/backoffice_web`, built with Flutter Web). When changes to either web application merge into `main`, the CD pipeline must automatically compile optimized release bundles and deploy them to the hosting environment (VPS Nginx/Caddy container, static host, or edge).

Prior to VPS provisioning, web apps can connect to a tunneled backend (Option 1: Cloudflare Tunnel) via build-time injection (`API_BASE_URL`), allowing full end-to-end web testing while deployed to free static hosting (e.g. GitHub Pages or Cloudflare Pages). Deployments must avoid proprietary vendor lock-in per REQ-INFRA-002 and respect SEO and bundle size budgets defined in `apps/website/GUARDRAILS.md`.

---

## Acceptance Criteria

- [x] GitHub Actions workflow `.github/workflows/cd-web.yml` triggers on push to `main` with path filters (`apps/website/**`, `apps/backoffice_web/**`, `.github/workflows/cd-web.yml`).
- [x] Pipeline injects `API_BASE_URL` at build time (e.g., via `--dart-define=API_BASE_URL=...` for Flutter Web and `PUBLIC_API_URL` for Astro).
- [x] Pipeline builds `apps/website` via Astro production build (`moon run website:build` or `pnpm build`), verifying HTML-first output and client bundle budgets.
- [x] Pipeline builds `apps/backoffice_web` using `flutter build web --release` with asset optimization.
- [x] Deploys built static artifacts to target web server or hosting layer (e.g. GitHub Pages or static host) with correct cache control policies (`immutable` for fingerprinted assets, `no-cache` for `index.html`).
- [x] Workflow handles preview / staging or production deployment target depending on branch/environment configuration.

---

## Technical Notes

- Target path filters: `apps/website/**`, `apps/backoffice_web/**`, `.github/workflows/cd-web.yml`.
- Build command pattern for Flutter Web: `flutter build web --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}`.
- Pre-VPS testing (Option 1): With the backend tunneled through `cloudflared`, static web apps hosted on GitHub Pages or Cloudflare Pages can make secure CORS-enabled HTTPS API requests to the local backend.
- Leverage Moon task caching where applicable (`moon run website:build`, `moon run backoffice_web:build`).
- Set caching headers: static JS/CSS/image assets cache for 1 year; entrypoint HTML files must not be cached aggressively.
- Respect `apps/website/GUARDRAILS.md` for bundle constraints and SEO rules.
- Do NOT use cloud-proprietary hosting services that prevent self-hosting.

---

## Out of Scope

- Go backend API deployment or database migrations (handled in TASK-INFRA-005).
- Mobile client app packaging (handled in TASK-INFRA-007).
- Dynamic backend SSR infrastructure if running purely static Astro.

---

## Definition of Done

- [x] Workflow file `.github/workflows/cd-web.yml` committed and verified
- [x] Diagnostics clean (`moon run :lint`)
- [x] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
