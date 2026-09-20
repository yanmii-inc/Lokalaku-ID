package auth

import (
	"encoding/json"
	"errors"
	"net/http"
)

// Handler exposes HTTP handlers for authentication.
type Handler struct {
	service    *Service
	otpService *OTPService
}

// NewHandler creates a new auth HTTP Handler.
func NewHandler(service *Service, otpService *OTPService) *Handler {
	return &Handler{
		service:    service,
		otpService: otpService,
	}
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type logoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type otpRequestBody struct {
	Phone   string `json:"phone"`
	Purpose string `json:"purpose"`
}

type otpVerifyBody struct {
	Phone   string `json:"phone"`
	Code    string `json:"code"`
	Purpose string `json:"purpose"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

// HandleLogin processes user login via phone/email and password.
func (h *Handler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "invalid request payload"})
		return
	}

	userAgent := r.UserAgent()
	ip := r.RemoteAddr

	res, err := h.service.Login(r.Context(), req, userAgent, ip)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			writeJSON(w, http.StatusUnauthorized, errorResponse{Error: err.Error()})
			return
		}
		if errors.Is(err, ErrAccountNotActive) {
			writeJSON(w, http.StatusForbidden, errorResponse{Error: err.Error()})
			return
		}
		writeJSON(w, http.StatusInternalServerError, errorResponse{Error: "internal server error"})
		return
	}

	writeJSON(w, http.StatusOK, res)
}

// HandleRefresh validates a refresh token and issues a new access token and rotated refresh token.
func (h *Handler) HandleRefresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "invalid request payload"})
		return
	}

	userAgent := r.UserAgent()
	ip := r.RemoteAddr

	res, err := h.service.Refresh(r.Context(), req.RefreshToken, userAgent, ip)
	if err != nil {
		if errors.Is(err, ErrInvalidRefreshToken) {
			writeJSON(w, http.StatusUnauthorized, errorResponse{Error: err.Error()})
			return
		}
		if errors.Is(err, ErrAccountNotActive) {
			writeJSON(w, http.StatusForbidden, errorResponse{Error: err.Error()})
			return
		}
		writeJSON(w, http.StatusInternalServerError, errorResponse{Error: "internal server error"})
		return
	}

	writeJSON(w, http.StatusOK, res)
}

// HandleLogout invalidates the provided refresh token session.
func (h *Handler) HandleLogout(w http.ResponseWriter, r *http.Request) {
	var req logoutRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	_ = h.service.Logout(r.Context(), req.RefreshToken)

	writeJSON(w, http.StatusOK, map[string]string{"status": "logged_out"})
}

// HandleOTPRequest issues a new 6-digit OTP for the given phone number.
// The plain-text code is logged server-side (dev-mode). Wire an SMS provider here for production.
func (h *Handler) HandleOTPRequest(w http.ResponseWriter, r *http.Request) {
	if h.otpService == nil {
		writeJSON(w, http.StatusNotImplemented, errorResponse{Error: "otp service not configured"})
		return
	}

	var req otpRequestBody
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "invalid request payload"})
		return
	}

	if req.Phone == "" {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "phone is required"})
		return
	}

	res, err := h.otpService.RequestOTP(r.Context(), req.Phone, req.Purpose)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, errorResponse{Error: "failed to issue otp"})
		return
	}

	writeJSON(w, http.StatusAccepted, res)
}

// HandleOTPVerify validates the provided OTP code.
// On success with purpose="auth", returns a token pair if the phone is registered.
func (h *Handler) HandleOTPVerify(w http.ResponseWriter, r *http.Request) {
	if h.otpService == nil {
		writeJSON(w, http.StatusNotImplemented, errorResponse{Error: "otp service not configured"})
		return
	}

	var req otpVerifyBody
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "invalid request payload"})
		return
	}

	if req.Phone == "" || req.Code == "" {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "phone and code are required"})
		return
	}

	res, err := h.otpService.VerifyOTP(r.Context(), req.Phone, req.Code, req.Purpose)
	if err != nil {
		switch {
		case errors.Is(err, ErrOTPExpired):
			writeJSON(w, http.StatusUnprocessableEntity, errorResponse{Error: err.Error()})
		case errors.Is(err, ErrOTPMaxAttempts):
			writeJSON(w, http.StatusTooManyRequests, errorResponse{Error: err.Error()})
		case errors.Is(err, ErrOTPAlreadyVerified):
			writeJSON(w, http.StatusConflict, errorResponse{Error: err.Error()})
		case errors.Is(err, ErrAccountNotActive):
			writeJSON(w, http.StatusForbidden, errorResponse{Error: err.Error()})
		default:
			// ErrInvalidOTP, ErrOTPNotFound → 401 to avoid phone enumeration
			writeJSON(w, http.StatusUnauthorized, errorResponse{Error: "invalid or expired otp"})
		}
		return
	}

	writeJSON(w, http.StatusOK, res)
}
