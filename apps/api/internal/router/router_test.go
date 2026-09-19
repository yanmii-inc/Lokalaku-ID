package router_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/auth"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/router"
)

func TestHealthEndpoint(t *testing.T) {
	r := router.New(nil, nil, nil, nil)

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rec.Code)
	}

	contentType := rec.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", contentType)
	}

	var res router.HealthResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
		t.Fatalf("failed to decode response JSON: %v", err)
	}

	if res.Status != "ok" {
		t.Errorf("expected status 'ok', got '%s'", res.Status)
	}

	if res.Version != "dev" {
		t.Errorf("expected version 'dev', got '%s'", res.Version)
	}
}

func TestAuthEndToEnd(t *testing.T) {
	ctx := context.Background()
	tokenSvc := auth.NewTokenService("test-secret-32-bytes-long-key-lokalaku", 15*time.Minute, 24*time.Hour)
	accountRepo := auth.NewMemoryAccountRepo()
	sessionStore := auth.NewMemorySessionStore()
	authSvc := auth.NewService(tokenSvc, accountRepo, sessionStore)

	// Create a test account with hashed password
	password := "SecretPass123!"
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		t.Fatalf("failed to hash password: %v", err)
	}
	hashStr := string(hashed)

	clusterID := "cluster-uuid-456"
	email := "merchant@lokalaku.id"
	testAccount := domain.Account{
		ID:               "acc_merchant_1",
		Phone:            "+6281234567890",
		Email:            &email,
		PasswordHash:     &hashStr,
		Role:             domain.RoleMerchant,
		Status:           domain.StatusActive,
		VillageClusterID: &clusterID,
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}
	if err := accountRepo.Create(ctx, &testAccount); err != nil {
		t.Fatalf("failed to create account: %v", err)
	}

	r := router.New(nil, authSvc, tokenSvc, nil)

	// 1. Test Login
	loginBody, _ := json.Marshal(map[string]string{
		"identifier": "+6281234567890",
		"password":   password,
	})
	loginReq := httptest.NewRequest(http.MethodPost, "/auth/login", bytes.NewReader(loginBody))
	loginRec := httptest.NewRecorder()
	r.ServeHTTP(loginRec, loginReq)

	if loginRec.Code != http.StatusOK {
		t.Fatalf("login failed: expected 200, got %d: %s", loginRec.Code, loginRec.Body.String())
	}

	var tokenRes auth.TokenPairResponse
	if err := json.Unmarshal(loginRec.Body.Bytes(), &tokenRes); err != nil {
		t.Fatalf("failed to unmarshal token response: %v", err)
	}

	if tokenRes.AccessToken == "" || tokenRes.RefreshToken == "" {
		t.Fatalf("expected both access_token and refresh_token")
	}

	// 2. Test Protected /auth/me with access token
	meReq := httptest.NewRequest(http.MethodGet, "/auth/me", nil)
	meReq.Header.Set("Authorization", "Bearer "+tokenRes.AccessToken)
	meRec := httptest.NewRecorder()
	r.ServeHTTP(meRec, meReq)

	if meRec.Code != http.StatusOK {
		t.Fatalf("/auth/me failed: expected 200, got %d: %s", meRec.Code, meRec.Body.String())
	}

	var meRes map[string]any
	if err := json.Unmarshal(meRec.Body.Bytes(), &meRes); err != nil {
		t.Fatalf("failed to unmarshal /auth/me response: %v", err)
	}

	if meRes["account_id"] != "acc_merchant_1" {
		t.Errorf("expected account_id acc_merchant_1, got %v", meRes["account_id"])
	}
	if meRes["role"] != string(domain.RoleMerchant) {
		t.Errorf("expected role merchant, got %v", meRes["role"])
	}
	if meRes["village_cluster_id"] != clusterID {
		t.Errorf("expected village_cluster_id %s, got %v", clusterID, meRes["village_cluster_id"])
	}

	// 3. Test Refresh Token (Rotation)
	refreshBody, _ := json.Marshal(map[string]string{
		"refresh_token": tokenRes.RefreshToken,
	})
	refreshReq := httptest.NewRequest(http.MethodPost, "/auth/refresh", bytes.NewReader(refreshBody))
	refreshRec := httptest.NewRecorder()
	r.ServeHTTP(refreshRec, refreshReq)

	if refreshRec.Code != http.StatusOK {
		t.Fatalf("refresh failed: expected 200, got %d: %s", refreshRec.Code, refreshRec.Body.String())
	}

	var rotatedRes auth.TokenPairResponse
	if err := json.Unmarshal(refreshRec.Body.Bytes(), &rotatedRes); err != nil {
		t.Fatalf("failed to unmarshal rotated tokens: %v", err)
	}

	if rotatedRes.AccessToken == "" || rotatedRes.RefreshToken == "" {
		t.Fatalf("expected new tokens on refresh")
	}
	if rotatedRes.RefreshToken == tokenRes.RefreshToken {
		t.Fatalf("expected refresh token to be rotated, but got same token")
	}

	// 4. Test Single-Use Rotation Guarantee: Old refresh token must now be rejected
	reuseReq := httptest.NewRequest(http.MethodPost, "/auth/refresh", bytes.NewReader(refreshBody))
	reuseRec := httptest.NewRecorder()
	r.ServeHTTP(reuseRec, reuseReq)

	if reuseRec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 when reusing old refresh token, got %d", reuseRec.Code)
	}

	// 5. Test Logout with the new rotated refresh token
	logoutBody, _ := json.Marshal(map[string]string{
		"refresh_token": rotatedRes.RefreshToken,
	})
	logoutReq := httptest.NewRequest(http.MethodPost, "/auth/logout", bytes.NewReader(logoutBody))
	logoutRec := httptest.NewRecorder()
	r.ServeHTTP(logoutRec, logoutReq)

	if logoutRec.Code != http.StatusOK {
		t.Fatalf("logout failed: expected 200, got %d", logoutRec.Code)
	}

	// 6. Test Refresh with logged-out token -> must fail
	postLogoutRefreshReq := httptest.NewRequest(http.MethodPost, "/auth/refresh", bytes.NewReader(logoutBody))
	postLogoutRefreshRec := httptest.NewRecorder()
	r.ServeHTTP(postLogoutRefreshRec, postLogoutRefreshReq)

	if postLogoutRefreshRec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 when using revoked refresh token, got %d", postLogoutRefreshRec.Code)
	}
}
