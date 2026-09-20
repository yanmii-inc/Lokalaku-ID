package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

// Claims defines the JWT claims payload per ADR-003.
type Claims struct {
	jwt.RegisteredClaims
	Role             domain.Role          `json:"role"`
	VillageClusterID *string              `json:"village_cluster_id,omitempty"`
	Status           domain.AccountStatus `json:"status"`
}

// TokenService handles generation and validation of access and refresh tokens.
type TokenService struct {
	secret     []byte
	accessTTL  time.Duration
	refreshTTL time.Duration
}

// NewTokenService creates a new TokenService.
func NewTokenService(secret string, accessTTL, refreshTTL time.Duration) *TokenService {
	return &TokenService{
		secret:     []byte(secret),
		accessTTL:  accessTTL,
		refreshTTL: refreshTTL,
	}
}

// GenerateAccessToken generates an HMAC-SHA256 signed JWT for the account.
func (s *TokenService) GenerateAccessToken(account *domain.Account) (string, error) {
	now := time.Now()
	claims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   account.ID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.accessTTL)),
		},
		Role:             account.Role,
		VillageClusterID: account.VillageClusterID,
		Status:           account.Status,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secret)
}

// ValidateAccessToken parses and validates an HMAC-SHA256 JWT string.
func (s *TokenService) ValidateAccessToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.secret, nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	return claims, nil
}

// GenerateRefreshToken creates a secure random opaque token and its SHA-256 hash.
func (s *TokenService) GenerateRefreshToken() (rawToken string, hashedToken string, error error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", "", fmt.Errorf("failed to generate random bytes: %w", err)
	}

	rawToken = hex.EncodeToString(bytes)
	hashedToken = HashToken(rawToken)
	return rawToken, hashedToken, nil
}

// HashToken calculates the SHA-256 hash of a raw token string.
func HashToken(rawToken string) string {
	hash := sha256.Sum256([]byte(rawToken))
	return hex.EncodeToString(hash[:])
}

// AccessTTL returns the configured access token time-to-live.
func (s *TokenService) AccessTTL() time.Duration {
	return s.accessTTL
}

// RefreshTTL returns the configured refresh token time-to-live.
func (s *TokenService) RefreshTTL() time.Duration {
	return s.refreshTTL
}
