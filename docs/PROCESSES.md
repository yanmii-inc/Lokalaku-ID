# Business Processes

## Pool Buying (Hulu Engine)

The cornerstone of Lokalaku's supply chain efficiency. Small village stores cannot afford factory-direct wholesale pricing individually due to high MOQs. The system aggregates separate store orders into a singular `Pool_Order`.

### State Machine

```
open ──► locked_ready ──► fulfilled
  └──────────────────────► cancelled
```

| State | Meaning |
|:---|:---|
| `open` | Any merchant in the cluster can commit quantities. Pool accumulates `committed_qty`. |
| `locked_ready` | `committed_qty >= target_qty` (wholesaler MOQ). No new commitments. Fulfillment begins. |
| `fulfilled` | Courier delivers the batch. Merchant POS stock is updated. |
| `cancelled` | Wholesaler cancels with written reason. All merchants are notified. |

### How It Works

```
  Merchants individually commit stock quantities to an open Pool Order
                              │
                    ┌─────────▼─────────┐
                    │     Pool: OPEN     │  ← any merchant can commit
                    └─────────┬─────────┘
                              │  accumulated_qty >= wholesaler MOQ
                    ┌─────────▼─────────┐
                    │  Pool: LOCKED /   │  ← factory pricing unlocks
                    │  READY TO FULFIL  │     courier job created
                    └─────────┬─────────┘
                              │  courier delivers batch
                    ┌─────────▼─────────┐
                    │  Pool: FULFILLED  │  ← merchant POS stock updated
                    └───────────────────┘
                    (or CANCELLED with written reason to all merchants)
```

State transitions are **atomic ACID transactions** — no race conditions, no double-counting, even under simultaneous peak commits.

### Pool Commitment

One Merchant's individual pledge within an open Pool Order. Records the merchant's intended quantity and timestamp. A commitment cannot be unilaterally withdrawn once the pool reaches `locked_ready`.

---

## Proximity Retail (Hilir Engine)

### Consumer Discovery
- Retail item listings are explicitly decentralized
- Consumers view what's available in their geographic vicinity
- Stores are discovered by **GPS proximity**, not cluster boundaries
- A consumer near a village border can see merchants from neighboring clusters

### Merchant POS
- Lightweight, fast Point-of-Sale interface for over-the-counter transactions
- Inventory deductions committed to local storage immediately
- Background sync to backend when network is available
- Maintains accurate local item indexes even when offline

### Courier Dispatch
- Courier claims pool-order batch deliveries
- Streams GPS telemetry during delivery
- Marks stops as complete on arrival
- All courier operations work offline-first

---

## Authentication & Account Lifecycle

### Login Flow
1. User provides credentials (phone + password, or OTP)
2. API issues short-lived JWT (15 min) + opaque refresh token (30 days)
3. Refresh token stored in Redis, rotated on every use
4. Tokens invalidated on logout or password reset

### OTP Verification
- 6-digit code, valid 5 minutes
- Rate-limited: 3 requests per phone number per 10 minutes
- Invalidated after first use

### Account States (Non-Consumer)
```
pending_approval → active → suspended
```
- `pending_approval`: Account created, awaiting verification
- `active`: Full access
- `suspended`: Access revoked by superadmin
