package auth

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log/slog"
	"math/big"
	"sync"
	"time"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

const (
	otpLength      = 6
	otpTTL         = 5 * time.Minute
	otpMaxAttempts = 5
)

// OTPPurpose defines why an OTP was issued.
type OTPPurpose string

const (
	PurposeAuth        OTPPurpose = "auth"
	PurposePhoneVerify OTPPurpose = "phone_verify"
)

// OTPStore provides persistence for OTP codes.
type OTPStore interface {
	// CreateOTP persists a new OTP, invalidating any prior active OTP for the same phone+purpose.
	CreateOTP(ctx context.Context, otp *domain.OTPCode) error
	// GetActiveOTP returns the most recent unexpired, unverified OTP for the given phone+purpose.
	GetActiveOTP(ctx context.Context, phone, purpose string) (*domain.OTPCode, error)
	// IncrementAttempts increments the failed-attempt counter for a given OTP ID.
	IncrementAttempts(ctx context.Context, id string) error
	// MarkVerified records the verification timestamp for a given OTP ID.
	MarkVerified(ctx context.Context, id string) error
}

// OTPService handles OTP issuance and verification for phone-based auth flows.
type OTPService struct {
	store       OTPStore
	accountRepo AccountRepo
	tokens      *TokenService
	logger      *slog.Logger
}

// NewOTPService creates a new OTPService.
func NewOTPService(store OTPStore, accountRepo AccountRepo, tokens *TokenService, logger *slog.Logger) *OTPService {
	return &OTPService{
		store:       store,
		accountRepo: accountRepo,
		tokens:      tokens,
		logger:      logger,
	}
}

// RequestOTPResponse holds the response for an OTP request.
type RequestOTPResponse struct {
	Phone   string `json:"phone"`
	Purpose string `json:"purpose"`
	// ExpiresInSeconds tells the client how long the code is valid.
	ExpiresInSeconds int `json:"expires_in_seconds"`
}

// RequestOTP generates and stores a 6-digit OTP for the given phone number and purpose.
// The plain-text code is emitted via slog (dev-only disclosure). In production a real
// SMS/push delivery mechanism replaces the log line.
func (s *OTPService) RequestOTP(ctx context.Context, phone, purpose string) (*RequestOTPResponse, error) {
	if phone == "" {
		return nil, errors.New("phone is required")
	}
	if purpose == "" {
		purpose = string(PurposeAuth)
	}

	code, err := generateNumericOTP(otpLength)
	if err != nil {
		return nil, fmt.Errorf("failed to generate OTP: %w", err)
	}

	now := time.Now()
	otp := &domain.OTPCode{
		ID:        fmt.Sprintf("otp_%d", now.UnixNano()),
		Phone:     phone,
		CodeHash:  HashToken(code), // SHA-256, same as refresh token hashing
		Purpose:   purpose,
		Attempts:  0,
		ExpiresAt: now.Add(otpTTL),
		CreatedAt: now,
	}

	if err := s.store.CreateOTP(ctx, otp); err != nil {
		return nil, fmt.Errorf("failed to store OTP: %w", err)
	}

	// Dev-mode disclosure: log the plain-text code so it can be used without SMS.
	// In production, replace this with an SMS/push dispatch call.
	s.logger.Info("OTP issued",
		slog.String("phone", phone),
		slog.String("purpose", purpose),
		slog.String("otp_code", code), // remove when SMS delivery is wired
		slog.Time("expires_at", otp.ExpiresAt),
	)

	return &RequestOTPResponse{
		Phone:            phone,
		Purpose:          purpose,
		ExpiresInSeconds: int(otpTTL.Seconds()),
	}, nil
}

// VerifyOTPResponse holds the response after a successful OTP verification.
// For purpose="auth" this includes a full token pair; for other purposes it
// returns only confirmation metadata.
type VerifyOTPResponse struct {
	Verified  bool               `json:"verified"`
	TokenPair *TokenPairResponse `json:"token_pair,omitempty"`
}

// VerifyOTP validates the provided code for the given phone and purpose.
// For purpose="auth", on success it also locates the account and returns a token pair.
func (s *OTPService) VerifyOTP(ctx context.Context, phone, code, purpose string) (*VerifyOTPResponse, error) {
	if phone == "" || code == "" {
		return nil, ErrInvalidOTP
	}
	if purpose == "" {
		purpose = string(PurposeAuth)
	}

	otp, err := s.store.GetActiveOTP(ctx, phone, purpose)
	if err != nil {
		return nil, ErrInvalidOTP
	}

	if otp.IsExpired() {
		return nil, ErrOTPExpired
	}

	if otp.Attempts >= otpMaxAttempts {
		return nil, ErrOTPMaxAttempts
	}

	if otp.VerifiedAt != nil {
		return nil, ErrOTPAlreadyVerified
	}

	if HashToken(code) != otp.CodeHash {
		// Increment attempt counter; ignore store error to keep response consistent.
		_ = s.store.IncrementAttempts(ctx, otp.ID)
		return nil, ErrInvalidOTP
	}

	if err := s.store.MarkVerified(ctx, otp.ID); err != nil {
		return nil, fmt.Errorf("failed to mark OTP as verified: %w", err)
	}

	// For auth purposes, look up the account and issue a token pair.
	if purpose == string(PurposeAuth) {
		acc, err := s.accountRepo.GetByPhoneOrEmail(ctx, phone)
		if err != nil {
			// Phone is verified but not yet registered — signal the client.
			return &VerifyOTPResponse{Verified: true}, nil
		}

		if acc.Status != domain.StatusActive {
			return nil, ErrAccountNotActive
		}

		accessToken, err := s.tokens.GenerateAccessToken(acc)
		if err != nil {
			return nil, fmt.Errorf("failed to generate access token: %w", err)
		}

		return &VerifyOTPResponse{
			Verified: true,
			TokenPair: &TokenPairResponse{
				AccessToken: accessToken,
				ExpiresIn:   int64(s.tokens.AccessTTL().Seconds()),
				TokenType:   "Bearer",
				Account:     acc,
			},
		}, nil
	}

	return &VerifyOTPResponse{Verified: true}, nil
}

// generateNumericOTP produces a zero-padded numeric OTP of the given digit length
// using a cryptographically secure random source.
func generateNumericOTP(digits int) (string, error) {
	max := big.NewInt(1)
	for i := 0; i < digits; i++ {
		max.Mul(max, big.NewInt(10))
	}

	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%0*d", digits, n), nil
}

// ─── MemoryOTPStore ───────────────────────────────────────────────────────────

// MemoryOTPStore is a thread-safe in-memory implementation of OTPStore.
type MemoryOTPStore struct {
	mu   sync.RWMutex
	otps map[string]*domain.OTPCode // keyed by ID
}

// NewMemoryOTPStore creates a new in-memory OTPStore.
func NewMemoryOTPStore() *MemoryOTPStore {
	return &MemoryOTPStore{
		otps: make(map[string]*domain.OTPCode),
	}
}

func (m *MemoryOTPStore) CreateOTP(ctx context.Context, otp *domain.OTPCode) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	// Invalidate any prior active OTP for this phone+purpose by marking it expired.
	for _, existing := range m.otps {
		if existing.Phone == otp.Phone &&
			existing.Purpose == otp.Purpose &&
			existing.VerifiedAt == nil &&
			!existing.IsExpired() {
			past := time.Now().Add(-time.Second)
			existing.ExpiresAt = past
		}
	}

	cp := *otp
	m.otps[otp.ID] = &cp
	return nil
}

func (m *MemoryOTPStore) GetActiveOTP(ctx context.Context, phone, purpose string) (*domain.OTPCode, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var latest *domain.OTPCode
	for _, otp := range m.otps {
		if otp.Phone != phone || otp.Purpose != purpose {
			continue
		}
		if otp.IsExpired() {
			continue
		}
		if otp.VerifiedAt != nil {
			continue
		}
		if latest == nil || otp.CreatedAt.After(latest.CreatedAt) {
			latest = otp
		}
	}

	if latest == nil {
		return nil, ErrOTPNotFound
	}

	cp := *latest
	return &cp, nil
}

func (m *MemoryOTPStore) IncrementAttempts(ctx context.Context, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	otp, ok := m.otps[id]
	if !ok {
		return ErrOTPNotFound
	}
	otp.Attempts++
	return nil
}

func (m *MemoryOTPStore) MarkVerified(ctx context.Context, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	otp, ok := m.otps[id]
	if !ok {
		return ErrOTPNotFound
	}

	now := time.Now()
	otp.VerifiedAt = &now
	return nil
}
