import 'dart:async';

import 'package:lokalaku_core_auth/src/auth_client.dart';
import 'package:lokalaku_core_auth/src/models/auth_state.dart';
import 'package:lokalaku_core_auth/src/models/login_request.dart';
import 'package:lokalaku_core_auth/src/models/pin_result.dart';
import 'package:lokalaku_core_auth/src/refresh_token_timer.dart';
import 'package:lokalaku_core_auth/src/token_storage.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Central authentication service orchestrating tokens, session lifecycle,
/// proactive JWT refresh timers, and offline PIN grace sessions.
class AuthService {
  AuthService({
    required TokenStorage tokenStorage,
    required AuthApiClient client,
    RefreshTokenTimer? refreshTimer,
  })  : _storage = tokenStorage,
        _client = client {
    _refreshTimer = refreshTimer ??
        RefreshTokenTimer(
          onRefresh: () async {
            await refresh();
          },
        );
  }

  final TokenStorage _storage;
  final AuthApiClient _client;
  late final RefreshTokenTimer _refreshTimer;

  final _stateController = StreamController<AuthState>.broadcast();
  AuthState _state = const AuthState.unauthenticated();

  /// Current authentication state.
  AuthState get state => _state;

  /// Broadcast stream of authentication state changes.
  Stream<AuthState> get stateStream => _stateController.stream;

  /// Maximum permitted offline grace duration for merchant POS continuity (ADR-003).
  static const Duration maxOfflineGraceDuration = Duration(hours: 8);

  void _setState(AuthState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  /// Restores session on app startup by checking stored tokens.
  ///
  /// If the stored token is still valid, immediately enters [Authenticated]
  /// and schedules the proactive refresh timer. If expired, attempts a silent refresh.
  Future<Result<Account>> restoreSession() async {
    final token = await _storage.readAuthToken();
    final account = await _storage.readAccount();

    if (token == null || account == null) {
      _setState(const AuthState.unauthenticated());
      return const Result.failure('No stored session found');
    }

    if (!token.isExpired) {
      _setState(AuthState.authenticated(account: account, token: token));
      _refreshTimer.schedule(token);
      return Result.success(account);
    }

    // Access token expired, attempt refresh using stored refresh token
    final refreshResult = await refresh();
    return switch (refreshResult) {
      Success() => Result.success(account),
      Failure(:final message, :final error, :final stackTrace) =>
        Result.failure(message, error: error, stackTrace: stackTrace),
    };
  }

  /// Performs user login with phone/email and password.
  Future<Result<Account>> login(LoginRequest request) async {
    _setState(const AuthState.authenticating());

    final result = await _client.login(request);

    switch (result) {
      case Success(data: (:final token, :final account)):
        await _storage.saveAuthToken(token);
        await _storage.saveAccount(account);

        _setState(AuthState.authenticated(account: account, token: token));
        _refreshTimer.schedule(token);

        return Result.success(account);

      case Failure(:final message, :final error, :final stackTrace):
        _setState(AuthState.unauthenticated(message: message));
        return Result<Account>.failure(
          message,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// Requests a 6-digit SMS OTP code for [phone].
  Future<Result<void>> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    return _client.requestOtp(phone: phone, purpose: purpose);
  }

  /// Verifies an OTP code and establishes an authenticated session if a token pair is issued.
  Future<Result<Account?>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    _setState(const AuthState.authenticating());

    final result = await _client.verifyOtp(
      phone: phone,
      code: code,
      purpose: purpose,
    );

    switch (result) {
      case Success(data: (:final token, :final account)):
        if (token != null && account != null) {
          await _storage.saveAuthToken(token);
          await _storage.saveAccount(account);

          _setState(AuthState.authenticated(account: account, token: token));
          _refreshTimer.schedule(token);
          return Result.success(account);
        }

        _setState(const AuthState.unauthenticated());
        return const Result.success(null);

      case Failure(:final message, :final error, :final stackTrace):
        _setState(AuthState.unauthenticated(message: message));
        return Result<Account?>.failure(
          message,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// Refreshes the JWT access token using the stored refresh token.
  Future<Result<AuthToken>> refresh() async {
    final currentToken = await _storage.readAuthToken();
    if (currentToken == null) {
      _setState(const AuthState.unauthenticated());
      return const Result.failure('No refresh token available');
    }

    final result = await _client.refreshToken(currentToken.refreshToken);

    switch (result) {
      case Success(data: (:final token, :final account)):
        await _storage.saveAuthToken(token);
        await _storage.saveAccount(account);

        _setState(AuthState.authenticated(account: account, token: token));
        _refreshTimer.schedule(token);

        return Result.success(token);

      case Failure(:final message, :final error, :final stackTrace):
        // If refresh failed due to token revocation/expiry, clear local storage
        await _storage.clearAuthToken();
        _refreshTimer.cancel();
        _setState(AuthState.unauthenticated(message: message));

        return Result<AuthToken>.failure(
          message,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// Revokes session on the server and purges all credentials locally.
  Future<Result<void>> logout() async {
    _refreshTimer.cancel();

    final token = await _storage.readAuthToken();
    if (token != null) {
      // Best-effort remote revocation
      await _client.logout(token.refreshToken);
    }

    await _storage.clearAll();
    _setState(const AuthState.unauthenticated());

    return const Result.success(null);
  }

  /// Sets or updates the 6-digit offline PIN.
  Future<Result<void>> setPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      return const Result.failure('PIN must be exactly 6 digits');
    }

    await _storage.setPin(pin);
    return const Result.success(null);
  }

  /// Unlocks an offline session using the local 6-digit PIN.
  ///
  /// On successful match, grants an [OfflineGrace] session lasting up to 8 hours
  /// to ensure POS transaction continuity during network outages.
  Future<PinResult> unlockWithPin(String pin) async {
    final result = await _storage.verifyPin(pin);

    if (result is PinSuccess) {
      final account = await _storage.readAccount();
      if (account != null) {
        final graceExpiry = DateTime.now().add(maxOfflineGraceDuration);
        _setState(AuthState.offlineGrace(
          account: account,
          graceExpiresAt: graceExpiry,
        ));

        // Attempt silent background refresh in case network recovered
        unawaited(refresh());
      }
    }

    return result;
  }

  /// Disposes background timers and stream controllers.
  void dispose() {
    _refreshTimer.cancel();
    _stateController.close();
  }
}
