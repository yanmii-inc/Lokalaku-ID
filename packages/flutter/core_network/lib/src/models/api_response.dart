/// Generic successful network response envelope.
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
  });

  /// Deserialized response payload.
  final T data;

  /// HTTP response status code.
  final int statusCode;

  /// HTTP response headers.
  final Map<String, List<String>> headers;

  @override
  String toString() => 'ApiResponse(statusCode: $statusCode, data: $data)';
}
