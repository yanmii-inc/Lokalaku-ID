import 'package:lokalaku_domain/lokalaku_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AccountStatus', () {
    test('isActive returns true only for active', () {
      expect(AccountStatus.active.isActive, isTrue);
      expect(AccountStatus.pending.isActive, isFalse);
      expect(AccountStatus.suspended.isActive, isFalse);
      expect(AccountStatus.deactivated.isActive, isFalse);
    });

    test('isTerminal returns true only for deactivated', () {
      expect(AccountStatus.deactivated.isTerminal, isTrue);
      expect(AccountStatus.active.isTerminal, isFalse);
      expect(AccountStatus.pending.isTerminal, isFalse);
      expect(AccountStatus.suspended.isTerminal, isFalse);
    });

    test('canTransitionTo enforces legal state machine edges', () {
      // Pending transitions
      expect(AccountStatus.pending.canTransitionTo(AccountStatus.active), isTrue);
      expect(AccountStatus.pending.canTransitionTo(AccountStatus.deactivated), isTrue);
      expect(AccountStatus.pending.canTransitionTo(AccountStatus.suspended), isFalse);
      expect(AccountStatus.pending.canTransitionTo(AccountStatus.pending), isFalse);

      // Active transitions
      expect(AccountStatus.active.canTransitionTo(AccountStatus.suspended), isTrue);
      expect(AccountStatus.active.canTransitionTo(AccountStatus.deactivated), isTrue);
      expect(AccountStatus.active.canTransitionTo(AccountStatus.pending), isFalse);
      expect(AccountStatus.active.canTransitionTo(AccountStatus.active), isFalse);

      // Suspended transitions
      expect(AccountStatus.suspended.canTransitionTo(AccountStatus.active), isTrue);
      expect(AccountStatus.suspended.canTransitionTo(AccountStatus.deactivated), isTrue);
      expect(AccountStatus.suspended.canTransitionTo(AccountStatus.pending), isFalse);
      expect(AccountStatus.suspended.canTransitionTo(AccountStatus.suspended), isFalse);

      // Deactivated (terminal) transitions
      expect(AccountStatus.deactivated.canTransitionTo(AccountStatus.active), isFalse);
      expect(AccountStatus.deactivated.canTransitionTo(AccountStatus.suspended), isFalse);
      expect(AccountStatus.deactivated.canTransitionTo(AccountStatus.pending), isFalse);
      expect(AccountStatus.deactivated.canTransitionTo(AccountStatus.deactivated), isFalse);
    });

    test('tryParse and fromString handle values correctly', () {
      expect(AccountStatus.tryParse('pending'), equals(AccountStatus.pending));
      expect(AccountStatus.tryParse('active'), equals(AccountStatus.active));
      expect(AccountStatus.tryParse('invalid'), isNull);

      expect(AccountStatus.fromString('active'), equals(AccountStatus.active));
      expect(() => AccountStatus.fromString('invalid'), throwsArgumentError);
    });
  });
}
