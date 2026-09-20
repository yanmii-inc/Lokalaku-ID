import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:lokalaku_core_auth/lokalaku_core_auth.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

/// In-memory implementation of [TokenStorage] for deterministic testing.
class InMemoryTokenStorage implements TokenStorage {
  AuthToken? _token;
  Account? _account;
  String? _pinHash;
  String? _pinSalt;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  @override
  Future<void> saveAuthToken(AuthToken token) async {
    _token = token;
  }

  @override
  Future<AuthToken?> readAuthToken() async => _token;

  @override
  Future<void> clearAuthToken() async {
    _token = null;
  }

  @override
  Future<void> saveAccount(Account account) async {
    _account = account;
  }

  @override
  Future<Account?> readAccount() async => _account;

  @override
  Future<void> clearAccount() async {
    _account = null;
  }

  @override
  Future<void> setPin(String pin) async {
    _pinSalt = 'test_salt_${Random().nextInt(10000)}';
    _pinHash = _hashPin(pin, _pinSalt!);
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  @override
  Future<bool> hasPin() async => _pinHash != null;

  @override
  Future<PinResult> verifyPin(String pin) async {
    if (_lockedUntil != null) {
      if (DateTime.now().isBefore(_lockedUntil!)) {
        return PinResult.lockedOut(
          lockDuration: _lockedUntil!.difference(DateTime.now()),
        );
      } else {
        _lockedUntil = null;
        _failedAttempts = 0;
      }
    }

    if (_pinSalt == null || _pinHash == null) {
      return const PinResult.notSet();
    }

    final candidate = _hashPin(pin, _pinSalt!);
    if (candidate == _pinHash) {
      _failedAttempts = 0;
      return const PinResult.success();
    }

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockoutDuration);
      return const PinResult.lockedOut(lockDuration: lockoutDuration);
    }

    return PinResult.invalidPin(remainingAttempts: maxAttempts - _failedAttempts);
  }

  @override
  Future<void> clearPin() async {
    _pinHash = null;
    _pinSalt = null;
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  @override
  Future<void> clearAll() async {
    await clearAuthToken();
    await clearAccount();
    await clearPin();
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}

/// Fake implementation of [AuthApiClient] for unit testing.
class FakeAuthApiClient implements AuthApiClient {
  Result<({AuthToken token, Account account})>? loginResult;
  Result<({AuthToken token, Account account})>? refreshResult;
  Result<void>? logoutResult;
  Result<void>? requestOtpResult;
  Result<({AuthToken? token, Account? account})>? verifyOtpResult;

  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Result<({AuthToken token, Account account})>> login(
    LoginRequest request,
  ) async {
    loginCalls++;
    return loginResult ?? const Result.failure('Default fake login failure');
  }

  @override
  Future<Result<({AuthToken token, Account account})>> refreshToken(
    String refreshToken,
  ) async {
    refreshCalls++;
    return refreshResult ?? const Result.failure('Default fake refresh failure');
  }

  @override
  Future<Result<void>> logout(String refreshToken) async {
    logoutCalls++;
    return logoutResult ?? const Result.success(null);
  }

  @override
  Future<Result<void>> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    return requestOtpResult ?? const Result.success(null);
  }

  @override
  Future<Result<({AuthToken? token, Account? account})>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    return verifyOtpResult ?? const Result.failure('Default fake verifyOtp failure');
  }
}
