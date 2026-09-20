package domain_test

import (
	"errors"
	"testing"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

// ── CanTransition ─────────────────────────────────────────────────────────────

func TestCanTransition_LegalEdges(t *testing.T) {
	legal := []struct {
		from domain.AccountStatus
		to   domain.AccountStatus
	}{
		{domain.StatusPending, domain.StatusActive},
		{domain.StatusPending, domain.StatusDeactivated},
		{domain.StatusActive, domain.StatusSuspended},
		{domain.StatusActive, domain.StatusDeactivated},
		{domain.StatusSuspended, domain.StatusActive},
		{domain.StatusSuspended, domain.StatusDeactivated},
	}

	for _, tc := range legal {
		if !domain.CanTransition(tc.from, tc.to) {
			t.Errorf("expected %q → %q to be legal", tc.from, tc.to)
		}
	}
}

func TestCanTransition_IllegalEdges(t *testing.T) {
	illegal := []struct {
		from domain.AccountStatus
		to   domain.AccountStatus
	}{
		// Self-transitions
		{domain.StatusPending, domain.StatusPending},
		{domain.StatusActive, domain.StatusActive},
		{domain.StatusSuspended, domain.StatusSuspended},
		{domain.StatusDeactivated, domain.StatusDeactivated},

		// Terminal state — no transitions out of deactivated
		{domain.StatusDeactivated, domain.StatusPending},
		{domain.StatusDeactivated, domain.StatusActive},
		{domain.StatusDeactivated, domain.StatusSuspended},

		// Skipped edges
		{domain.StatusPending, domain.StatusSuspended},   // pending cannot go straight to suspended
		{domain.StatusSuspended, domain.StatusPending},   // cannot revert to pending
		{domain.StatusActive, domain.StatusPending},      // cannot revert to pending
	}

	for _, tc := range illegal {
		if domain.CanTransition(tc.from, tc.to) {
			t.Errorf("expected %q → %q to be illegal, but CanTransition returned true", tc.from, tc.to)
		}
	}
}

// ── TransitionStatus ──────────────────────────────────────────────────────────

func TestTransitionStatus_LegalTransitions(t *testing.T) {
	cases := []struct {
		from domain.AccountStatus
		to   domain.AccountStatus
	}{
		{domain.StatusPending, domain.StatusActive},
		{domain.StatusActive, domain.StatusSuspended},
		{domain.StatusSuspended, domain.StatusActive},
		{domain.StatusActive, domain.StatusDeactivated},
		{domain.StatusSuspended, domain.StatusDeactivated},
		{domain.StatusPending, domain.StatusDeactivated},
	}

	for _, tc := range cases {
		got, err := domain.TransitionStatus(tc.from, tc.to)
		if err != nil {
			t.Errorf("%q → %q: unexpected error: %v", tc.from, tc.to, err)
			continue
		}
		if got != tc.to {
			t.Errorf("%q → %q: expected new status %q, got %q", tc.from, tc.to, tc.to, got)
		}
	}
}

func TestTransitionStatus_IllegalTransitions(t *testing.T) {
	cases := []struct {
		from domain.AccountStatus
		to   domain.AccountStatus
	}{
		{domain.StatusDeactivated, domain.StatusActive},
		{domain.StatusDeactivated, domain.StatusPending},
		{domain.StatusPending, domain.StatusSuspended},
		{domain.StatusSuspended, domain.StatusPending},
		{domain.StatusActive, domain.StatusPending},
	}

	for _, tc := range cases {
		got, err := domain.TransitionStatus(tc.from, tc.to)
		if err == nil {
			t.Errorf("%q → %q: expected error, got nil (new status: %q)", tc.from, tc.to, got)
			continue
		}
		if !errors.Is(err, domain.ErrIllegalStatusTransition) {
			t.Errorf("%q → %q: expected ErrIllegalStatusTransition, got: %v", tc.from, tc.to, err)
		}
		// Original status must be returned unchanged on error
		if got != tc.from {
			t.Errorf("%q → %q: expected original status %q on error, got %q", tc.from, tc.to, tc.from, got)
		}
	}
}

func TestTransitionStatus_UnknownTargetStatus(t *testing.T) {
	_, err := domain.TransitionStatus(domain.StatusActive, domain.AccountStatus("unknown_state"))
	if err == nil {
		t.Fatal("expected error for unknown target status, got nil")
	}
	if !errors.Is(err, domain.ErrIllegalStatusTransition) {
		t.Errorf("expected ErrIllegalStatusTransition, got: %v", err)
	}
}

// ── Terminal state completeness ────────────────────────────────────────────────

func TestDeactivated_IsTerminal(t *testing.T) {
	// All statuses must be rejected as targets from deactivated
	all := []domain.AccountStatus{
		domain.StatusPending,
		domain.StatusActive,
		domain.StatusSuspended,
		domain.StatusDeactivated,
	}

	for _, target := range all {
		if domain.CanTransition(domain.StatusDeactivated, target) {
			t.Errorf("deactivated should be a terminal state, but CanTransition(deactivated, %q) returned true", target)
		}
	}
}
