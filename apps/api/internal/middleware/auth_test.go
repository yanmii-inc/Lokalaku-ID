package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/auth"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/middleware"
)

func TestRequireAuthMiddleware(t *testing.T) {
	secret := "test-secret-key-32-bytes-long-12"
	tokenSvc := auth.NewTokenService(secret, 15*time.Minute, 24*time.Hour)

	clusterID := "cluster-999"
	account := domain.Account{
		ID:               "acc-123",
		Role:             domain.RoleWholesaler,
		Status:           domain.StatusActive,
		VillageClusterID: &clusterID,
	}
	validToken, _ := tokenSvc.GenerateAccessToken(&account)

	handler := middleware.RequireAuth(tokenSvc)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := middleware.GetClaims(r.Context())
		if !ok || claims.Subject != "acc-123" {
			t.Errorf("failed to retrieve expected claims in handler")
		}
		w.WriteHeader(http.StatusOK)
	}))

	// Case 1: Missing header
	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 on missing auth header, got %d", rec.Code)
	}

	// Case 2: Invalid format
	req = httptest.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "InvalidFormat")
	rec = httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 on invalid header format, got %d", rec.Code)
	}

	// Case 3: Invalid token
	req = httptest.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer invalid.jwt.token")
	rec = httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 on invalid token, got %d", rec.Code)
	}

	// Case 4: Valid token
	req = httptest.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+validToken)
	rec = httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Errorf("expected 200 on valid token, got %d", rec.Code)
	}
}

func TestRequireRoleMiddleware(t *testing.T) {
	secret := "test-secret-key-32-bytes-long-12"
	tokenSvc := auth.NewTokenService(secret, 15*time.Minute, 24*time.Hour)

	merchantAcc := domain.Account{
		ID:     "acc-merchant",
		Role:   domain.RoleMerchant,
		Status: domain.StatusActive,
	}
	merchantToken, _ := tokenSvc.GenerateAccessToken(&merchantAcc)

	courierAcc := domain.Account{
		ID:     "acc-courier",
		Role:   domain.RoleCourier,
		Status: domain.StatusActive,
	}
	courierToken, _ := tokenSvc.GenerateAccessToken(&courierAcc)

	// Route requiring RoleMerchant or RoleSuperadmin
	handler := middleware.RequireAuth(tokenSvc)(
		middleware.RequireRole(domain.RoleMerchant, domain.RoleSuperadmin)(
			http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
			}),
		),
	)

	// Merchant allowed
	req := httptest.NewRequest(http.MethodGet, "/merchant-only", nil)
	req.Header.Set("Authorization", "Bearer "+merchantToken)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Errorf("expected 200 for merchant, got %d", rec.Code)
	}

// Courier forbidden
	req = httptest.NewRequest(http.MethodGet, "/merchant-only", nil)
	req.Header.Set("Authorization", "Bearer "+courierToken)
	rec = httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 for courier, got %d", rec.Code)
	}
}

func TestRequireActiveAccountMiddleware(t *testing.T) {
	secret := "test-secret-key-32-bytes-long-12"
	tokenSvc := auth.NewTokenService(secret, 15*time.Minute, 24*time.Hour)

	okHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	makeToken := func(status domain.AccountStatus) string {
		acc := domain.Account{
			ID:     "acc-state-test",
			Role:   domain.RoleMerchant,
			Status: status,
		}
		tok, _ := tokenSvc.GenerateAccessToken(&acc)
		return tok
	}

	chain := func(tok string) *httptest.ResponseRecorder {
		h := middleware.RequireAuth(tokenSvc)(
			middleware.RequireActiveAccount(okHandler),
		)
		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec
	}

	// Active account → allowed
	if rec := chain(makeToken(domain.StatusActive)); rec.Code != http.StatusOK {
		t.Errorf("active: expected 200, got %d", rec.Code)
	}

	// Suspended account → 403
	if rec := chain(makeToken(domain.StatusSuspended)); rec.Code != http.StatusForbidden {
		t.Errorf("suspended: expected 403, got %d", rec.Code)
	}

	// Pending account → 403
	if rec := chain(makeToken(domain.StatusPending)); rec.Code != http.StatusForbidden {
		t.Errorf("pending: expected 403, got %d", rec.Code)
	}

	// Deactivated account → 403
	if rec := chain(makeToken(domain.StatusDeactivated)); rec.Code != http.StatusForbidden {
		t.Errorf("deactivated: expected 403, got %d", rec.Code)
	}

	// No auth header at all → 401 (RequireAuth fires first)
	h := middleware.RequireAuth(tokenSvc)(
		middleware.RequireActiveAccount(okHandler),
	)
	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("no-auth: expected 401, got %d", rec.Code)
	}
}

