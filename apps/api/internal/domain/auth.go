package domain

import (
	"errors"
	"fmt"
	"time"
)

// Role defines the account role within the platform.
type Role string

const (
	RoleConsumer        Role = "consumer"
	RoleMerchant        Role = "merchant"
	RoleCourier         Role = "courier"
	RoleWholesaler      Role = "wholesaler"
	RoleBackofficeAdmin Role = "backoffice_admin"
	RoleSuperadmin      Role = "superadmin"
)

// IsValid checks if the role is a recognized role.
func (r Role) IsValid() bool {
	switch r {
	case RoleConsumer, RoleMerchant, RoleCourier, RoleWholesaler, RoleBackofficeAdmin, RoleSuperadmin:
		return true
	default:
		return false
	}
}

// IsClusterBound returns true if the role must be bound to a single village cluster.
func (r Role) IsClusterBound() bool {
	return r == RoleMerchant || r == RoleBackofficeAdmin
}

// AccountStatus defines the lifecycle state of an account.
type AccountStatus string

const (
	StatusPending     AccountStatus = "pending"
	StatusActive      AccountStatus = "active"
	StatusSuspended   AccountStatus = "suspended"
	StatusDeactivated AccountStatus = "deactivated"
)

// IsValid checks if the account status is recognized.
func (s AccountStatus) IsValid() bool {
	switch s {
	case StatusPending, StatusActive, StatusSuspended, StatusDeactivated:
		return true
	default:
		return false
	}
}

// VillageCluster represents a geographically bounded community cluster.
type VillageCluster struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Code      string    `json:"code"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Account represents a user account across all client roles.
type Account struct {
	ID               string        `json:"id"`
	VillageClusterID *string       `json:"village_cluster_id,omitempty"`
	Phone            string        `json:"phone"`
	Email            *string       `json:"email,omitempty"`
	PasswordHash     *string       `json:"-"`
	Role             Role          `json:"role"`
	Status           AccountStatus `json:"status"`
	CreatedAt        time.Time     `json:"created_at"`
	UpdatedAt        time.Time     `json:"updated_at"`
}

// Validate checks entity integrity rules for Account.
func (a *Account) Validate() error {
	if a.Phone == "" {
		return errors.New("phone number is required")
	}

	if !a.Role.IsValid() {
		return fmt.Errorf("invalid role: %s", a.Role)
	}

	if !a.Status.IsValid() {
		return fmt.Errorf("invalid status: %s", a.Status)
	}

	if a.Role.IsClusterBound() && (a.VillageClusterID == nil || *a.VillageClusterID == "") {
		return fmt.Errorf("role '%s' requires a village_cluster_id", a.Role)
	}

	return nil
}

// Session represents a persistent session refresh token record.
type Session struct {
	ID               string     `json:"id"`
	AccountID        string     `json:"account_id"`
	RefreshTokenHash string     `json:"-"`
	UserAgent        *string    `json:"user_agent,omitempty"`
	IPAddress        *string    `json:"ip_address,omitempty"`
	ExpiresAt        time.Time  `json:"expires_at"`
	RevokedAt        *time.Time `json:"revoked_at,omitempty"`
	CreatedAt        time.Time  `json:"created_at"`
}

// IsActive returns true if the session is not expired and not revoked.
func (s *Session) IsActive() bool {
	if s.RevokedAt != nil {
		return false
	}
	return time.Now().Before(s.ExpiresAt)
}

// OTPCode represents a one-time password issuance for phone verification.
type OTPCode struct {
	ID         string     `json:"id"`
	Phone      string     `json:"phone"`
	CodeHash   string     `json:"-"`
	Purpose    string     `json:"purpose"`
	Attempts   int        `json:"attempts"`
	ExpiresAt  time.Time  `json:"expires_at"`
	VerifiedAt *time.Time `json:"verified_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
}

// IsExpired checks if the OTP code has passed its lifetime.
func (o *OTPCode) IsExpired() bool {
	return time.Now().After(o.ExpiresAt)
}

// AuditEvent represents an immutable log of state changes or auth actions.
type AuditEvent struct {
	ID               string         `json:"id"`
	VillageClusterID *string        `json:"village_cluster_id,omitempty"`
	AccountID        *string        `json:"account_id,omitempty"`
	Action           string         `json:"action"`
	Metadata         map[string]any `json:"metadata,omitempty"`
	IPAddress        *string        `json:"ip_address,omitempty"`
	CreatedAt        time.Time      `json:"created_at"`
}

// ─── Account Status State Machine ─────────────────────────────────────────────
//
// Legal transitions (REQ-BG-005):
//
//	pending     → active       (admin activates after verification)
//	pending     → deactivated  (admin rejects/purges unverified account)
//	active      → suspended    (admin suspends for review)
//	active      → deactivated  (admin permanently closes account)
//	suspended   → active       (admin reinstates after review)
//	suspended   → deactivated  (admin permanently closes suspended account)
//	deactivated → (none)       terminal state — no further transitions allowed
var accountStatusTransitions = map[AccountStatus][]AccountStatus{
	StatusPending:     {StatusActive, StatusDeactivated},
	StatusActive:      {StatusSuspended, StatusDeactivated},
	StatusSuspended:   {StatusActive, StatusDeactivated},
	StatusDeactivated: {},
}

// ErrIllegalStatusTransition is returned when a status change violates the state machine.
var ErrIllegalStatusTransition = errors.New("illegal account status transition")

// CanTransition reports whether moving from current to next is a legal edge.
func CanTransition(current, next AccountStatus) bool {
	allowed, ok := accountStatusTransitions[current]
	if !ok {
		return false
	}
	for _, s := range allowed {
		if s == next {
			return true
		}
	}
	return false
}

// TransitionStatus validates the requested status change and returns the new status.
// Returns ErrIllegalStatusTransition when the edge is not in the state machine.
func TransitionStatus(current, next AccountStatus) (AccountStatus, error) {
	if !next.IsValid() {
		return current, fmt.Errorf("unknown target status %q: %w", next, ErrIllegalStatusTransition)
	}
	if !CanTransition(current, next) {
		return current, fmt.Errorf(
			"cannot transition account from %q to %q: %w",
			current, next, ErrIllegalStatusTransition,
		)
	}
	return next, nil
}

