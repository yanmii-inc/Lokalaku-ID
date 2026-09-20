import 'package:json_annotation/json_annotation.dart';

part 'role.g.dart';

/// Role defines the user account's permission scope and persona within the platform.
@JsonEnum(alwaysCreate: true)
enum Role {
  @JsonValue('consumer')
  consumer('consumer'),

  @JsonValue('merchant')
  merchant('merchant'),

  @JsonValue('courier')
  courier('courier'),

  @JsonValue('wholesaler')
  wholesaler('wholesaler'),

  @JsonValue('backoffice_admin')
  backofficeAdmin('backoffice_admin'),

  @JsonValue('superadmin')
  superadmin('superadmin');

  const Role(this.value);

  /// The raw string representation used in database and API payloads.
  final String value;

  /// Returns true if this role is strictly bound to a single `village_cluster_id`.
  ///
  /// Per data sovereignty rules:
  /// - `merchant` and `backoffice_admin` are cluster-bound.
  /// - `consumer`, `courier`, `wholesaler`, and `superadmin` operate across clusters.
  bool get isClusterBound => this == Role.merchant || this == Role.backofficeAdmin;

  /// Returns true if this role is an administrative operator role.
  bool get isOperator => this == Role.backofficeAdmin || this == Role.superadmin;

  /// Returns true if this role is a trade participant (merchant, wholesaler, or courier).
  bool get isSupplyChainRole =>
      this == Role.merchant || this == Role.wholesaler || this == Role.courier;

  /// Parse a string into a [Role], or return `null` if unrecognized.
  static Role? tryParse(String? raw) {
    if (raw == null) return null;
    for (final role in Role.values) {
      if (role.value == raw) return role;
    }
    return null;
  }

  /// Parse a string into a [Role], throwing [ArgumentError] if unrecognized.
  static Role fromString(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      throw ArgumentError.value(raw, 'role', 'Unknown role value');
    }
    return parsed;
  }
}
