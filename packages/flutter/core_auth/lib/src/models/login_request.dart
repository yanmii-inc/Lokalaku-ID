/// Encapsulates user login credentials (phone/email + password).
class LoginRequest {
  const LoginRequest({
    required this.identifier,
    required this.password,
  });

  /// User phone number (e.g. +628123456789) or email.
  final String identifier;

  /// Raw password string.
  final String password;

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
      };

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
        identifier: json['identifier'] as String,
        password: json['password'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoginRequest && other.identifier == identifier && other.password == password);

  @override
  int get hashCode => Object.hash(identifier, password);
}
