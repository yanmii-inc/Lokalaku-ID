package auth

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/domain"
)

var (
	ErrSessionNotFound = errors.New("session not found")
	ErrAccountNotFound = errors.New("account not found")
	ErrSessionExpired  = errors.New("session has expired")
	ErrSessionRevoked  = errors.New("session has been revoked")

	// OTP sentinel errors
	ErrOTPNotFound       = errors.New("otp not found or expired")
	ErrOTPExpired        = errors.New("otp has expired")
	ErrOTPMaxAttempts    = errors.New("otp max attempts exceeded")
	ErrOTPAlreadyVerified = errors.New("otp already verified")
	ErrInvalidOTP        = errors.New("invalid otp code")
)

// SessionStore provides storage operations for refresh token sessions.
type SessionStore interface {
	CreateSession(ctx context.Context, session *domain.Session) error
	GetSessionByHash(ctx context.Context, hash string) (*domain.Session, error)
	RotateSession(ctx context.Context, oldHash string, newSession *domain.Session) error
	RevokeSession(ctx context.Context, hash string) error
}

// AccountRepo provides storage operations for accounts.
type AccountRepo interface {
	GetByID(ctx context.Context, id string) (*domain.Account, error)
	GetByPhoneOrEmail(ctx context.Context, identifier string) (*domain.Account, error)
	Create(ctx context.Context, account *domain.Account) error
}

// MemorySessionStore is a thread-safe in-memory implementation of SessionStore.
type MemorySessionStore struct {
	mu       sync.RWMutex
	sessions map[string]*domain.Session // keyed by RefreshTokenHash
}

// NewMemorySessionStore creates a new in-memory SessionStore.
func NewMemorySessionStore() *MemorySessionStore {
	return &MemorySessionStore{
		sessions: make(map[string]*domain.Session),
	}
}

func (m *MemorySessionStore) CreateSession(ctx context.Context, session *domain.Session) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	cp := *session
	m.sessions[session.RefreshTokenHash] = &cp
	return nil
}

func (m *MemorySessionStore) GetSessionByHash(ctx context.Context, hash string) (*domain.Session, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	s, ok := m.sessions[hash]
	if !ok {
		return nil, ErrSessionNotFound
	}

	cp := *s
	return &cp, nil
}

func (m *MemorySessionStore) RotateSession(ctx context.Context, oldHash string, newSession *domain.Session) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	s, ok := m.sessions[oldHash]
	if !ok {
		return ErrSessionNotFound
	}

	if s.RevokedAt != nil {
		return ErrSessionRevoked
	}

	if time.Now().After(s.ExpiresAt) {
		return ErrSessionExpired
	}

	// Revoke old session and add new session
	now := time.Now()
	s.RevokedAt = &now

	cp := *newSession
	m.sessions[newSession.RefreshTokenHash] = &cp
	return nil
}

func (m *MemorySessionStore) RevokeSession(ctx context.Context, hash string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	s, ok := m.sessions[hash]
	if !ok {
		return ErrSessionNotFound
	}

	now := time.Now()
	s.RevokedAt = &now
	return nil
}

// MemoryAccountRepo is a thread-safe in-memory implementation of AccountRepo.
type MemoryAccountRepo struct {
	mu       sync.RWMutex
	accounts map[string]*domain.Account
}

// NewMemoryAccountRepo creates a new in-memory AccountRepo.
func NewMemoryAccountRepo() *MemoryAccountRepo {
	return &MemoryAccountRepo{
		accounts: make(map[string]*domain.Account),
	}
}

func (r *MemoryAccountRepo) GetByID(ctx context.Context, id string) (*domain.Account, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	acc, ok := r.accounts[id]
	if !ok {
		return nil, ErrAccountNotFound
	}
	cp := *acc
	return &cp, nil
}

func (r *MemoryAccountRepo) GetByPhoneOrEmail(ctx context.Context, identifier string) (*domain.Account, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, acc := range r.accounts {
		if acc.Phone == identifier {
			cp := *acc
			return &cp, nil
		}
		if acc.Email != nil && *acc.Email == identifier {
			cp := *acc
			return &cp, nil
		}
	}

	return nil, ErrAccountNotFound
}

func (r *MemoryAccountRepo) Create(ctx context.Context, account *domain.Account) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	cp := *account
	r.accounts[account.ID] = &cp
	return nil
}
