# 🔐 Auth Flow — Product Design

> **Scope:** Authentication and session lifecycle across all five Lokalaku apps.
> Covers user stories, acceptance criteria, screen inventory, token strategy, API contract, and edge cases.
>
> **Derived from PRD requirements:** `REQ-BG-004`, `REQ-BG-005`, `REQ-BG-006`, `REQ-ME-003`, `REQ-ME-004`, `REQ-CO-003`, `REQ-CO-004`, `REQ-CS-002`, `REQ-CS-003`, `REQ-WS-004`, `REQ-WS-005`, `REQ-SA-004`
> See [`/PRD.md`](../../PRD.md) for the authoritative requirement definitions.

---

## 1. Roles & App Matrix

Each app serves exactly one role. There is no role-switching within a single app.

| Role | App | Registration | Account Creation |
|:---|:---|:---|:---|
| **Consumer** (Warga) | `consumer_app` | Self-serve via phone OTP | Instant — no approval needed |
| **Merchant** (Warung) | `merchant_app` | Self-serve with store info | Requires superadmin approval |
| **Courier** | `courier_app` | Self-serve with vehicle info | Requires superadmin approval |
| **Wholesaler** | `wholesaler_app` | Self-serve with business docs | Requires superadmin approval |
| **Superadmin** | `backoffice_web` | None — provisioned manually | Created directly in the database |

---

## 2. Token Architecture

### Strategy
- **Access Token** — JWT, short-lived (15 minutes). Carries `user_id`, `role`, `village_cluster_id`, `exp`.
- **Refresh Token** — Opaque token, long-lived (30 days). Stored server-side (Redis) and client-side (secure storage). Rotated on every use.
- **One active refresh token per device.** New login on the same device replaces the existing token.

### Client Storage
| Platform | Storage Mechanism |
|:---|:---|
| Android | `flutter_secure_storage` (Android Keystore) |
| Flutter Web | `flutter_secure_storage` web (sessionStorage + encrypted) |
| Desktop | `flutter_secure_storage` (OS credential store) |

### Session States

```
  ┌─────────────────┐
  │ UNAUTHENTICATED │ ◄─── cold start / logout / refresh failed
  └────────┬────────┘
           │  login success
  ┌────────▼────────┐
  │  AUTHENTICATED  │ ◄─── access token valid
  └────────┬────────┘
           │  access token expires
  ┌────────▼────────┐
  │   REFRESHING    │  auto-refresh via Dio interceptor
  └────────┬────────┘
           │  success           │  failure (refresh expired / revoked)
  ┌────────▼────────┐   ┌───────▼──────────┐
  │  AUTHENTICATED  │   │ UNAUTHENTICATED   │
  └─────────────────┘   └──────────────────┘
```

### Package Responsibilities
| Package | Responsibility |
|:---|:---|
| `lokalaku_domain` | `AuthToken` entity, `User` entity, `AuthRepository` interface |
| `lokalaku_core_network` | Dio interceptor — attaches `Bearer` token, triggers refresh on 401 |
| `lokalaku_core_auth` | `AuthService` — login, logout, refresh, secure token storage, session stream |
| `lokalaku_data` | `AuthRepositoryImpl` — HTTP calls to API auth endpoints |
| Each app | `AuthNotifier` (Riverpod) — listens to session stream, drives router redirect |

---

## 3. Consumer App (`consumer_app`)

### Context
Warga (end consumers) can browse local store listings without logging in. An account is required only to place an order. Both Android native and Flutter Web (PWA) targets must be supported.

### User Stories

---

**AUTH-CS-01 — Guest Browsing** `REQ-CS-002`
> As a visitor, I want to browse nearby stores and product listings without creating an account, so I can explore what's available before committing to sign up.

**Acceptance Criteria:**
- [ ] App launches directly to the home/discovery screen with no auth gate.
- [ ] Store listings and product details are fully readable without a session.
- [ ] A "Sign in to order" prompt appears only when a gated action is attempted (e.g. adding to cart, checking out).
- [ ] On web, GPS permission is requested before proximity filtering is applied. If denied or unavailable, proximity filter is hidden — the app does not crash.

---

**AUTH-CS-02 — Registration via Phone OTP** `REQ-CS-003` · `REQ-BG-006`
> As a new user, I want to register with my phone number using a one-time code, so I don't need to remember a password and my identity is tied to a real device.

**Acceptance Criteria:**
- [ ] User enters a valid Indonesian phone number (`+62…` format), validated client-side before submission.
- [ ] API sends a 6-digit OTP via SMS to the provided number.
- [ ] OTP input screen shows a 60-second countdown resend timer. Resend is disabled until it expires.
- [ ] Up to 3 resend attempts are allowed before the session is invalidated and the user must restart.
- [ ] On successful OTP verification, the user is prompted to set a display name.
- [ ] A JWT access + refresh token pair is returned and stored in secure storage.
- [ ] User is redirected to the home screen upon completion.
- [ ] On Flutter Web: the flow is identical. No platform-specific OTP autofill is assumed — user types the code manually.

---

**AUTH-CS-03 — Login** `REQ-CS-003` · `REQ-BG-004`
> As a returning user, I want to log in with my phone number and OTP (or password if I set one), so I can access my order history and checkout.

**Acceptance Criteria:**
- [ ] Login screen offers two methods: **Phone + OTP** (default) and **Phone + Password** (if user previously set a password).
- [ ] OTP method follows the same flow as registration (AUTH-CS-02).
- [ ] On successful login, tokens are stored and the user is returned to the screen they were on before the auth gate appeared.
- [ ] A "wrong number" or invalid OTP error displays a human-readable message. Never expose raw API errors.
- [ ] After 5 consecutive failed password attempts, the account is temporarily locked for 15 minutes. The UI displays the remaining lockout time.

---

**AUTH-CS-04 — Persistent Session** `REQ-BG-004`
> As a returning user, I want to stay logged in across app restarts, so I don't have to sign in every time I open the app.

**Acceptance Criteria:**
- [ ] On app start, `AuthService` reads the stored refresh token and silently attempts a token refresh before rendering any screen.
- [ ] If refresh succeeds, user lands on the home screen as authenticated.
- [ ] If refresh fails (expired or revoked), user lands on the home screen as a guest — no forced login screen.
- [ ] The splash/loading screen is shown during this check. It must resolve within 3 seconds; if the API is unreachable, assume guest mode.

---

**AUTH-CS-05 — Logout** `REQ-BG-004`
> As a logged-in user, I want to log out of my account, so I can hand my device to someone else or switch accounts.

**Acceptance Criteria:**
- [ ] Logout is accessible from the profile screen.
- [ ] On logout: refresh token is revoked server-side (best-effort), tokens are cleared from secure storage, and Riverpod state is reset.
- [ ] User is returned to the home/guest screen. No personal data (order history, etc.) is visible after logout.
- [ ] If the revocation API call fails (e.g. offline), the client-side tokens are still cleared. The server-side token expires naturally.

---

### Screen Inventory

| Screen | Route | Auth Required |
|:---|:---|:---|
| Home / Discovery | `/` | No |
| Store Detail | `/stores/:id` | No |
| Product Detail | `/stores/:id/products/:pid` | No |
| Auth Gate Prompt | (bottom sheet) | — |
| Register — Enter Phone | `/auth/register` | No |
| Register — Verify OTP | `/auth/register/verify` | No |
| Register — Set Name | `/auth/register/profile` | No |
| Login — Enter Phone | `/auth/login` | No |
| Login — Verify OTP | `/auth/login/verify` | No |
| Profile / Account | `/profile` | Yes |

---

## 4. Merchant App (`merchant_app`)

### Context
Warung owners use this app as their primary business tool — both for wholesale pool ordering and for daily over-the-counter POS sales. The POS must work fully offline. Auth must account for the case where a session expires while the merchant is offline mid-shift.

### User Stories

---

**AUTH-ME-01 — Registration** `REQ-ME-003` · `REQ-BG-005` · `REQ-BG-006`
> As a warung owner, I want to register my store on the platform so I can start sourcing stock through wholesale pools.

**Acceptance Criteria:**
- [ ] Registration form collects: full name, phone number, store name, store address, and village cluster selection (from a dropdown of active clusters).
- [ ] Phone number is verified via OTP before the form can be submitted.
- [ ] On submission, account status is `pending_approval`. A confirmation screen communicates that approval is in progress.
- [ ] The app does NOT grant a session until the account is approved. The login screen shows a "your account is pending approval" state if the user tries to log in before approval.
- [ ] Superadmin receives an approval task in `backoffice_web` (outside scope of this document).

---

**AUTH-ME-02 — Login** `REQ-BG-004` · `REQ-BG-005`
> As an approved merchant, I want to log in with my phone number and password so I can access my store dashboard and POS.

**Acceptance Criteria:**
- [ ] Login requires: phone number + password. No OTP login for merchants (password is set during the approval onboarding flow).
- [ ] On successful login, the app lands on the store dashboard.
- [ ] If account is `pending_approval`, display a dedicated waiting screen instead of the dashboard.
- [ ] If account is `suspended`, display a suspension notice with a support contact prompt.

---

**AUTH-ME-03 — PIN Quick-Auth for POS** `REQ-ME-004` · `REQ-ME-001`
> As a merchant mid-shift, I want to unlock the POS with a short PIN instead of re-entering my full password, so I can keep serving customers quickly even if the session times out.

**Acceptance Criteria:**
- [ ] During onboarding (post-approval), the merchant is prompted to set a 6-digit PIN.
- [ ] PIN is stored locally in secure storage and hashed. It is **never sent to the server**.
- [ ] When the access token expires during an active POS session, a PIN lock screen overlays the POS instead of navigating away.
- [ ] Correct PIN locally validates and triggers a background token refresh attempt.
- [ ] If the token refresh also fails (device offline), the PIN unlock grants a **temporary offline session** — POS transactions continue writing to local storage. A sync queue is triggered once connectivity resumes.
- [ ] After 5 incorrect PIN attempts, the full login screen is shown. The local PIN is cleared.
- [ ] PIN is cleared on full logout.

---

**AUTH-ME-04 — Persistent Session & Offline Resilience** `REQ-ME-004` · `REQ-ME-001` · `REQ-BG-004`
> As a merchant, I want my session to survive app restarts and brief connectivity gaps so my POS workflow is never interrupted.

**Acceptance Criteria:**
- [ ] Same refresh-on-start flow as AUTH-CS-04.
- [ ] If offline at start: if a valid (non-expired) access token exists in storage, grant offline session immediately. POS is accessible. Non-POS features that require the network show an "offline" state.
- [ ] Offline session is limited to 8 hours without a successful refresh. After that, PIN lock screen is shown.

---

**AUTH-ME-05 — Logout** `REQ-BG-004`
> As a merchant, I want to log out so I can secure my account at end of day.

**Acceptance Criteria:**
- [ ] Logout is accessible from the account/settings screen — not from inside the POS flow.
- [ ] If there are unsynced offline transactions in the queue, logout is blocked with a warning: "You have unsynced sales. Please connect to the internet before logging out."
- [ ] On successful logout: refresh token revoked, tokens cleared, PIN cleared, Riverpod state reset.

---

### Screen Inventory

| Screen | Route | Auth Required |
|:---|:---|:---|
| Login | `/auth/login` | No |
| Register — Store Info | `/auth/register` | No |
| Register — Verify OTP | `/auth/register/verify` | No |
| Pending Approval | `/auth/pending` | No |
| Suspended Notice | `/auth/suspended` | No |
| Set PIN | `/auth/set-pin` | Yes (post-approval onboarding) |
| PIN Lock Overlay | (overlay) | — |
| Dashboard | `/dashboard` | Yes |
| POS | `/pos` | Yes |

---

## 5. Courier App (`courier_app`)

### Context
Couriers are field workers with low-end Android phones. The auth flow must be fast, lightweight, and resilient to poor connectivity. Background GPS telemetry must continue even when the access token is near expiry.

### User Stories

---

**AUTH-CO-01 — Registration** `REQ-CO-003` · `REQ-BG-005` · `REQ-BG-006`
> As a prospective courier, I want to register my account with my personal and vehicle details so I can be approved to take delivery jobs.

**Acceptance Criteria:**
- [ ] Registration collects: full name, phone number (OTP-verified), ID card number (KTP), vehicle type, and vehicle plate number.
- [ ] Account status is `pending_approval` on submission. Confirmation screen shown.
- [ ] Login is blocked with a "pending approval" state until superadmin approves.

---

**AUTH-CO-02 — Login** `REQ-BG-004` · `REQ-BG-005`
> As an approved courier, I want to log in quickly so I can start accepting delivery jobs for the day.

**Acceptance Criteria:**
- [ ] Login: phone number + password.
- [ ] On success, lands on the job feed screen.
- [ ] Pending/suspended states handled identically to AUTH-ME-02.
- [ ] Login screen is portrait-only and optimized for one-thumb use.

---

**AUTH-CO-03 — Background Session for GPS Telemetry** `REQ-CO-004` · `REQ-CO-001`
> As an active courier on a route, I want my session to stay valid in the background so GPS location updates are never dropped due to token expiry.

**Acceptance Criteria:**
- [ ] The Dio auth interceptor proactively refreshes the access token when it has less than 3 minutes of lifetime remaining, rather than waiting for a 401.
- [ ] Token refresh runs on a background isolate so it does not block the UI or interrupt GPS batching.
- [ ] If a refresh fails mid-route, GPS coordinates are buffered locally and retried with exponential backoff. No coordinates are dropped.
- [ ] The courier is notified with a non-intrusive banner ("Connection lost — location buffering") — not a blocking dialog.

---

**AUTH-CO-04 — Logout** `REQ-BG-004`
> As a courier, I want to log out at end of day so my account is secured.

**Acceptance Criteria:**
- [ ] Logout is only permitted when no active route is claimed. If a route is active, logout is blocked: "Complete or release your current delivery first."
- [ ] On logout: tokens cleared, buffered GPS data flushed (or discarded if route is already marked complete).

---

### Screen Inventory

| Screen | Route | Auth Required |
|:---|:---|:---|
| Login | `/auth/login` | No |
| Register | `/auth/register` | No |
| Register — OTP | `/auth/register/verify` | No |
| Pending Approval | `/auth/pending` | No |
| Job Feed | `/jobs` | Yes |
| Active Route | `/jobs/:id/route` | Yes |

---

## 6. Wholesaler App (`wholesaler_app`)

### Context
Wholesale operators manage their product catalogues and pool order pipelines from a **Desktop** (primary) or **Web** (secondary) app. Sessions are longer-lived. File-system operations (e.g. bulk CSV import) are Desktop-only and must be guarded with `kIsWeb`.

### User Stories

---

**AUTH-WS-01 — Registration** `REQ-WS-004` · `REQ-BG-005` · `REQ-BG-006`
> As a wholesale supplier, I want to register my business on Lokalaku so I can start listing products for merchants in my assigned village clusters.

**Acceptance Criteria:**
- [ ] Registration collects: business name, business registration number (NIB), PIC full name, PIC phone (OTP-verified), PIC email, product categories, and desired village clusters.
- [ ] Uploaded business documents (NIB scan) are accepted as file upload on Desktop, or image capture on Web. `kIsWeb` guard applies.
- [ ] Account status is `pending_verification`. A confirmation screen explains the review process (typically 1–3 business days).
- [ ] Login is blocked until superadmin verifies and assigns village clusters.

---

**AUTH-WS-02 — Login** `REQ-BG-004` · `REQ-BG-005`
> As a verified wholesaler, I want to log in from my desktop or browser to manage my product catalogue and monitor pool orders.

**Acceptance Criteria:**
- [ ] Login: email + password (email is the primary identifier for wholesalers, not phone).
- [ ] "Remember me" checkbox: if checked, refresh token persists for 30 days; if unchecked, refresh token is session-scoped (cleared when app/window closes).
- [ ] On success, lands on the wholesaler dashboard.
- [ ] On web, the session respects browser tab lifecycle — closing the tab ends the session if "remember me" is unchecked.

---

**AUTH-WS-03 — Password Reset** `REQ-WS-005`
> As a wholesaler who forgot their password, I want to reset it via email so I can regain access to my account.

**Acceptance Criteria:**
- [ ] "Forgot password" link on login screen.
- [ ] User enters their registered email address. API sends a reset link (via Mailpit in dev, SMTP in prod).
- [ ] Reset link is valid for 30 minutes and single-use.
- [ ] After successful reset, user is redirected to the login screen with a success message.
- [ ] All existing sessions for that account are revoked server-side on reset.

---

**AUTH-WS-04 — Logout** `REQ-BG-004`
> As a wholesaler, I want to log out securely, especially when using a shared workstation.

**Acceptance Criteria:**
- [ ] Logout from the account menu.
- [ ] On logout: refresh token revoked, tokens cleared, "remember me" preference cleared.
- [ ] On Desktop: app returns to the login screen.
- [ ] On Web: page navigates to `/login`.

---

### Screen Inventory

| Screen | Route | Auth Required |
|:---|:---|:---|
| Login | `/auth/login` | No |
| Register — Business Info | `/auth/register` | No |
| Register — OTP | `/auth/register/verify` | No |
| Pending Verification | `/auth/pending` | No |
| Forgot Password | `/auth/forgot-password` | No |
| Reset Password | `/auth/reset-password` | No |
| Dashboard | `/dashboard` | Yes |

---

## 7. Backoffice Web (`backoffice_web`)

### Context
Superadmin dashboard for Lokalaku platform operators. No public registration. All accounts are provisioned by engineering. Security posture is higher than other apps — session timeouts are strict.

### User Stories

---

**AUTH-SA-01 — Login** `REQ-SA-004`
> As a platform operator, I want to log in to the backoffice with my credentials so I can manage the platform.

**Acceptance Criteria:**
- [ ] Login: email + password.
- [ ] No "remember me" option. Sessions are always non-persistent (access token in memory, refresh token in sessionStorage — cleared on tab close).
- [ ] Access token lifetime is 15 minutes. Refresh token lifetime is 4 hours (one working session).
- [ ] After 4 hours of inactivity or browser close, the operator must log in again.
- [ ] Failed login attempts: after 5 failures, account is locked for 30 minutes. A notification is sent to other active superadmins.

---

**AUTH-SA-02 — Session Timeout** `REQ-SA-004`
> As a security measure, I want my backoffice session to auto-expire after a period of inactivity, so that an unattended workstation cannot be exploited.

**Acceptance Criteria:**
- [ ] After 30 minutes of UI inactivity (no mouse/keyboard events), a warning modal appears: "Your session will expire in 2 minutes."
- [ ] If the user dismisses the modal or interacts with the app, the inactivity timer resets.
- [ ] If the timer expires: tokens are cleared, user is redirected to login with a "Session expired" message.

---

**AUTH-SA-03 — Logout** `REQ-SA-004` · `REQ-BG-004`
> As an operator, I want to explicitly log out so I can secure the dashboard when leaving my workstation.

**Acceptance Criteria:**
- [ ] Logout from the top navigation bar.
- [ ] On logout: refresh token revoked, all in-memory and sessionStorage tokens cleared.
- [ ] Redirected to `/login` with a "Logged out successfully" message.

---

### Screen Inventory

| Screen | Route | Auth Required |
|:---|:---|:---|
| Login | `/auth/login` | No |
| Session Expired | (modal / redirect) | — |
| Dashboard | `/dashboard` | Yes |

---

## 8. API Contract

All auth endpoints live under `/api/v1/auth`. The API enforces role boundaries — a merchant credential cannot access wholesaler-scoped endpoints.

### Endpoints

| Method | Path | Description | Used By |
|:---|:---|:---|:---|
| `POST` | `/auth/request-otp` | Send OTP to phone number | consumer, merchant, courier |
| `POST` | `/auth/verify-otp` | Verify OTP, return tokens | consumer, merchant, courier |
| `POST` | `/auth/login` | Login with email/phone + password | all apps |
| `POST` | `/auth/register` | Submit registration form | consumer, merchant, courier, wholesaler |
| `POST` | `/auth/refresh` | Exchange refresh token for new token pair | all apps |
| `POST` | `/auth/logout` | Revoke refresh token server-side | all apps |
| `POST` | `/auth/forgot-password` | Send password reset email | wholesaler, backoffice |
| `POST` | `/auth/reset-password` | Set new password via reset token | wholesaler, backoffice |
| `GET` | `/auth/me` | Return current user profile from JWT | all apps |

### JWT Claims

```json
{
  "sub": "user_uuid",
  "role": "merchant",
  "village_cluster_id": "cluster_uuid",
  "status": "active",
  "iat": 1234567890,
  "exp": 1234568790
}
```

### Account Status Flow

```
  [Registration submitted]
          │
   ┌──────▼──────┐
   │   PENDING   │  consumer → skip this state (instant activation)
   └──────┬──────┘
          │  superadmin approves
   ┌──────▼──────┐
   │   ACTIVE    │ ◄─── normal operation
   └──────┬──────┘
          │  superadmin suspends
   ┌──────▼──────┐
   │  SUSPENDED  │  can be reactivated by superadmin
   └─────────────┘
```

---

## 9. Edge Cases & Error States

| Scenario | Behaviour |
|:---|:---|
| OTP not received | User can resend after 60s. After 3 resends, prompt to check number or contact support. |
| OTP entered after expiry | API returns `otp_expired`. Client shows "Code expired — request a new one." |
| Refresh token revoked (logged out on another device) | Next API call returns 401 with `token_revoked`. Client clears storage, redirects to login with "Signed out remotely" message. |
| Account suspended mid-session | Next API call returns 403 with `account_suspended`. Client clears session, shows suspension screen. |
| Network unavailable during login | Show inline "No connection" error. Do not clear any existing stored session. |
| Merchant tries to log in before approval | API returns 403 with `account_pending`. Client shows dedicated pending screen, not a generic error. |
| Wholesaler submits duplicate phone/email | API returns 409. Client shows "An account with this detail already exists — try logging in." |
| Wrong password (non-lockout attempt) | Generic "Incorrect phone number or password" — do not reveal which field is wrong. |
| Password reset link already used | API returns `token_used`. Client shows "This link has already been used. Request a new one." |
