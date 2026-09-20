// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) => _$AccountImpl(
      id: json['id'] as String,
      villageClusterId: json['village_cluster_id'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: $enumDecode(_$RoleEnumMap, json['role']),
      status: $enumDecode(_$AccountStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) => <String, dynamic>{
      'id': instance.id,
      'village_cluster_id': instance.villageClusterId,
      'phone': instance.phone,
      'email': instance.email,
      'role': _$RoleEnumMap[instance.role]!,
      'status': _$AccountStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$RoleEnumMap = {
  Role.consumer: 'consumer',
  Role.merchant: 'merchant',
  Role.courier: 'courier',
  Role.wholesaler: 'wholesaler',
  Role.backofficeAdmin: 'backoffice_admin',
  Role.superadmin: 'superadmin',
};

const _$AccountStatusEnumMap = {
  AccountStatus.pending: 'pending',
  AccountStatus.active: 'active',
  AccountStatus.suspended: 'suspended',
  AccountStatus.deactivated: 'deactivated',
};
