package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all configuration parameters for the API server.
type Config struct {
	Port            string
	ShutdownTimeout time.Duration
	Env             string
	JWTSecret       string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
}

// Load reads configuration parameters from environment variables with safe defaults.
func Load() Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	env := os.Getenv("ENV")
	if env == "" {
		env = "development"
	}

	shutdownTimeoutSecStr := os.Getenv("SHUTDOWN_TIMEOUT_SECONDS")
	shutdownTimeoutSec := 10
	if shutdownTimeoutSecStr != "" {
		if parsed, err := strconv.Atoi(shutdownTimeoutSecStr); err == nil && parsed > 0 {
			shutdownTimeoutSec = parsed
		}
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "lokalaku_dev_jwt_secret_32bytes_long_key!!"
	}

	return Config{
		Port:            port,
		ShutdownTimeout: time.Duration(shutdownTimeoutSec) * time.Second,
		Env:             env,
		JWTSecret:       jwtSecret,
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 30 * 24 * time.Hour,
	}
}

