import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Represents the global authentication and session state across the app.
sealed class AuthState {
  const AuthState();

  /// User is not logged in.
  const factory AuthState.unauthenticated({String? message}) = Unauthenticated;

  /// User authentication or token refresh is currently in flight.
  const factory AuthState.authenticating() = Authenticating;

  /// User is fully authenticated with a valid online session.
  const factory AuthState.authenticated({
    required Account account,
    required AuthToken token,
  }) = Authenticated;

  /// Merchant or operator is operating in offline grace mode (unlocked via PIN).
  const factory AuthState.offlineGrace({
    required Account account,
    required DateTime graceExpiresAt,
  }) = OfflineGrace;

  /// Returns true if currently authenticated with a valid online token.
  bool get isAuthenticated => this is Authenticated;

  /// Returns true if currently operating in offline grace mode.
  bool get isOfflineGrace => this is OfflineGrace;

  /// Returns true if user has access to transacting features (authenticated or offline grace).
  bool get hasActiveSession => isAuthenticated || isOfflineGrace;

  /// Resolves the current account, if any.
  Account? get accountOrNull => switch (this) {
        Authenticated(:final account) => account,
        OfflineGrace(:final account) => account,
        _ => null,
      };

  /// Resolves the current auth token, if any.
  AuthToken? get tokenOrNull => switch (this) {
        Authenticated(:final token) => token,
        _ => null,
      };
}

/// Unauthenticated state.
final class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});

  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Unauthenticated && other.message == message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => message != null
      ? 'AuthState.unauthenticated(message: "$message")'
      : 'AuthState.unauthenticated()';
}

/// Authentication / token refresh in progress.
final class Authenticating extends AuthState {
  const Authenticating();

  @override
  bool operator ==(Object other) => other is Authenticating;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'AuthState.authenticating()';
}

/// Fully authenticated online state.
final class Authenticated extends AuthState {
  const Authenticated({
    required this.account,
    required this.token,
  });

  final Account account;
  final AuthToken token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Authenticated && other.account == account && other.token == token);

  @override
  int get hashCode => Object.hash(account, token);

  @override
  String toString() =>
      'AuthState.authenticated(accountId: "${account.id}", role: ${account.role.value})';
}

/// Offline grace state unlocked by PIN during network outage.
final class OfflineGrace extends AuthState {
  const OfflineGrace({
    required this.account,
    required this.graceExpiresAt,
  });

  final Account account;
  final DateTime graceExpiresAt;

  bool get isExpired => DateTime.now().isAfter(graceExpiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineGrace && other.account == account && other.graceExpiresAt == graceExpiresAt);

  @override
  int get hashCode => Object.hash(account, graceExpiresAt);

  @override
  String toString() =>
      'AuthState.offlineGrace(accountId: "${account.id}", expiresAt: $graceExpiresAt)';
}
