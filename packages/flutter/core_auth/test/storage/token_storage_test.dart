import 'package:flutter_test/flutter_test.dart';
import 'package:lokalaku_core_auth/lokalaku_core_auth.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

import '../mocks.dart';

void main() {
  group('InMemoryTokenStorage', () {
    late TokenStorage storage;

    setUp(() {
      storage = InMemoryTokenStorage();
    });

    test('saves and reads AuthToken correctly', () async {
      final token = AuthToken(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        expiresIn: 900,
        issuedAt: DateTime.utc(2026, 9, 20, 10, 0),
      );

      await storage.saveAuthToken(token);
      final retrieved = await storage.readAuthToken();

      expect(retrieved, equals(token));

      await storage.clearAuthToken();
      expect(await storage.readAuthToken(), isNull);
    });

    test('saves and reads Account correctly', () async {
      final account = Account(
        id: 'acc-1',
        phone: '+628123456789',
        role: Role.merchant,
        status: AccountStatus.active,
        villageClusterId: 'vc-alpha',
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );

      await storage.saveAccount(account);
      final retrieved = await storage.readAccount();

      expect(retrieved, equals(account));

      await storage.clearAccount();
      expect(await storage.readAccount(), isNull);
    });

    test('offline PIN lifecycle: set, verify, incorrect attempts, lockout', () async {
      expect(await storage.hasPin(), isFalse);
      expect(await storage.verifyPin('123456'), equals(const PinResult.notSet()));

      await storage.setPin('123456');
      expect(await storage.hasPin(), isTrue);

      // Correct PIN
      expect(await storage.verifyPin('123456'), equals(const PinResult.success()));

      // 1st wrong attempt
      final attempt1 = await storage.verifyPin('999999');
      expect(attempt1, equals(const PinResult.invalidPin(remainingAttempts: 4)));

      // 2nd, 3rd, 4th wrong attempts
      await storage.verifyPin('999999');
      await storage.verifyPin('999999');
      await storage.verifyPin('999999');

      // 5th wrong attempt triggers lockout
      final lockout = await storage.verifyPin('999999');
      expect(lockout.isLockedOut, isTrue);

      // While locked out, even the correct PIN fails with lockedOut
      final lockedAttempt = await storage.verifyPin('123456');
      expect(lockedAttempt.isLockedOut, isTrue);

      // Clear PIN clears lockout and pin
      await storage.clearPin();
      expect(await storage.hasPin(), isFalse);
    });

    test('clearAll clears tokens, accounts, and PINs', () async {
      await storage.saveAuthToken(
        AuthToken(
          accessToken: 'a',
          refreshToken: 'b',
          expiresIn: 100,
          issuedAt: DateTime.now(),
        ),
      );
      await storage.saveAccount(
        Account(
          id: 'acc',
          phone: '+62',
          role: Role.consumer,
          status: AccountStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await storage.setPin('654321');

      await storage.clearAll();

      expect(await storage.readAuthToken(), isNull);
      expect(await storage.readAccount(), isNull);
      expect(await storage.hasPin(), isFalse);
    });
  });
}
