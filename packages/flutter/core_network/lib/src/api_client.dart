import 'package:dio/dio.dart';
import 'package:lokalaku_core_network/src/models/api_error.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Configured HTTP client wrapping [Dio] and converting network responses
/// into type-safe domain [Result] outcomes.
class ApiClient {
  ApiClient({
    String? baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 15),
    List<Interceptor> interceptors = const [],
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? '',
                connectTimeout: connectTimeout,
                receiveTimeout: receiveTimeout,
                sendTimeout: sendTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (interceptors.isNotEmpty) {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  /// Underlying [Dio] instance for advanced configuration or custom interceptors.
  final Dio dio;

  /// Executes an HTTP GET request returning a domain [Result].
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
  }) async {
    return _execute(
      () => dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  /// Executes an HTTP POST request returning a domain [Result].
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
  }) async {
    return _execute(
      () => dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  /// Executes an HTTP PUT request returning a domain [Result].
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
  }) async {
    return _execute(
      () => dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  /// Executes an HTTP PATCH request returning a domain [Result].
  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
  }) async {
    return _execute(
      () => dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  /// Executes an HTTP DELETE request returning a domain [Result].
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
  }) async {
    return _execute(
      () => dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson,
    );
  }

  Future<Result<T>> _execute<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data)? fromJson,
  ) async {
    try {
      final response = await call();
      final data = response.data;

      if (fromJson != null) {
        return Result.success(fromJson(data));
      }

      if (data is T) {
        return Result.success(data);
      }

      if (data == null && null is T) {
        return Result.success(null as T);
      }

      return Result.failure(
        'Failed to parse response of type ${data.runtimeType} to $T',
      );
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      return apiError.toResult<T>();
    } catch (e, st) {
      return Result<T>.failure(
        'Unexpected client error: $e',
        error: e,
        stackTrace: st,
      );
    }
  }
}
