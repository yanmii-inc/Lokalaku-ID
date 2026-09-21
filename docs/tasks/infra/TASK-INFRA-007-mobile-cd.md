---
id: TASK-INFRA-007
title: "Mobile CD pipeline (Flutter Android build, sign & distribute on PR merge)"
milestone: INFRA
prd_ref: "REQ-INFRA-055"
app: infra
status: done
priority: high
complexity: L
github_issue: null
dependencies: ["TASK-INFRA-003"]
assigned_to: null
---

# TASK-INFRA-007: Mobile CD pipeline (Flutter Android build, sign & distribute on PR merge)

> **Milestone:** Infrastructure (cross-cutting)  
> **PRD Reference:** [REQ-INFRA-052, REQ-INFRA-055](../../infra/REQUIREMENTS.md)  
> **Design Doc:** _Not applicable_

---

## Objective

Build an automated Continuous Delivery (CD) workflow in GitHub Actions that triggers when a pull request modifying mobile applications (`consumer_app`, `merchant_app`, `courier_app`) or shared packages is merged into `main`, compiling signed release Android APKs and App Bundles (AAB), and publishing them to internal distribution channels for testers and operators.

---

## Context

Lokalaku's ecosystem relies on multiple mobile clients: Consumer App (Android & Web), Merchant POS App (Android Tablet/Phone), and Courier App (Android Phone). For grassroots operations, merchant pilots, and courier field testing, direct APK distribution and timely internal builds are vital.

Prior to provisioning a dedicated production VPS, mobile builds connect to the backend exposed via a zero-cost HTTPS tunnel (Option 1: Cloudflare Tunnel via `cloudflared tunnel --url http://localhost:8080`). The CD workflow must dynamically inject the target `API_BASE_URL` at build time without hardcoding hostnames into the repository, securely inject Android keystores, compile optimized release builds, and publish versioned artifacts automatically whenever mobile code or shared packages are updated on `main`.

---

## Acceptance Criteria

- [x] GitHub Actions workflow `.github/workflows/cd-mobile.yml` triggers on push to `main` with path filters (`apps/consumer_app/**`, `apps/merchant_app/**`, `apps/courier_app/**`, `packages/flutter/**`, `.github/workflows/cd-mobile.yml`).
- [x] Matrix strategy builds each modified mobile app independently to optimize CI run duration.
- [x] Builds inject `API_BASE_URL` via `--dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}` (pointing to Cloudflare Tunnel during staging/testing, or production VPS once live).
- [x] Cryptographic signing implemented using base64-encoded keystore from GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) without leaking secrets.
- [x] Generates signed universal release APKs (for direct download and sideloading) and AABs (for Play Console tracks).
- [x] Releases are stamped with semantic version and incremental build number (derived from GitHub run number or git commit count).
- [x] Published artifacts are attached to GitHub workflow run and pushed to GitHub Releases (pre-release) or internal distribution service.

---

## Technical Notes

- Target path filters: `apps/consumer_app/**`, `apps/merchant_app/**`, `apps/courier_app/**`, `packages/flutter/**`, `.github/workflows/cd-mobile.yml`.
- Build command pattern: `flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL || 'http://10.0.2.2:8080' }}`.
- Pre-VPS testing (Option 1): Expose local backend with `cloudflared tunnel --url http://localhost:8080` and set GitHub Secret `API_BASE_URL` to the generated tunnel URL. This allows physical test devices on mobile data to connect without a paid VPS.
- Cache Gradle caches (`~/.gradle/caches`, `~/.gradle/wrapper`) and pub cache (`~/.pub-cache`) for fast rebuilds.
- Adhere to AGENTS.md rules for low-end device compatibility and asset size discipline.
- NEVER commit keystores, signing keys, or raw passwords into version control.
- Ensure `kIsWeb` guards remain uncompromised during Android builds.

---

## Out of Scope

- iOS IPA signing and TestFlight distribution (requires macOS runner and Apple Developer certificate provisioning; deferred to future task).
- Flutter Desktop installers (macOS DMG, Linux AppImage, Windows MSIX) for Wholesaler App.
- Automated public Play Store production track promotion without human approval.

---

## Definition of Done

- [x] Workflow file `.github/workflows/cd-mobile.yml` committed and verified
- [x] Signing logic validated with sample / CI mock keystore
- [x] `TASK-INDEX.md` status updated to `done`
- [ ] GitHub issue closed
