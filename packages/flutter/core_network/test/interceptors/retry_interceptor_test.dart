import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lokalaku_core_network/lokalaku_core_network.dart';
import 'package:test/test.dart';

void main() {
  group('RetryInterceptor', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
    });

    test('retries idempotent GET request on connection error up to maxRetries', () async {
      final interceptor = RetryInterceptor(
        dio: dio,
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 10),
      );
      dio.interceptors.add(interceptor);

      var attempts = 0;
      dio.httpClientAdapter = _MockAdapter((options) async {
        attempts++;
        if (attempts < 3) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'Connection refused',
          );
        }
        return ResponseBody.fromString('{"status": "ok"}', 200);
      });

      final response = await dio.get<dynamic>('/health');
      expect(response.statusCode, equals(200));
      expect(attempts, equals(3));
    });

    test('retries on 503 Service Unavailable', () async {
      final interceptor = RetryInterceptor(
        dio: dio,
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 10),
      );
      dio.interceptors.add(interceptor);

      var attempts = 0;
      dio.httpClientAdapter = _MockAdapter((options) async {
        attempts++;
        if (attempts == 1) {
          return ResponseBody.fromString('{"error": "Unavailable"}', 503);
        }
        return ResponseBody.fromString('{"status": "recovered"}', 200);
      });

      final response = await dio.get<dynamic>('/data');
      expect(response.statusCode, equals(200));
      expect(attempts, equals(2));
    });

    test('does NOT retry non-idempotent POST requests by default', () async {
      final interceptor = RetryInterceptor(
        dio: dio,
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 10),
      );
      dio.interceptors.add(interceptor);

      var attempts = 0;
      dio.httpClientAdapter = _MockAdapter((options) async {
        attempts++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      expect(
        () => dio.post<dynamic>('/orders', data: {'item': '1'}),
        throwsA(isA<DioException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(attempts, equals(1)); // No retry
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
