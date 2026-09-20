import 'package:dio/dio.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Standardized API and network error representation.
class ApiError {
  const ApiError({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.rawError,
    this.stackTrace,
  });

  /// Human-readable error description suitable for UI presentation.
  final String message;

  /// HTTP status code if available (e.g. 400, 401, 403, 404, 500).
  final int? statusCode;

  /// Domain-specific error code string if provided by backend (e.g. "ERR_TOKEN_EXPIRED").
  final String? code;

  /// Structured error details (e.g. field validation error maps).
  final Map<String, dynamic>? details;

  /// Underlying raw exception (e.g. SocketException, DioException).
  final Object? rawError;

  /// Stack trace associated with the failure.
  final StackTrace? stackTrace;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isNetworkError =>
      rawError is DioException &&
      (rawError as DioException).type == DioExceptionType.connectionError;

  /// Converts this [ApiError] into a domain [Result.failure].
  Result<T> toResult<T>() => Result<T>.failure(
        message,
        error: this,
        stackTrace: stackTrace,
      );

  /// Constructs an [ApiError] from a caught [DioException].
  factory ApiError.fromDioException(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Network communication failed';
    String? code;
    Map<String, dynamic>? details;

    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is String && err.isNotEmpty) {
        message = err;
      } else {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) {
          message = msg;
        }
      }

      if (data['code'] is String) {
        code = data['code'] as String;
      }

      if (data['details'] is Map<String, dynamic>) {
        details = data['details'] as Map<String, dynamic>;
      }
    } else if (response?.statusMessage != null && response!.statusMessage!.isNotEmpty) {
      message = response.statusMessage!;
    } else {
      message = switch (exception.type) {
        DioExceptionType.connectionTimeout => 'Connection timed out',
        DioExceptionType.sendTimeout => 'Send request timed out',
        DioExceptionType.receiveTimeout => 'Server response timed out',
        DioExceptionType.badCertificate => 'Invalid server SSL certificate',
        DioExceptionType.badResponse => 'Server returned an invalid response',
        DioExceptionType.cancel => 'Request was cancelled',
        DioExceptionType.connectionError =>
          'Unable to connect to server. Please check your internet connection.',
        _ => exception.message ?? 'An unexpected network error occurred',
      };
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      code: code,
      details: details,
      rawError: exception,
      stackTrace: exception.stackTrace,
    );
  }

  @override
  String toString() => 'ApiError(statusCode: $statusCode, code: $code, message: "$message")';
}
