package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/yanmii-inc/lokalaku/apps/api/internal/auth"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/config"
	"github.com/yanmii-inc/lokalaku/apps/api/internal/router"
)

func main() {
	cfg := config.Load()

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	tokenService := auth.NewTokenService(cfg.JWTSecret, cfg.AccessTokenTTL, cfg.RefreshTokenTTL)
	sessionStore := auth.NewMemorySessionStore()
	accountRepo := auth.NewMemoryAccountRepo()
	authService := auth.NewService(tokenService, accountRepo, sessionStore)
	otpStore := auth.NewMemoryOTPStore()
	otpService := auth.NewOTPService(otpStore, accountRepo, tokenService, logger)

	r := router.New(logger, authService, tokenService, otpService)

	server := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.Port),
		Handler: r,
	}

	shutdownComplete := make(chan struct{})

	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
		<-sigChan

		logger.Info("shutting down HTTP server gracefully", "timeout", cfg.ShutdownTimeout.String())

		ctx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			logger.Error("error during HTTP server shutdown", "error", err)
		}
		close(shutdownComplete)
	}()

	logger.Info("starting HTTP server", "port", cfg.Port, "env", cfg.Env)

	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		logger.Error("HTTP server error", "error", err)
		os.Exit(1)
	}

	<-shutdownComplete
	logger.Info("server exited cleanly")
}
