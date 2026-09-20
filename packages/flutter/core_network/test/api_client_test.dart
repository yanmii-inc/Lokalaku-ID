import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lokalaku_core_network/lokalaku_core_network.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ApiClient', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient(baseUrl: 'https://api.lokalaku.id');
    });

    test('get returns Result.success on 200 with fromJson parsing', () async {
      client.dio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString(
          '{"id": "item-1", "name": "Beras Rojolele"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await client.get<Map<String, dynamic>>(
        '/products/item-1',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?['id'], equals('item-1'));
      expect(result.dataOrNull?['name'], equals('Beras Rojolele'));
    });

    test('post returns Result.failure on 400 error', () async {
      client.dio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString(
          '{"error": "Invalid payload", "code": "ERR_VALIDATION"}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await client.post<Map<String, dynamic>>(
        '/products',
        data: {'name': ''},
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, equals('Invalid payload'));
      final failure = result as Failure<Map<String, dynamic>>;
      expect((failure.error as ApiError).code, equals('ERR_VALIDATION'));
    });

    test('post returns Result.success on 204 No Content', () async {
      client.dio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString('', 204);
      });

      final result = await client.delete<void>('/items/1');
      expect(result.isSuccess, isTrue);
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
