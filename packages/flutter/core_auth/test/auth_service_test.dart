import 'package:flutter_test/flutter_test.dart';
import 'package:lokalaku_core_auth/lokalaku_core_auth.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

import 'mocks.dart';

void main() {
  group('AuthService', () {
    late InMemoryTokenStorage storage;
    late FakeAuthApiClient client;
    late AuthService authService;

    final testAccount = Account(
      id: 'acc-101',
      phone: '+6281234567890',
      role: Role.merchant,
      status: AccountStatus.active,
      villageClusterId: 'vc-bali',
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );

    final testToken = AuthToken(
      accessToken: 'access.jwt.sample',
      refreshToken: 'refresh-uuid-sample',
      expiresIn: 900,
      issuedAt: DateTime.now(),
    );

    setUp(() {
      storage = InMemoryTokenStorage();
      client = FakeAuthApiClient();
      authService = AuthService(
        tokenStorage: storage,
        client: client,
      );
    });

    tearDown(() {
      authService.dispose();
    });

    test('initial state is unauthenticated', () {
      expect(authService.state, equals(const AuthState.unauthenticated()));
    });

    test('login success stores tokens, transitions to authenticated, schedules refresh', () async {
      client.loginResult = Result.success((token: testToken, account: testAccount));

      final result = await authService.login(
        const LoginRequest(identifier: '+6281234567890', password: 'password123'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(testAccount));

      expect(
        authService.state,
        equals(AuthState.authenticated(account: testAccount, token: testToken)),
      );

      // Verify stored in storage
      expect(await storage.readAuthToken(), equals(testToken));
      expect(await storage.readAccount(), equals(testAccount));
    });

    test('login failure transitions to unauthenticated with error message', () async {
      client.loginResult = const Result.failure('Invalid credentials');

      final result = await authService.login(
        const LoginRequest(identifier: '+6281234567890', password: 'wrong'),
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, equals('Invalid credentials'));

      expect(
        authService.state,
        equals(const AuthState.unauthenticated(message: 'Invalid credentials')),
      );
    });

    test('restoreSession enters authenticated if stored token is unexpired', () async {
      await storage.saveAuthToken(testToken);
      await storage.saveAccount(testAccount);

      final result = await authService.restoreSession();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(testAccount));
      expect(
        authService.state,
        equals(AuthState.authenticated(account: testAccount, token: testToken)),
      );
    });

    test('restoreSession triggers refresh if stored token is expired', () async {
      final expiredToken = testToken.copyWith(
        issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      await storage.saveAuthToken(expiredToken);
      await storage.saveAccount(testAccount);

      final freshToken = testToken.copyWith(
        accessToken: 'fresh.access.token',
        refreshToken: 'fresh.refresh.token',
      );
      client.refreshResult = Result.success((token: freshToken, account: testAccount));

      final result = await authService.restoreSession();

      expect(result.isSuccess, isTrue);
      expect(client.refreshCalls, equals(1));
      expect(await storage.readAuthToken(), equals(freshToken));
      expect(
        authService.state,
        equals(AuthState.authenticated(account: testAccount, token: freshToken)),
      );
    });

    test('logout revokes remote token, clears storage, transitions to unauthenticated', () async {
      await storage.saveAuthToken(testToken);
      await storage.saveAccount(testAccount);

      final result = await authService.logout();

      expect(result.isSuccess, isTrue);
      expect(client.logoutCalls, equals(1));
      expect(await storage.readAuthToken(), isNull);
      expect(await storage.readAccount(), isNull);
      expect(authService.state, equals(const AuthState.unauthenticated()));
    });

    test('setPin validates 6 digits and stores correctly', () async {
      final invalidResult = await authService.setPin('12345');
      expect(invalidResult.isFailure, isTrue);
      expect(invalidResult.errorOrNull, equals('PIN must be exactly 6 digits'));

      final nonDigitResult = await authService.setPin('12345a');
      expect(nonDigitResult.isFailure, isTrue);

      final validResult = await authService.setPin('123456');
      expect(validResult.isSuccess, isTrue);
      expect(await storage.hasPin(), isTrue);
    });

    test('unlockWithPin sets OfflineGrace session on correct PIN', () async {
      await storage.saveAccount(testAccount);
      await authService.setPin('123456');

      final result = await authService.unlockWithPin('123456');

      expect(result.isSuccess, isTrue);
      expect(authService.state.isOfflineGrace, isTrue);

      final offlineState = authService.state as OfflineGrace;
      expect(offlineState.account, equals(testAccount));
      expect(offlineState.isExpired, isFalse);
    });

    test('unlockWithPin fails on incorrect PIN without changing state', () async {
      await storage.saveAccount(testAccount);
      await authService.setPin('123456');

      final result = await authService.unlockWithPin('999999');

      expect(result, equals(const PinResult.invalidPin(remainingAttempts: 4)));
      expect(authService.state, equals(const AuthState.unauthenticated()));
    });
  });
}
