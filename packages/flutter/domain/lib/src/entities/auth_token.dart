import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_token.freezed.dart';
part 'auth_token.g.dart';

/// Represents an authenticated JWT token pair returned by the auth API.
@freezed
class AuthToken with _$AuthToken {
  const AuthToken._();

  const factory AuthToken({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in') required int expiresIn,
    @JsonKey(name: 'token_type') @Default('Bearer') String tokenType,
    @JsonKey(name: 'issued_at') DateTime? issuedAt,
  }) = _AuthToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) => _$AuthTokenFromJson(json);

  /// Resolved issuance timestamp, defaulting to [DateTime.now()] if omitted.
  DateTime get effectiveIssuedAt => issuedAt ?? DateTime.now();

  /// Computes the absolute expiration timestamp based on issuance and [expiresIn].
  DateTime get expiresAt => effectiveIssuedAt.add(Duration(seconds: expiresIn));

  /// Returns true if the access token has passed its expiration time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Returns true if the access token expires within [threshold] (default 5 minutes).
  bool expiresSoon([Duration threshold = const Duration(minutes: 5)]) =>
      DateTime.now().add(threshold).isAfter(expiresAt);
}
