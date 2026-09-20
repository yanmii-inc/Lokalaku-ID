import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Result<T>', () {
    test('Success holds data and returns true for isSuccess', () {
      const result = Result.success('lokalaku');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('lokalaku'));
      expect(result.errorOrNull, isNull);
    });

    test('Failure holds message and returns true for isFailure', () {
      final exception = Exception('db down');
      final result = Result<int>.failure('operation failed', error: exception);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, equals('operation failed'));
      expect((result as Failure<int>).error, equals(exception));
    });

    test('when matches Success and Failure correctly', () {
      const Result<int> success = Result.success(42);
      final successValue = success.when(
        success: (data) => 'got $data',
        failure: (msg, _, __) => 'failed: $msg',
      );
      expect(successValue, equals('got 42'));

      const Result<int> failure = Result.failure('not found');
      final failureValue = failure.when(
        success: (data) => 'got $data',
        failure: (msg, _, __) => 'failed: $msg',
      );
      expect(failureValue, equals('failed: not found'));
    });

    test('map transforms success and forwards failure', () {
      const Result<int> success = Result.success(10);
      final mappedSuccess = success.map((data) => data * 2);

      expect(mappedSuccess.dataOrNull, equals(20));

      const Result<int> failure = Result.failure('error');
      final mappedFailure = failure.map((data) => data * 2);

      expect(mappedFailure.isFailure, isTrue);
      expect(mappedFailure.errorOrNull, equals('error'));
    });

    test('equality works as value object', () {
      expect(const Result.success('a'), equals(const Result.success('a')));
      expect(const Result.success('a'), isNot(equals(const Result.success('b'))));
      expect(
        const Result<int>.failure('fail'),
        equals(const Result<int>.failure('fail')),
      );
    });
  });
}
