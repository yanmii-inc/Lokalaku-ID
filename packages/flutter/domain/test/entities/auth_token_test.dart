import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AuthToken', () {
    test('computes expiration and validity correctly', () {
      final issued = DateTime.now();
      final token = AuthToken(
        accessToken: 'access.jwt.token',
        refreshToken: 'refresh-token-uuid',
        expiresIn: 3600, // 1 hour
        issuedAt: issued,
      );

      expect(token.expiresAt, equals(issued.add(const Duration(seconds: 3600))));
      expect(token.isExpired, isFalse);
      expect(token.expiresSoon(const Duration(minutes: 5)), isFalse);
      expect(token.expiresSoon(const Duration(minutes: 70)), isTrue);
    });

    test('expired token returns isExpired true', () {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      final expiredToken = AuthToken(
        accessToken: 'expired.jwt.token',
        refreshToken: 'expired-refresh',
        expiresIn: 3600,
        issuedAt: past,
      );

      expect(expiredToken.isExpired, isTrue);
    });

    test('fromJson and toJson round-trip with snake_case keys', () {
      final json = {
        'access_token': 'jwt.token.val',
        'refresh_token': 'refresh.token.val',
        'expires_in': 900,
        'token_type': 'Bearer',
        'issued_at': '2026-09-20T08:00:00.000Z',
      };

      final token = AuthToken.fromJson(json);

      expect(token.accessToken, equals('jwt.token.val'));
      expect(token.refreshToken, equals('refresh.token.val'));
      expect(token.expiresIn, equals(900));
      expect(token.tokenType, equals('Bearer'));
      expect(token.issuedAt, equals(DateTime.parse('2026-09-20T08:00:00.000Z')));

      final serialized = token.toJson();
      expect(serialized['access_token'], equals('jwt.token.val'));
      expect(serialized['refresh_token'], equals('refresh.token.val'));
      expect(serialized['expires_in'], equals(900));
    });
  });
}
