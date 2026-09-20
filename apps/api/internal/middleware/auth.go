package middleware

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/auth"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

type contextKey struct {
	name string
}

var claimsKey = &contextKey{name: "user_claims"}

// WithClaims stores claims in context.
func WithClaims(ctx context.Context, claims *auth.Claims) context.Context {
	return context.WithValue(ctx, claimsKey, claims)
}

// GetClaims retrieves Claims from context if present.
func GetClaims(ctx context.Context) (*auth.Claims, bool) {
	claims, ok := ctx.Value(claimsKey).(*auth.Claims)
	return claims, ok
}

// GetAccountID returns the authenticated user's account ID (sub).
func GetAccountID(ctx context.Context) (string, bool) {
	claims, ok := GetClaims(ctx)
	if !ok || claims == nil {
		return "", false
	}
	return claims.Subject, true
}

// GetRole returns the authenticated user's role.
func GetRole(ctx context.Context) (domain.Role, bool) {
	claims, ok := GetClaims(ctx)
	if !ok || claims == nil {
		return "", false
	}
	return claims.Role, true
}

// GetClusterID returns the authenticated user's village_cluster_id.
func GetClusterID(ctx context.Context) (*string, bool) {
	claims, ok := GetClaims(ctx)
	if !ok || claims == nil {
		return nil, false
	}
	return claims.VillageClusterID, true
}

func writeAuthError(w http.ResponseWriter, status int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

// RequireAuth validates the Authorization: Bearer <token> header and injects claims into context.
func RequireAuth(tokens *auth.TokenService) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				writeAuthError(w, http.StatusUnauthorized, "missing authorization header")
				return
			}

			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				writeAuthError(w, http.StatusUnauthorized, "invalid authorization header format")
				return
			}

			tokenStr := strings.TrimSpace(parts[1])
			claims, err := tokens.ValidateAccessToken(tokenStr)
			if err != nil {
				writeAuthError(w, http.StatusUnauthorized, "invalid or expired token")
				return
			}

			ctx := WithClaims(r.Context(), claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireRole enforces role-based access control against the context claims.
func RequireRole(allowedRoles ...domain.Role) func(http.Handler) http.Handler {
	allowed := make(map[domain.Role]struct{}, len(allowedRoles))
	for _, r := range allowedRoles {
		allowed[r] = struct{}{}
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role, ok := GetRole(r.Context())
			if !ok {
				writeAuthError(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			if _, exists := allowed[role]; !exists {
				writeAuthError(w, http.StatusForbidden, "insufficient permissions")
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// RequireActiveAccount rejects requests whose JWT status claim is not "active".
// It must be applied after RequireAuth (which validates the token and injects claims).
// Using the claim avoids a database round-trip on every request; the status is
// refreshed when the client exchanges a refresh token for a new access token.
func RequireActiveAccount(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := GetClaims(r.Context())
		if !ok || claims == nil {
			writeAuthError(w, http.StatusUnauthorized, "unauthorized")
			return
		}

		if claims.Status != domain.StatusActive {
			writeAuthError(w, http.StatusForbidden, "account is not active")
			return
		}

		next.ServeHTTP(w, r)
	})
}

