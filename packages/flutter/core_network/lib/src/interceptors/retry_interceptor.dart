import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Interceptor that automatically retries idempotent requests on transient
/// network errors or 5xx server responses using exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 5),
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;

  static const String retryCountKey = 'retryCount';
  static const String retryableKey = 'retryable';

  static const Set<String> _idempotentMethods = {
    'GET',
    'HEAD',
    'PUT',
    'DELETE',
    'OPTIONS',
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    if (!_shouldRetry(err, options)) {
      return handler.next(err);
    }

    final currentAttempt = (options.extra[retryCountKey] as int? ?? 0) + 1;

    if (currentAttempt > maxRetries) {
      return handler.next(err);
    }

    final delay = _calculateDelay(currentAttempt);
    await Future<void>.delayed(delay);

    try {
      final retryOptions = options.copyWith(
        extra: Map.of(options.extra)..[retryCountKey] = currentAttempt,
      );

      final response = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err, RequestOptions options) {
    // Check if explicitly marked retryable or using an idempotent HTTP method
    final explicitlyRetryable = options.extra[retryableKey] as bool? ?? false;
    final isIdempotent = _idempotentMethods.contains(options.method.toUpperCase());

    if (!explicitlyRetryable && !isIdempotent) {
      return false;
    }

    // Network connection errors and timeouts
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Server-side transient 5xx errors (502, 503, 504)
    final statusCode = err.response?.statusCode;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return true;
    }

    return false;
  }

  Duration _calculateDelay(int attempt) {
    // Exponential backoff: initialDelay * 2^(attempt-1) + jitter
    final factor = pow(2, attempt - 1).toDouble();
    final delayMs = initialDelay.inMilliseconds * factor;
    final jitter = Random().nextInt(100);
    final totalMs = min(delayMs + jitter, maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: totalMs.toInt());
  }
}
