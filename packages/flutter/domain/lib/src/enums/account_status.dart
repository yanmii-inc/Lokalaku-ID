import 'package:json_annotation/json_annotation.dart';

part 'account_status.g.dart';

/// AccountStatus defines the lifecycle state of an account.
@JsonEnum(alwaysCreate: true)
enum AccountStatus {
  @JsonValue('pending')
  pending('pending'),

  @JsonValue('active')
  active('active'),

  @JsonValue('suspended')
  suspended('suspended'),

  @JsonValue('deactivated')
  deactivated('deactivated');

  const AccountStatus(this.value);

  /// The raw string representation used in database and API payloads.
  final String value;

  /// Returns true if the account is in good standing and permitted to perform transactions.
  bool get isActive => this == AccountStatus.active;

  /// Returns true if the account is in a terminal state that cannot transition further.
  bool get isTerminal => this == AccountStatus.deactivated;

  /// Validates whether a state transition from `this` to [next] is permitted.
  ///
  /// Legal transition edges:
  /// - `pending`     -> `active`, `deactivated`
  /// - `active`      -> `suspended`, `deactivated`
  /// - `suspended`   -> `active`, `deactivated`
  /// - `deactivated` -> none (terminal)
  bool canTransitionTo(AccountStatus next) {
    if (this == next) return false;

    return switch (this) {
      AccountStatus.pending => next == AccountStatus.active || next == AccountStatus.deactivated,
      AccountStatus.active => next == AccountStatus.suspended || next == AccountStatus.deactivated,
      AccountStatus.suspended => next == AccountStatus.active || next == AccountStatus.deactivated,
      AccountStatus.deactivated => false,
    };
  }

  /// Parse a string into an [AccountStatus], or return `null` if unrecognized.
  static AccountStatus? tryParse(String? raw) {
    if (raw == null) return null;
    for (final status in AccountStatus.values) {
      if (status.value == raw) return status;
    }
    return null;
  }

  /// Parse a string into an [AccountStatus], throwing [ArgumentError] if unrecognized.
  static AccountStatus fromString(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      throw ArgumentError.value(raw, 'status', 'Unknown account status value');
    }
    return parsed;
  }
}
