---
id: TASK-API-002
title: "PostgreSQL schema: accounts, sessions, OTP, audit"
milestone: M001
prd_ref: "REQ-BG-001"
app: api
status: done
priority: high
complexity: M
github_issue: null
dependencies: ["TASK-API-001"]
assigned_to: null
---

# TASK-API-002: PostgreSQL schema: accounts, sessions, OTP, audit

> **Milestone:** [M001 — Foundation & Auth System](../../milestones/M001-foundation-auth-system.md)  
> **PRD Reference:** [REQ-BG-001](../../apps/api/PRD.md#req-bg-001--village-data-isolation)  
> **Design Doc:** [docs/design/01-auth-flow.md](../../design/01-auth-flow.md)

---

## Objective

Create the PostgreSQL database migrations (`.up.sql` and `.down.sql`) and Go repository models for the core authentication tables: `accounts`, `sessions`, `otp_codes`, and `audit_events`. Ensure tenant data isolation using `village_cluster_id` for cluster-bound roles (`merchant`, `backoffice_admin`), while allowing cluster-independence for `wholesaler`, `courier`, `consumer`, and `superadmin`.

---

## Context

Per `REQ-BG-001`, data belonging to one village cluster must never be mixed with another. `village_cluster_id` is embedded in tenant tables and JWT tokens.
Per `ADR-003`, refresh tokens are primarily cached in Redis, but PostgreSQL serves as the persistent sessions store and fallback.

Tables required:
1. `village_clusters`: cluster master table (`id`, `name`, `code`, `status`, `created_at`, `updated_at`).
2. `accounts`: user account table (`id`, `village_cluster_id`, `phone`, `email`, `password_hash`, `role`, `status`, `created_at`, `updated_at`).
3. `sessions`: user session refresh tokens persistent backup (`id`, `account_id`, `refresh_token_hash`, `user_agent`, `ip_address`, `expires_at`, `revoked_at`, `created_at`).
4. `otp_codes`: OTP codes for phone auth (`id`, `phone`, `code_hash`, `purpose`, `expires_at`, `verified_at`, `attempts`, `created_at`).
5. `audit_events`: audit trail for auth & administrative actions (`id`, `village_cluster_id`, `account_id`, `action`, `metadata`, `ip_address`, `created_at`).

---

## Acceptance Criteria

- [x] Migration files placed in `apps/api/migrations/000001_create_auth_tables.up.sql` and `000001_create_auth_tables.down.sql`.
- [x] Table `village_clusters` created with UUID primary key.
- [x] Table `accounts` created with foreign key to `village_clusters(id)` (nullable for system superadmins, wholesalers, couriers, consumers), unique constraints on `phone` and `email`, check constraints for role, status, and cluster binding rules.
- [x] Table `sessions` created with FK to `accounts(id)`, index on `refresh_token_hash` and `expires_at`.
- [x] Table `otp_codes` created with index on `phone` and `expires_at`.
- [x] Table `audit_events` created with `village_cluster_id` and `account_id` FKs.
- [x] Go domain entities and validation rules defined in `apps/api/internal/domain/auth.go`.
- [x] SQL files and domain validation pass unit tests.

---

## Technical Notes

- Use standard PostgreSQL UUID extensions (`gen_random_uuid()`).
- Roles allowed: `'consumer'`, `'merchant'`, `'courier'`, `'wholesaler'`, `'backoffice_admin'`, `'superadmin'`.
- Statuses allowed: `'pending'`, `'active'`, `'suspended'`, `'deactivated'`.
- Use `TIMESTAMPTZ` for all timestamp columns.

---

## Definition of Done

- [x] `.up.sql` and `.down.sql` migration scripts written and verified
- [x] Go schema models / types defined in `apps/api/internal/domain`
- [x] `TASK-INDEX.md` status updated to `done`
- [x] Tests verifying SQL syntax / Go struct mappings pass clean

