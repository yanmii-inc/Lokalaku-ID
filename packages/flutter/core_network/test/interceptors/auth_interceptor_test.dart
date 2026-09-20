import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lokalaku_core_network/lokalaku_core_network.dart';
import 'package:test/test.dart';

void main() {
  group('AuthInterceptor', () {
    late Dio dio;
    String? currentToken;
    var refreshCalled = false;
    var refreshSuccess = true;
    var authFailureCalled = false;

    setUp(() {
      currentToken = 'initial-token';
      refreshCalled = false;
      refreshSuccess = true;
      authFailureCalled = false;

      dio = Dio();
    });

    AuthInterceptor createInterceptor() {
      return AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        refreshToken: () async {
          refreshCalled = true;
          if (refreshSuccess) {
            currentToken = 'refreshed-token';
          }
          return refreshSuccess;
        },
        onAuthFailure: () async {
          authFailureCalled = true;
        },
      );
    }

    test('injects Bearer token when requiresAuth is true or omitted', () async {
      final interceptor = createInterceptor();
      final options = RequestOptions(path: '/orders');

      var nextCalled = false;

      // Intercept request via custom handler
      await interceptor.onRequest(
        options,
        _FakeRequestHandler((opt) {
          nextCalled = true;
          expect(opt.headers['Authorization'], equals('Bearer initial-token'));
        }),
      );

      expect(nextCalled, isTrue);
    });

    test('omits Authorization header when requiresAuth is false', () async {
      final interceptor = createInterceptor();
      final options = RequestOptions(
        path: '/auth/login',
        extra: {AuthInterceptor.requiresAuthKey: false},
      );

      var nextCalled = false;
      await interceptor.onRequest(
        options,
        _FakeRequestHandler((opt) {
          nextCalled = true;
          expect(opt.headers.containsKey('Authorization'), isFalse);
        }),
      );

      expect(nextCalled, isTrue);
    });

    test('retries on 401 and replays with new token on successful refresh', () async {
      final interceptor = createInterceptor();
      dio.interceptors.add(interceptor);

      // The retry client inside AuthInterceptor shares the adapter — set it
      // before the interceptor is created so both share the same instance.
      var fetchCount = 0;
      final adapter = _MockAdapter((options) async {
        fetchCount++;
        if (fetchCount == 1) {
          // First attempt returns 401
          return ResponseBody.fromString(
            '{"error": "Unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        // Retry attempt succeeds with refreshed token
        expect(options.headers['Authorization'], equals('Bearer refreshed-token'));
        expect(options.extra[AuthInterceptor.isRetryKey], isTrue);
        return ResponseBody.fromString(
          '{"success": true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      dio.httpClientAdapter = adapter;

      final response = await dio.get<dynamic>('/protected');

      expect(response.statusCode, equals(200));
      expect(refreshCalled, isTrue);
      expect(fetchCount, equals(2));
      expect(authFailureCalled, isFalse);
    });

    test('notifies onAuthFailure when refresh fails on 401', () async {
      refreshSuccess = false;
      final interceptor = createInterceptor();
      dio.interceptors.add(interceptor);

      dio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString(
          '{"error": "Unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCalled, isTrue);
      expect(authFailureCalled, isTrue);
    });

    test('does not loop if retry request also returns 401', () async {
      final interceptor = createInterceptor();
      dio.interceptors.add(interceptor);

      var attempts = 0;
      dio.httpClientAdapter = _MockAdapter((options) async {
        attempts++;
        return ResponseBody.fromString(
          '{"error": "Unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(isA<DioException>()),
      );

      // First attempt (401) → refresh → second attempt (401) → terminates.
      expect(attempts, equals(2));
    });
  });
}

class _FakeRequestHandler extends RequestInterceptorHandler {
  _FakeRequestHandler(this.onNext);
  final void Function(RequestOptions) onNext;

  @override
  void next(RequestOptions requestOptions) {
    onNext(requestOptions);
  }
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
