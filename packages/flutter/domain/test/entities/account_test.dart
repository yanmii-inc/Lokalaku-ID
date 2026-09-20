import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Account', () {
    final now = DateTime.utc(2026, 9, 20, 10, 0, 0);

    test('valid consumer account without cluster id validates cleanly', () {
      final account = Account(
        id: 'acc-1',
        phone: '+628123456789',
        email: 'consumer@example.com',
        role: Role.consumer,
        status: AccountStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.validate(), isNull);
      expect(account.canTransact, isTrue);
    });

    test('merchant account requires village_cluster_id', () {
      final invalidMerchant = Account(
        id: 'acc-2',
        phone: '+628123456789',
        role: Role.merchant,
        status: AccountStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        invalidMerchant.validate(),
        equals("role 'merchant' requires a village_cluster_id"),
      );

      final validMerchant = invalidMerchant.copyWith(villageClusterId: 'vc-101');
      expect(validMerchant.validate(), isNull);
    });

    test('backoffice_admin requires village_cluster_id', () {
      final admin = Account(
        id: 'acc-3',
        phone: '+628123456789',
        role: Role.backofficeAdmin,
        status: AccountStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        admin.validate(),
        equals("role 'backoffice_admin' requires a village_cluster_id"),
      );
    });

    test('missing phone number fails validation', () {
      final account = Account(
        id: 'acc-4',
        phone: '   ',
        role: Role.consumer,
        status: AccountStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.validate(), equals('phone number is required'));
    });

    test('fromJson and toJson round-trip with snake_case keys', () {
      final json = {
        'id': 'acc-10',
        'village_cluster_id': 'cluster-alpha',
        'phone': '+628999888777',
        'email': 'merchant@lokalaku.id',
        'role': 'merchant',
        'status': 'active',
        'created_at': '2026-09-20T10:00:00.000Z',
        'updated_at': '2026-09-20T10:00:00.000Z',
      };

      final account = Account.fromJson(json);

      expect(account.id, equals('acc-10'));
      expect(account.villageClusterId, equals('cluster-alpha'));
      expect(account.phone, equals('+628999888777'));
      expect(account.role, equals(Role.merchant));
      expect(account.status, equals(AccountStatus.active));

      final serialized = account.toJson();
      expect(serialized['village_cluster_id'], equals('cluster-alpha'));
      expect(serialized['role'], equals('merchant'));
      expect(serialized['status'], equals('active'));
    });
  });
}
