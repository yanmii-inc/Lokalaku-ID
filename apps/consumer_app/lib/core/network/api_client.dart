import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the Dio HTTP client
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com', // TODO: Replace with actual base URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Add standard interceptors (e.g., logging, auth)
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // TODO: Add auth token if needed
        // options.headers['Authorization'] = 'Bearer token';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Handle global responses if needed
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // Handle global errors
        return handler.next(e);
      },
    ),
  );

  // Add LogInterceptor in debug mode
  // dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});
