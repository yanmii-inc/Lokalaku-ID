import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lokalaku_domain/src/enums/account_status.dart';
import 'package:lokalaku_domain/src/enums/role.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Represents a user account in the Lokalaku platform across all personas.
@freezed
class Account with _$Account {
  const Account._();

  const factory Account({
    required String id,
    @JsonKey(name: 'village_cluster_id') String? villageClusterId,
    required String phone,
    String? email,
    required Role role,
    required AccountStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

  /// Validates domain entity invariants.
  /// Returns `null` if valid, or a descriptive error message if invalid.
  String? validate() {
    if (phone.trim().isEmpty) {
      return 'phone number is required';
    }

    if (role.isClusterBound && (villageClusterId == null || villageClusterId!.trim().isEmpty)) {
      return "role '${role.value}' requires a village_cluster_id";
    }

    return null;
  }

  /// Returns true if this account is active and permitted to perform business actions.
  bool get canTransact => status == AccountStatus.active;
}
