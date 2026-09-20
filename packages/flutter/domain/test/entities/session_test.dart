import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Session', () {
    final now = DateTime.now();

    test('active unrevoked unexpired session returns isActive true', () {
      final session = Session(
        id: 'sess-1',
        accountId: 'acc-1',
        userAgent: 'Dart/3.12 (macOS)',
        ipAddress: '127.0.0.1',
        expiresAt: now.add(const Duration(days: 30)),
        createdAt: now,
      );

      expect(session.isActive, isTrue);
    });

    test('revoked session returns isActive false', () {
      final session = Session(
        id: 'sess-2',
        accountId: 'acc-1',
        expiresAt: now.add(const Duration(days: 30)),
        revokedAt: now,
        createdAt: now.subtract(const Duration(days: 1)),
      );

      expect(session.isActive, isFalse);
    });

    test('expired session returns isActive false', () {
      final session = Session(
        id: 'sess-3',
        accountId: 'acc-1',
        expiresAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 30)),
      );

      expect(session.isActive, isFalse);
    });

    test('fromJson and toJson round-trip with snake_case keys', () {
      final json = {
        'id': 'sess-4',
        'account_id': 'acc-10',
        'user_agent': 'Mozilla/5.0',
        'ip_address': '192.168.1.1',
        'expires_at': '2026-10-20T10:00:00.000Z',
        'revoked_at': null,
        'created_at': '2026-09-20T10:00:00.000Z',
      };

      final session = Session.fromJson(json);

      expect(session.id, equals('sess-4'));
      expect(session.accountId, equals('acc-10'));
      expect(session.userAgent, equals('Mozilla/5.0'));
      expect(session.ipAddress, equals('192.168.1.1'));

      final serialized = session.toJson();
      expect(serialized['account_id'], equals('acc-10'));
      expect(serialized['user_agent'], equals('Mozilla/5.0'));
      expect(serialized['ip_address'], equals('192.168.1.1'));
    });
  });
}
