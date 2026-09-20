import 'package:dio/dio.dart';

/// Interceptor that transparently injects Bearer tokens and serializes
/// token refresh on HTTP 401 Unauthorized responses.
///
/// Uses [QueuedInterceptor] to prevent concurrent refresh stampedes:
/// when a 401 occurs, all concurrent outgoing requests are queued until
/// the refresh operation finishes.
///
/// Retry requests are dispatched through a dedicated [Dio] instance that
/// borrows the main client's [HttpClientAdapter] at call-time but carries
/// **no** [AuthInterceptor]. This prevents re-entrant calls back into the
/// same [QueuedInterceptor] queue, which would deadlock.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Future<String?> Function() getAccessToken,
    required Future<bool> Function() refreshToken,
    required Dio dio,
    Future<void> Function()? onAuthFailure,
  })  : _getAccessToken = getAccessToken,
        _refreshToken = refreshToken,
        _onAuthFailure = onAuthFailure,
        _dio = dio;

  final Future<String?> Function() _getAccessToken;
  final Future<bool> Function() _refreshToken;
  final Future<void> Function()? _onAuthFailure;

  /// The main Dio instance — used only to borrow its adapter for retries.
  final Dio _dio;

  static const String requiresAuthKey = 'requiresAuth';
  static const String isRetryKey = 'isRetry';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra[requiresAuthKey] as bool? ?? true;

    if (requiresAuth) {
      final token = await _getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;
    final requiresAuth = options.extra[requiresAuthKey] as bool? ?? true;
    final isRetry = options.extra[isRetryKey] as bool? ?? false;

    // Handle 401 only on authenticated, first-attempt requests.
    if (response?.statusCode == 401 && requiresAuth && !isRetry) {
      try {
        final refreshSucceeded = await _refreshToken();

        if (refreshSucceeded) {
          final newToken = await _getAccessToken();

          if (newToken != null && newToken.isNotEmpty) {
            // Build retry options with the fresh token and the retry flag.
            final retryOptions = options.copyWith(
              headers: Map.of(options.headers)..['Authorization'] = 'Bearer $newToken',
              extra: Map.of(options.extra)..[isRetryKey] = true,
            );

            // Dispatch through a dedicated Dio instance that borrows the
            // current adapter (captured lazily at call-time) but carries no
            // AuthInterceptor, preventing re-entry into this queue.
            final retryClient = Dio(
              BaseOptions(
                baseUrl: _dio.options.baseUrl,
                connectTimeout: _dio.options.connectTimeout,
                receiveTimeout: _dio.options.receiveTimeout,
              ),
            )..httpClientAdapter = _dio.httpClientAdapter;

            final retryResponse = await retryClient.fetch<dynamic>(retryOptions);
            return handler.resolve(retryResponse);
          }
        }
      } catch (_) {
        // Refresh threw or retry itself failed — fall through to auth failure.
      }

      // Refresh failed or returned an invalid token.
      await _onAuthFailure?.call();
    }

    handler.next(err);
  }
}
