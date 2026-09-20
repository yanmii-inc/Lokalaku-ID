import 'package:dio/dio.dart';
import 'package:lokalaku_core_network/lokalaku_core_network.dart';
import 'package:test/test.dart';

void main() {
  group('ApiError', () {
    test('status code helpers report correctly', () {
      const unauthorized = ApiError(message: 'unauth', statusCode: 401);
      expect(unauthorized.isUnauthorized, isTrue);
      expect(unauthorized.isForbidden, isFalse);

      const forbidden = ApiError(message: 'forbid', statusCode: 403);
      expect(forbidden.isForbidden, isTrue);

      const notFound = ApiError(message: 'not found', statusCode: 404);
      expect(notFound.isNotFound, isTrue);

      const serverError = ApiError(message: 'server error', statusCode: 500);
      expect(serverError.isServerError, isTrue);
    });

    test('fromDioException parses JSON error field', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {
            'error': 'Invalid phone number',
            'code': 'ERR_INVALID_PHONE',
            'details': {'field': 'phone'},
          },
        ),
      );

      final apiError = ApiError.fromDioException(dioException);

      expect(apiError.statusCode, equals(400));
      expect(apiError.message, equals('Invalid phone number'));
      expect(apiError.code, equals('ERR_INVALID_PHONE'));
      expect(apiError.details?['field'], equals('phone'));
    });

    test('fromDioException parses JSON message field as fallback', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {'message': 'Unprocessable entity'},
        ),
      );

      final apiError = ApiError.fromDioException(dioException);
      expect(apiError.message, equals('Unprocessable entity'));
    });

    test('fromDioException maps connection timeouts and errors', () {
      final timeoutException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        ApiError.fromDioException(timeoutException).message,
        equals('Connection timed out'),
      );

      final connectionException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final error = ApiError.fromDioException(connectionException);
      expect(error.isNetworkError, isTrue);
      expect(error.message, contains('Unable to connect to server'));
    });

    test('toResult returns Failure holding this ApiError', () {
      const error = ApiError(message: 'failed', statusCode: 500);
      final result = error.toResult<String>();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, equals('failed'));
    });
  });
}
