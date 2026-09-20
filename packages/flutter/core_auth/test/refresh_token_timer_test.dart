import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokalaku_core_auth/lokalaku_core_auth.dart';
import 'package:lokalaku_domain/lokalaku_domain.dart';

void main() {
  group('RefreshTokenTimer', () {
    test('schedules refresh to trigger 3 minutes before expiration', () {
      fakeAsync((async) {
        var refreshTriggered = false;
        final timer = RefreshTokenTimer(
          onRefresh: () async {
            refreshTriggered = true;
          },
        );

        // Token expires in 10 minutes
        final token = AuthToken(
          accessToken: 'jwt',
          refreshToken: 'refresh',
          expiresIn: 600,
          issuedAt: DateTime.now(),
        );

        // Expected fire time: 10m - 3m = 7m (420s)
        timer.schedule(token, leadTime: const Duration(minutes: 3));
        expect(timer.isActive, isTrue);

        // Advance 6 minutes: should not trigger yet
        async.elapse(const Duration(minutes: 6));
        expect(refreshTriggered, isFalse);

        // Advance 1 more minute (total 7m): should trigger
        async.elapse(const Duration(minutes: 1));
        expect(refreshTriggered, isTrue);
        expect(timer.isActive, isFalse);
      });
    });

    test('fires immediately if token is already within leadTime window', () {
      var refreshTriggered = false;
      final timer = RefreshTokenTimer(
        onRefresh: () async {
          refreshTriggered = true;
        },
      );

      // Token expires in 2 minutes, which is <= 3m lead time
      final token = AuthToken(
        accessToken: 'jwt',
        refreshToken: 'refresh',
        expiresIn: 120,
        issuedAt: DateTime.now(),
      );

      timer.schedule(token, leadTime: const Duration(minutes: 3));
      expect(refreshTriggered, isTrue);
      expect(timer.isActive, isFalse);
    });

    test('cancel aborts pending timer', () {
      fakeAsync((async) {
        var refreshTriggered = false;
        final timer = RefreshTokenTimer(
          onRefresh: () async {
            refreshTriggered = true;
          },
        );

        final token = AuthToken(
          accessToken: 'jwt',
          refreshToken: 'refresh',
          expiresIn: 600,
          issuedAt: DateTime.now(),
        );

        timer.schedule(token);
        expect(timer.isActive, isTrue);

        timer.cancel();
        expect(timer.isActive, isFalse);

        async.elapse(const Duration(minutes: 10));
        expect(refreshTriggered, isFalse);
      });
    });
  });
}
