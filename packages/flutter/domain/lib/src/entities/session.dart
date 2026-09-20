import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Represents an active or historical user session record.
@freezed
class Session with _$Session {
  const Session._();

  const factory Session({
    required String id,
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'revoked_at') DateTime? revokedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  /// Returns true if the session is unrevoked and not expired.
  bool get isActive => revokedAt == null && DateTime.now().isBefore(expiresAt);
}
