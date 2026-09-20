package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

var (
	ErrInvalidCredentials  = errors.New("invalid phone/email or password")
	ErrAccountNotActive    = errors.New("account is not active")
	ErrInvalidRefreshToken = errors.New("invalid or expired refresh token")
)

// LoginRequest holds caller credentials.
type LoginRequest struct {
	Identifier string `json:"identifier"` // Phone number or email
	Password   string `json:"password"`
}

// TokenPairResponse represents the authentication payload returned to clients.
type TokenPairResponse struct {
	AccessToken  string          `json:"access_token"`
	RefreshToken string          `json:"refresh_token"`
	ExpiresIn    int64           `json:"expires_in"` // in seconds
	TokenType    string          `json:"token_type"`
	Account      *domain.Account `json:"account"`
}

// Service provides business logic for authentication and token sessions.
type Service struct {
	tokens       *TokenService
	accountRepo  AccountRepo
	sessionStore SessionStore
}

// NewService creates a new authentication Service.
func NewService(tokens *TokenService, accountRepo AccountRepo, sessionStore SessionStore) *Service {
	return &Service{
		tokens:       tokens,
		accountRepo:  accountRepo,
		sessionStore: sessionStore,
	}
}

// Login verifies account credentials and creates a new authenticated session.
func (s *Service) Login(ctx context.Context, req LoginRequest, userAgent, ip string) (*TokenPairResponse, error) {
	if req.Identifier == "" || req.Password == "" {
		return nil, ErrInvalidCredentials
	}

	acc, err := s.accountRepo.GetByPhoneOrEmail(ctx, req.Identifier)
	if err != nil {
		if errors.Is(err, ErrAccountNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("failed to lookup account: %w", err)
	}

	if acc.PasswordHash == nil || *acc.PasswordHash == "" {
		return nil, ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(*acc.PasswordHash), []byte(req.Password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	if acc.Status != domain.StatusActive {
		return nil, ErrAccountNotActive
	}

	// Generate access token
	accessToken, err := s.tokens.GenerateAccessToken(acc)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Generate refresh token
	rawRefresh, hashRefresh, err := s.tokens.GenerateRefreshToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	now := time.Now()
	session := domain.Session{
		ID:               fmt.Sprintf("sess_%d", now.UnixNano()),
		AccountID:        acc.ID,
		RefreshTokenHash: hashRefresh,
		UserAgent:        &userAgent,
		IPAddress:        &ip,
		ExpiresAt:        now.Add(s.tokens.RefreshTTL()),
		CreatedAt:        now,
	}

	if err := s.sessionStore.CreateSession(ctx, &session); err != nil {
		return nil, fmt.Errorf("failed to persist session: %w", err)
	}

	return &TokenPairResponse{
		AccessToken:  accessToken,
		RefreshToken: rawRefresh,
		ExpiresIn:    int64(s.tokens.AccessTTL().Seconds()),
		TokenType:    "Bearer",
		Account:      acc,
	}, nil
}

// Refresh validates an existing refresh token, rotates it, and issues a new access token.
func (s *Service) Refresh(ctx context.Context, rawRefreshToken, userAgent, ip string) (*TokenPairResponse, error) {
	if rawRefreshToken == "" {
		return nil, ErrInvalidRefreshToken
	}

	oldHash := HashToken(rawRefreshToken)
	session, err := s.sessionStore.GetSessionByHash(ctx, oldHash)
	if err != nil {
		return nil, ErrInvalidRefreshToken
	}

	if !session.IsActive() {
		return nil, ErrInvalidRefreshToken
	}

	acc, err := s.accountRepo.GetByID(ctx, session.AccountID)
	if err != nil {
		return nil, ErrInvalidRefreshToken
	}

	if acc.Status != domain.StatusActive {
		return nil, ErrAccountNotActive
	}

	// Generate new access token
	accessToken, err := s.tokens.GenerateAccessToken(acc)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Generate rotated refresh token
	newRawRefresh, newHashRefresh, err := s.tokens.GenerateRefreshToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate rotated refresh token: %w", err)
	}

	now := time.Now()
	newSession := domain.Session{
		ID:               fmt.Sprintf("sess_%d", now.UnixNano()),
		AccountID:        acc.ID,
		RefreshTokenHash: newHashRefresh,
		UserAgent:        &userAgent,
		IPAddress:        &ip,
		ExpiresAt:        now.Add(s.tokens.RefreshTTL()),
		CreatedAt:        now,
	}

	// Rotate session
	if err := s.sessionStore.RotateSession(ctx, oldHash, &newSession); err != nil {
		return nil, ErrInvalidRefreshToken
	}

	return &TokenPairResponse{
		AccessToken:  accessToken,
		RefreshToken: newRawRefresh,
		ExpiresIn:    int64(s.tokens.AccessTTL().Seconds()),
		TokenType:    "Bearer",
		Account:      acc,
	}, nil
}

// Logout revokes the session associated with the provided refresh token.
func (s *Service) Logout(ctx context.Context, rawRefreshToken string) error {
	if rawRefreshToken == "" {
		return nil
	}

	hash := HashToken(rawRefreshToken)
	_ = s.sessionStore.RevokeSession(ctx, hash)
	return nil
}
