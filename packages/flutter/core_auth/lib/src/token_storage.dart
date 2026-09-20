import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lokalaku_core_auth/src/models/pin_result.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Abstract storage contract for tokens, cached session accounts, and offline PINs.
abstract interface class TokenStorage {
  Future<void> saveAuthToken(AuthToken token);
  Future<AuthToken?> readAuthToken();
  Future<void> clearAuthToken();

  Future<void> saveAccount(Account account);
  Future<Account?> readAccount();
  Future<void> clearAccount();

  Future<void> setPin(String pin);
  Future<PinResult> verifyPin(String pin);
  Future<bool> hasPin();
  Future<void> clearPin();

  Future<void> clearAll();
}

/// Secure implementation of [TokenStorage] using [FlutterSecureStorage].
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({
    FlutterSecureStorage? secureStorage,
    Random? random,
  })  : _storage = secureStorage ?? const FlutterSecureStorage(),
        _random = random ?? Random.secure();

  final FlutterSecureStorage _storage;
  final Random _random;

  static const _keyAccessToken = 'lokalaku_auth_access_token';
  static const _keyRefreshToken = 'lokalaku_auth_refresh_token';
  static const _keyExpiresIn = 'lokalaku_auth_expires_in';
  static const _keyTokenType = 'lokalaku_auth_token_type';
  static const _keyIssuedAt = 'lokalaku_auth_issued_at';

  static const _keyAccountJson = 'lokalaku_auth_account_json';

  static const _keyPinHash = 'lokalaku_auth_pin_hash';
  static const _keyPinSalt = 'lokalaku_auth_pin_salt';
  static const _keyPinFailedAttempts = 'lokalaku_auth_pin_failed_attempts';
  static const _keyPinLockedUntil = 'lokalaku_auth_pin_locked_until';

  static const int maxPinAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  @override
  Future<void> saveAuthToken(AuthToken token) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: token.accessToken),
      _storage.write(key: _keyRefreshToken, value: token.refreshToken),
      _storage.write(key: _keyExpiresIn, value: token.expiresIn.toString()),
      _storage.write(key: _keyTokenType, value: token.tokenType),
      _storage.write(
        key: _keyIssuedAt,
        value: token.effectiveIssuedAt.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<AuthToken?> readAuthToken() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    final expiresInStr = await _storage.read(key: _keyExpiresIn);
    final expiresIn = int.tryParse(expiresInStr ?? '') ?? 900;
    final tokenType = await _storage.read(key: _keyTokenType) ?? 'Bearer';
    final issuedAtStr = await _storage.read(key: _keyIssuedAt);
    final issuedAt =
        issuedAtStr != null ? DateTime.tryParse(issuedAtStr) ?? DateTime.now() : DateTime.now();

    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      tokenType: tokenType,
      issuedAt: issuedAt,
    );
  }

  @override
  Future<void> clearAuthToken() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyExpiresIn),
      _storage.delete(key: _keyTokenType),
      _storage.delete(key: _keyIssuedAt),
    ]);
  }

  @override
  Future<void> saveAccount(Account account) async {
    final rawJson = jsonEncode(account.toJson());
    await _storage.write(key: _keyAccountJson, value: rawJson);
  }

  @override
  Future<Account?> readAccount() async {
    final rawJson = await _storage.read(key: _keyAccountJson);
    if (rawJson == null) return null;

    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return Account.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAccount() async {
    await _storage.delete(key: _keyAccountJson);
  }

  @override
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await Future.wait([
      _storage.write(key: _keyPinSalt, value: salt),
      _storage.write(key: _keyPinHash, value: hash),
      _storage.delete(key: _keyPinFailedAttempts),
      _storage.delete(key: _keyPinLockedUntil),
    ]);
  }

  @override
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<PinResult> verifyPin(String pin) async {
    // Check if currently locked out
    final lockedUntilStr = await _storage.read(key: _keyPinLockedUntil);
    if (lockedUntilStr != null) {
      final lockedUntil = DateTime.tryParse(lockedUntilStr);
      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        return PinResult.lockedOut(
          lockDuration: lockedUntil.difference(DateTime.now()),
        );
      } else {
        // Lockout expired, clear lockout
        await _storage.delete(key: _keyPinLockedUntil);
        await _storage.delete(key: _keyPinFailedAttempts);
      }
    }

    final salt = await _storage.read(key: _keyPinSalt);
    final expectedHash = await _storage.read(key: _keyPinHash);

    if (salt == null || expectedHash == null) {
      return const PinResult.notSet();
    }

    final candidateHash = _hashPin(pin, salt);

    if (candidateHash == expectedHash) {
      // Reset failed attempts on success
      await _storage.delete(key: _keyPinFailedAttempts);
      return const PinResult.success();
    }

    // Increment failed attempts
    final attemptsStr = await _storage.read(key: _keyPinFailedAttempts);
    final currentAttempts = (int.tryParse(attemptsStr ?? '') ?? 0) + 1;

    if (currentAttempts >= maxPinAttempts) {
      final lockedUntil = DateTime.now().add(lockoutDuration);
      await Future.wait([
        _storage.write(
          key: _keyPinLockedUntil,
          value: lockedUntil.toIso8601String(),
        ),
        _storage.write(
          key: _keyPinFailedAttempts,
          value: currentAttempts.toString(),
        ),
      ]);
      return const PinResult.lockedOut(lockDuration: lockoutDuration);
    }

    await _storage.write(
      key: _keyPinFailedAttempts,
      value: currentAttempts.toString(),
    );

    return PinResult.invalidPin(
      remainingAttempts: maxPinAttempts - currentAttempts,
    );
  }

  @override
  Future<void> clearPin() async {
    await Future.wait([
      _storage.delete(key: _keyPinSalt),
      _storage.delete(key: _keyPinHash),
      _storage.delete(key: _keyPinFailedAttempts),
      _storage.delete(key: _keyPinLockedUntil),
    ]);
  }

  @override
  Future<void> clearAll() async {
    await Future.wait([
      clearAuthToken(),
      clearAccount(),
      clearPin(),
    ]);
  }

  String _generateSalt([int length = 16]) {
    final values = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64UrlEncode(values);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
