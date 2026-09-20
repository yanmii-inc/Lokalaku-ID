import 'dart:async';

import 'package:lokalaku_domain/lokalaku_domain.dart';

/// Manages proactive background token refresh timers.
///
/// Per ADR-003, proactive refresh fires at ≤3 minutes before access token expiry,
/// preventing mid-route courier telemetry disruptions and checkout auth errors.
class RefreshTokenTimer {
  RefreshTokenTimer({
    required Future<void> Function() onRefresh,
  }) : _onRefresh = onRefresh;

  final Future<void> Function() _onRefresh;
  Timer? _timer;

  /// Returns true if a refresh timer is currently active and waiting.
  bool get isActive => _timer != null && _timer!.isActive;

  /// Schedules a proactive refresh for [token].
  ///
  /// [leadTime] defines how much time before [token.expiresAt] the refresh should trigger.
  /// Defaults to 3 minutes per ADR-003.
  void schedule(
    AuthToken token, {
    Duration leadTime = const Duration(minutes: 3),
  }) {
    cancel();

    final remaining = token.expiresAt.difference(DateTime.now());
    final delay = remaining - leadTime;

    if (delay <= Duration.zero) {
      // If token is already within leadTime or expired, trigger immediately
      _trigger();
      return;
    }

    _timer = Timer(delay, _trigger);
  }

  void _trigger() {
    _timer = null;
    _onRefresh();
  }

  /// Cancels any scheduled proactive refresh.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
