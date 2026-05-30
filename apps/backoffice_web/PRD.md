# 📋 PRD: backoffice_web — Platform Superadmin Dashboard

> **Scope:** This document covers only the `backoffice_web` sub-project.
> For ecosystem-wide context, refer to the root [`/PRD.md`](../../PRD.md).

---

## 1. Role & Purpose

| Attribute | Detail |
| :--- | :--- |
| **Target Users** | Lokalaku platform operators and superadmins — the team running the Lokalaku ecosystem itself |
| **Primary Platform** | Web browser — desktop-first |
| **Core Function** | Village cluster setup, wholesaler verification, platform-wide oversight, and system configuration |

This dashboard is the **control centre for Lokalaku as a platform**. It is not used by merchants, couriers, wholesalers, or consumers. Its audience is the small internal team responsible for onboarding new villages, approving suppliers, and maintaining the health of the overall ecosystem.

---

## 2. User Stories

| ID | As a… | I want to… | So that… |
| :--- | :--- | :--- | :--- |
| US-SA-01 | Superadmin | Create and configure a new village cluster | A new village community can start using the platform |
| US-SA-02 | Superadmin | Review and approve wholesaler registration requests | Only verified, legitimate suppliers enter the marketplace |
| US-SA-03 | Superadmin | Assign or revoke which village clusters a wholesaler can supply | Supply relationships are geographically appropriate and controlled |
| US-SA-04 | Superadmin | Suspend or permanently deactivate any user account across all roles | Bad actors can be removed quickly without affecting other users |
| US-SA-05 | Superadmin | View a platform-wide health overview | I can spot problems in any cluster before they escalate |
| US-SA-06 | Superadmin | Manage other superadmin accounts | Access to this dashboard is always tightly controlled |
| US-SA-07 | Superadmin | View an audit trail of all significant actions taken across the platform | Accountability is maintained for every change |

---

## 3. Functional Requirements

### REQ-SA-001 — Village Cluster Management
*   Superadmins can create a new village cluster by defining its name, geographic boundary, and a unique public-facing identifier (used in the public web URLs).
*   Clusters can be set to active, paused, or archived. Pausing a cluster hides it from public discovery without deleting its data.
*   Each cluster has a designated contact (e.g. a local coordinator) whose details can be recorded.

### REQ-SA-002 — Wholesaler Verification & Approval
*   When a wholesaler registers, their account is held in a pending state until a superadmin reviews and approves it.
*   Approval includes verifying business identity and assigning the wholesaler to one or more village clusters they are permitted to supply.
*   A wholesaler can be suspended (temporarily blocked) or rejected (account closed) with a recorded reason.

### REQ-SA-003 — Platform-Wide Account Oversight
*   Superadmins can search for any account across all roles and clusters.
*   Any account can be suspended or deactivated. Superadmin accounts can only be modified by other superadmins.
*   Account changes are logged permanently.

### REQ-SA-004 — Platform Health Dashboard
*   A top-level dashboard shows ecosystem-wide metrics: total active clusters, total registered accounts by role, open and fulfilled pool orders across all clusters, and any clusters with no activity in the past 30 days.
*   Anomalies (e.g. a cluster with a very high cancellation rate) are surfaced as alerts for superadmin review.

### REQ-SA-005 — System Configuration
*   Superadmins can manage platform-wide settings: default pool order expiry periods, notification templates, and feature flags for enabling or disabling capabilities per cluster.
*   Configuration changes take effect without requiring a platform redeployment.

### REQ-SA-006 — Immutable Audit Log
*   Every action performed within this dashboard — account changes, cluster creation, wholesaler approvals, configuration edits — is permanently recorded with the acting superadmin's identity, timestamp, and a description of what changed.
*   Audit records cannot be edited or deleted by anyone, including superadmins.

---

## 4. Non-Functional Requirements

| Category | Requirement |
| :--- | :--- |
| **Access Control** | Only accounts with the superadmin role can access this dashboard. All other roles are denied entry at the platform level, not just in the UI. |
| **Security** | Superadmin sessions must require recent authentication. Sensitive actions (account deactivation, cluster creation) must prompt for confirmation. |
| **Auditability** | Complete, tamper-proof log of every change. If something goes wrong, the full history of who did what is always available. |
| **Availability** | The dashboard should remain accessible even if individual village clusters are experiencing issues — superadmins need visibility to respond to outages. |

---

## 5. Data Flows

*   Superadmins log in with a dedicated superadmin credential that is separate from all operator-facing roles.
*   Village clusters created here become the geographic and data boundaries within which all other apps operate.
*   Wholesaler approvals made here unlock the wholesaler's access to the `wholesaler_app` dashboard and make their products visible in assigned clusters.
*   Account suspensions made here immediately revoke access across all apps and platforms for the affected account.
*   Platform health metrics are drawn from aggregated, read-only summaries across all clusters — superadmins never directly query or modify raw operational data.

---

## 6. Out of Scope

*   Product catalogue management → `wholesaler_app`
*   Pool order participation → `merchant_app`
*   Delivery management → `courier_app`
*   Consumer ordering → `consumer_app`
*   Public village catalog → `website`
