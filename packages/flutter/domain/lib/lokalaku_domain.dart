/// Lokalaku domain layer — pure Dart entities and value objects.
///
/// No Flutter, no network, no storage.
/// All other packages and apps depend on this; it depends on nothing internal.
library lokalaku_domain;

// Result type (Rule 6 in packages/flutter/AGENTS.md)
export 'src/result.dart';

// Enums
export 'src/enums/account_status.dart';
export 'src/enums/role.dart';

// Entities
export 'src/entities/account.dart';
export 'src/entities/auth_token.dart';
export 'src/entities/session.dart';
