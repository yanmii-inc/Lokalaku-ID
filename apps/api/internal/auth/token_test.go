package auth_test

import (
	"testing"
	"time"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/auth"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

func TestTokenService(t *testing.T) {
	secret := "my-secret-key-32-bytes-long-super"
	tokenSvc := auth.NewTokenService(secret, 1*time.Minute, 1*time.Hour)

	clusterID := "cluster-123"
	account := domain.Account{
		ID:               "acc-001",
		Role:             domain.RoleCourier,
		Status:           domain.StatusActive,
		VillageClusterID: &clusterID,
	}

	// 1. Generate access token
	tokenStr, err := tokenSvc.GenerateAccessToken(&account)
	if err != nil {
		t.Fatalf("failed to generate access token: %v", err)
	}

	// 2. Validate token
	claims, err := tokenSvc.ValidateAccessToken(tokenStr)
	if err != nil {
		t.Fatalf("failed to validate valid access token: %v", err)
	}

	if claims.Subject != account.ID {
		t.Errorf("expected subject %s, got %s", account.ID, claims.Subject)
	}
	if claims.Role != domain.RoleCourier {
		t.Errorf("expected role courier, got %s", claims.Role)
	}
	if claims.VillageClusterID == nil || *claims.VillageClusterID != clusterID {
		t.Errorf("expected cluster ID %s", clusterID)
	}
	if claims.Status != domain.StatusActive {
		t.Errorf("expected status active, got %s", claims.Status)
	}

	// 3. Test tampering
	tamperedToken := tokenStr + "tampered"
	if _, err := tokenSvc.ValidateAccessToken(tamperedToken); err == nil {
		t.Errorf("expected tampered token to fail validation")
	}

	// 4. Test wrong secret
	otherSvc := auth.NewTokenService("other-secret-key-32-bytes-long!", 1*time.Minute, 1*time.Hour)
	if _, err := otherSvc.ValidateAccessToken(tokenStr); err == nil {
		t.Errorf("expected token validated with different secret to fail")
	}

	// 5. Test expired token
	expiredSvc := auth.NewTokenService(secret, -1*time.Minute, 1*time.Hour)
	expiredToken, err := expiredSvc.GenerateAccessToken(&account)
	if err != nil {
		t.Fatalf("failed to generate token: %v", err)
	}
	if _, err := tokenSvc.ValidateAccessToken(expiredToken); err == nil {
		t.Errorf("expected expired token to fail validation")
	}

	// 6. Test Refresh Token generation and hashing
	raw1, hash1, err := tokenSvc.GenerateRefreshToken()
	if err != nil {
		t.Fatalf("failed to generate refresh token: %v", err)
	}
	if raw1 == "" || hash1 == "" {
		t.Fatalf("expected non-empty refresh token and hash")
	}
	if auth.HashToken(raw1) != hash1 {
		t.Errorf("expected hash to match HashToken(raw)")
	}

	raw2, hash2, _ := tokenSvc.GenerateRefreshToken()
	if raw1 == raw2 || hash1 == hash2 {
		t.Errorf("expected distinct random refresh tokens")
	}
}
