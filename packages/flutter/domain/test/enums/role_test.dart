import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Role', () {
    test('cluster-bound roles identified correctly', () {
      expect(Role.merchant.isClusterBound, isTrue);
      expect(Role.backofficeAdmin.isClusterBound, isTrue);

      expect(Role.consumer.isClusterBound, isFalse);
      expect(Role.courier.isClusterBound, isFalse);
      expect(Role.wholesaler.isClusterBound, isFalse);
      expect(Role.superadmin.isClusterBound, isFalse);
    });

    test('operator roles identified correctly', () {
      expect(Role.backofficeAdmin.isOperator, isTrue);
      expect(Role.superadmin.isOperator, isTrue);

      expect(Role.consumer.isOperator, isFalse);
      expect(Role.merchant.isOperator, isFalse);
    });

    test('tryParse parses valid strings and returns null for invalid', () {
      expect(Role.tryParse('consumer'), equals(Role.consumer));
      expect(Role.tryParse('merchant'), equals(Role.merchant));
      expect(Role.tryParse('courier'), equals(Role.courier));
      expect(Role.tryParse('wholesaler'), equals(Role.wholesaler));
      expect(Role.tryParse('backoffice_admin'), equals(Role.backofficeAdmin));
      expect(Role.tryParse('superadmin'), equals(Role.superadmin));

      expect(Role.tryParse('unknown'), isNull);
      expect(Role.tryParse(null), isNull);
    });

    test('fromString parses valid string and throws on invalid', () {
      expect(Role.fromString('consumer'), equals(Role.consumer));
      expect(() => Role.fromString('invalid'), throwsArgumentError);
    });
  });
}
