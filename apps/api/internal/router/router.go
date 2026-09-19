package router

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/auth"
	custommiddleware "github.com/yanmii-inc/lokalaku/apps/api/internal/middleware"
)

// HealthResponse represents the payload returned by the /health endpoint.
type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version"`
}

// New creates and configures the main Chi router with mounted middleware and routes.
func New(logger *slog.Logger, authService *auth.Service, tokenService *auth.TokenService, otpService *auth.OTPService) chi.Router {
	r := chi.NewRouter()

	r.Use(chimiddleware.Recoverer)
	if logger != nil {
		r.Use(custommiddleware.Logger(logger))
	}

	r.Get("/health", handleHealth)

	// Auth routes
	if authService != nil {
		authHandler := auth.NewHandler(authService, otpService)

		r.Route("/auth", func(r chi.Router) {
			r.Post("/login", authHandler.HandleLogin)
			r.Post("/refresh", authHandler.HandleRefresh)
			r.Post("/logout", authHandler.HandleLogout)

			// OTP phone-based auth
			r.Post("/otp/request", authHandler.HandleOTPRequest)
			r.Post("/otp/verify", authHandler.HandleOTPVerify)

			if tokenService != nil {
				r.Group(func(r chi.Router) {
					r.Use(custommiddleware.RequireAuth(tokenService))
					r.Get("/me", handleMe)
				})
			}
		})
	}

	return r
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	res := HealthResponse{
		Status:  "ok",
		Version: "dev",
	}

	_ = json.NewEncoder(w).Encode(res)
}

func handleMe(w http.ResponseWriter, r *http.Request) {
	claims, ok := custommiddleware.GetClaims(r.Context())
	if !ok {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(map[string]string{"error": "unauthorized"})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"account_id":         claims.Subject,
		"role":               claims.Role,
		"village_cluster_id": claims.VillageClusterID,
		"status":             claims.Status,
	})
}
