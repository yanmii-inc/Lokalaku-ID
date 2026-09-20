/// Represents the outcome of an offline PIN challenge verification.
sealed class PinResult {
  const PinResult();

  /// PIN was verified successfully.
  const factory PinResult.success() = PinSuccess;

  /// Invalid PIN with number of [remainingAttempts] before lockout.
  const factory PinResult.invalidPin({
    required int remainingAttempts,
  }) = PinInvalid;

  /// Account locked out due to exceeding maximum failed attempts.
  const factory PinResult.lockedOut({
    required Duration lockDuration,
  }) = PinLockedOut;

  /// No PIN has been configured on this device.
  const factory PinResult.notSet() = PinNotSet;

  bool get isSuccess => this is PinSuccess;
  bool get isLockedOut => this is PinLockedOut;
}

final class PinSuccess extends PinResult {
  const PinSuccess();

  @override
  bool operator ==(Object other) => other is PinSuccess;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'PinResult.success()';
}

final class PinInvalid extends PinResult {
  const PinInvalid({required this.remainingAttempts});

  final int remainingAttempts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinInvalid && other.remainingAttempts == remainingAttempts);

  @override
  int get hashCode => remainingAttempts.hashCode;

  @override
  String toString() => 'PinResult.invalidPin(remainingAttempts: $remainingAttempts)';
}

final class PinLockedOut extends PinResult {
  const PinLockedOut({required this.lockDuration});

  final Duration lockDuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PinLockedOut && other.lockDuration == lockDuration);

  @override
  int get hashCode => lockDuration.hashCode;

  @override
  String toString() => 'PinResult.lockedOut(duration: ${lockDuration.inMinutes}m)';
}

final class PinNotSet extends PinResult {
  const PinNotSet();

  @override
  bool operator ==(Object other) => other is PinNotSet;

  @override
  int get hashCode => 1;

  @override
  String toString() => 'PinResult.notSet()';
}
