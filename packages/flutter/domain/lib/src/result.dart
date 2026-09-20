/// A robust, type-safe Result type for functional error handling across
/// package boundaries (Rule 6 in packages/flutter/AGENTS.md).
sealed class Result<T> {
  const Result();

  /// Creates a successful result holding [data].
  const factory Result.success(T data) = Success<T>;

  /// Creates a failed result holding an error [message] and optional details.
  const factory Result.failure(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) = Failure<T>;

  /// Returns true if this instance represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this instance represents a failed outcome.
  bool get isFailure => this is Failure<T>;

  /// Returns the unwrapped data if [Success], or `null` if [Failure].
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Returns the error message if [Failure], or `null` if [Success].
  String? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final message) => message,
      };

  /// Pattern-matches over [Success] and [Failure] branches.
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error, StackTrace? stackTrace) failure,
  }) =>
      switch (this) {
        Success(:final data) => success(data),
        Failure(:final message, :final error, :final stackTrace) =>
          failure(message, error, stackTrace),
      };

  /// Transforms the inner value with [fn] if [Success], otherwise forwards [Failure].
  Result<R> map<R>(R Function(T data) fn) => switch (this) {
        Success(:final data) => Result.success(fn(data)),
        Failure(:final message, :final error, :final stackTrace) =>
          Result.failure(message, error: error, stackTrace: stackTrace),
      };
}

/// A successful [Result] containing [data].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Result.success($data)';
}

/// A failed [Result] containing [message] and optional underlying [error] / [stackTrace].
final class Failure<T> extends Result<T> {
  const Failure(
    this.message, {
    this.error,
    this.stackTrace,
  });

  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> && other.message == message && other.error == error);

  @override
  int get hashCode => Object.hash(message, error);

  @override
  String toString() =>
      error != null ? 'Result.failure("$message", error: $error)' : 'Result.failure("$message")';
}
