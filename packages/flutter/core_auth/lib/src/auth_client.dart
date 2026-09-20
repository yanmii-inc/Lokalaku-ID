import 'package:dio/dio.dart';
import 'package:lokalaku_core_auth/src/models/login_request.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Contract for calling remote authentication API endpoints.
abstract interface class AuthApiClient {
  /// Authenticates using phone/email and password.
  Future<Result<({AuthToken token, Account account})>> login(LoginRequest request);

  /// Rotates the refresh token and obtains a fresh access token.
  Future<Result<({AuthToken token, Account account})>> refreshToken(String refreshToken);

  /// Revokes the current session and invalidates the refresh token server-side.
  Future<Result<void>> logout(String refreshToken);

  /// Requests a 6-digit OTP code to be sent to [phone].
  Future<Result<void>> requestOtp({
    required String phone,
    required String purpose,
  });

  /// Verifies an OTP code and exchanges it for a session if registration/login.
  Future<Result<({AuthToken? token, Account? account})>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  });
}

/// Default implementation of [AuthApiClient] using [Dio].
class DioAuthApiClient implements AuthApiClient {
  DioAuthApiClient({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Result<({AuthToken token, Account account})>> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        return const Result.failure('Empty response payload from auth service');
      }

      final token = AuthToken.fromJson(data);
      final accountData = data['account'] as Map<String, dynamic>?;
      if (accountData == null) {
        return const Result.failure('Missing account payload in login response');
      }
      final account = Account.fromJson(accountData);

      return Result.success((token: token, account: account));
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Authentication failed';
      return Result.failure(message, error: e);
    } catch (e, st) {
      return Result.failure('Unexpected login error', error: e, stackTrace: st);
    }
  }

  @override
  Future<Result<({AuthToken token, Account account})>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data == null) {
        return const Result.failure('Empty response payload from refresh service');
      }

      final token = AuthToken.fromJson(data);
      final accountData = data['account'] as Map<String, dynamic>?;
      if (accountData == null) {
        return const Result.failure('Missing account payload in refresh response');
      }
      final account = Account.fromJson(accountData);

      return Result.success((token: token, account: account));
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Token refresh failed';
      return Result.failure(message, error: e);
    } catch (e, st) {
      return Result.failure('Unexpected refresh error', error: e, stackTrace: st);
    }
  }

  @override
  Future<Result<void>> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
      );
      return const Result.success(null);
    } on DioException catch (e) {
      // Even if network fails, logout should succeed locally
      return Result.failure(
        _extractErrorMessage(e) ?? 'Logout request failed',
        error: e,
      );
    } catch (e, st) {
      return Result.failure('Unexpected logout error', error: e, stackTrace: st);
    }
  }

  @override
  Future<Result<void>> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/otp/request',
        data: {
          'phone': phone,
          'purpose': purpose,
        },
      );
      return const Result.success(null);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Failed to request OTP';
      return Result.failure(message, error: e);
    } catch (e, st) {
      return Result.failure('Unexpected OTP request error', error: e, stackTrace: st);
    }
  }

  @override
  Future<Result<({AuthToken? token, Account? account})>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: {
          'phone': phone,
          'code': code,
          'purpose': purpose,
        },
      );

      final data = response.data;
      if (data == null) {
        return const Result.failure('Empty response payload from OTP verification');
      }

      final verified = data['verified'] as bool? ?? false;
      if (!verified) {
        return const Result.failure('Invalid or expired OTP code');
      }

      final tokenPairData = data['token_pair'] as Map<String, dynamic>?;
      if (tokenPairData != null) {
        final token = AuthToken.fromJson(tokenPairData);
        final accountData = tokenPairData['account'] as Map<String, dynamic>?;
        final account = accountData != null ? Account.fromJson(accountData) : null;
        return Result.success((token: token, account: account));
      }

      return const Result.success((token: null, account: null));
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Failed to verify OTP';
      return Result.failure(message, error: e);
    } catch (e, st) {
      return Result.failure('Unexpected OTP verification error', error: e, stackTrace: st);
    }
  }

  String? _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return e.message;
  }
}
