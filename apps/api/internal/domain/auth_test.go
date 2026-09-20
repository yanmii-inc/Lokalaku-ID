package domain_test

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

func TestRoleValidation(t *testing.T) {
	validRoles := []domain.Role{
		domain.RoleConsumer,
		domain.RoleMerchant,
		domain.RoleCourier,
		domain.RoleWholesaler,
		domain.RoleBackofficeAdmin,
		domain.RoleSuperadmin,
	}

	for _, r := range validRoles {
		if !r.IsValid() {
			t.Errorf("expected role %s to be valid", r)
		}
	}

	invalidRole := domain.Role("unknown_role")
	if invalidRole.IsValid() {
		t.Errorf("expected invalid role to fail IsValid()")
	}

	// Cluster binding checks
	if !domain.RoleMerchant.IsClusterBound() {
		t.Errorf("expected merchant role to be cluster bound")
	}

	if !domain.RoleBackofficeAdmin.IsClusterBound() {
		t.Errorf("expected backoffice_admin role to be cluster bound")
	}

	if domain.RoleCourier.IsClusterBound() {
		t.Errorf("expected courier role to NOT be cluster bound")
	}

	if domain.RoleWholesaler.IsClusterBound() {
		t.Errorf("expected wholesaler role to NOT be cluster bound")
	}
}

func TestAccountValidation(t *testing.T) {
	clusterID := "cluster-uuid-123"

	// Valid Merchant with cluster
	merchantAcc := domain.Account{
		Phone:            "+628123456789",
		Role:             domain.RoleMerchant,
		Status:           domain.StatusActive,
		VillageClusterID: &clusterID,
	}
	if err := merchantAcc.Validate(); err != nil {
		t.Fatalf("expected valid merchant account to pass validation, got: %v", err)
	}

	// Merchant without cluster should fail
	invalidMerchant := domain.Account{
		Phone:  "+628123456789",
		Role:   domain.RoleMerchant,
		Status: domain.StatusActive,
	}
	if err := invalidMerchant.Validate(); err == nil {
		t.Errorf("expected merchant without cluster to fail validation")
	}

	// Wholesaler without cluster should pass (cluster-independent)
	wholesalerAcc := domain.Account{
		Phone:  "+628123456789",
		Role:   domain.RoleWholesaler,
		Status: domain.StatusActive,
	}
	if err := wholesalerAcc.Validate(); err != nil {
		t.Errorf("expected wholesaler without cluster to pass validation, got: %v", err)
	}

	// Courier without cluster should pass (cluster-independent)
	courierAcc := domain.Account{
		Phone:  "+628123456789",
		Role:   domain.RoleCourier,
		Status: domain.StatusActive,
	}
	if err := courierAcc.Validate(); err != nil {
		t.Errorf("expected courier without cluster to pass validation, got: %v", err)
	}

	// Missing phone number
	noPhoneAcc := domain.Account{
		Role:   domain.RoleConsumer,
		Status: domain.StatusActive,
	}
	if err := noPhoneAcc.Validate(); err == nil {
		t.Errorf("expected missing phone account to fail validation")
	}
}

func TestSessionIsActive(t *testing.T) {
	now := time.Now()

	activeSession := domain.Session{
		ExpiresAt: now.Add(15 * time.Minute),
	}
	if !activeSession.IsActive() {
		t.Errorf("expected unexpired, unrevoked session to be active")
	}

	expiredSession := domain.Session{
		ExpiresAt: now.Add(-5 * time.Minute),
	}
	if expiredSession.IsActive() {
		t.Errorf("expected expired session to NOT be active")
	}

	revokedAt := now.Add(-1 * time.Minute)
	revokedSession := domain.Session{
		ExpiresAt: now.Add(15 * time.Minute),
		RevokedAt: &revokedAt,
	}
	if revokedSession.IsActive() {
		t.Errorf("expected revoked session to NOT be active")
	}
}

func TestMigrationFilesExist(t *testing.T) {
	migrationDir := filepath.Join("..", "..", "migrations")

	upPath := filepath.Join(migrationDir, "000001_create_auth_tables.up.sql")
	if _, err := os.Stat(upPath); os.IsNotExist(err) {
		t.Fatalf("expected up migration file at %s", upPath)
	}

	downPath := filepath.Join(migrationDir, "000001_create_auth_tables.down.sql")
	if _, err := os.Stat(downPath); os.IsNotExist(err) {
		t.Fatalf("expected down migration file at %s", downPath)
	}
}
