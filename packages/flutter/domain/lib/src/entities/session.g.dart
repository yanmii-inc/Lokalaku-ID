// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionImpl _$$SessionImplFromJson(Map<String, dynamic> json) => _$SessionImpl(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      revokedAt: json['revoked_at'] == null ? null : DateTime.parse(json['revoked_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$SessionImplToJson(_$SessionImpl instance) => <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'user_agent': instance.userAgent,
      'ip_address': instance.ipAddress,
      'expires_at': instance.expiresAt.toIso8601String(),
      'revoked_at': instance.revokedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
