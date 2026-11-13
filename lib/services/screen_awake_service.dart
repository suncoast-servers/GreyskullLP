import 'package:flutter/services.dart';

/// Keeps the display awake during a live workout (issue #82).
///
/// Uses the Android window flag via a thin platform channel, so no extra
/// dependency is needed. On other platforms the call is a no-op.
class ScreenAwakeService {
  const ScreenAwakeService._();

  static const MethodChannel _channel = MethodChannel('greyskull/screen');

  static bool _awake = false;

  static bool get isAwake => _awake;

  /// Idempotent: repeated calls are ignored when the state already matches.
  static Future<void> setAwake(bool awake) async {
    if (_awake == awake) return;
    _awake = awake;
    try {
      await _channel.invokeMethod<void>('setAwake', {'awake': awake});
    } catch (_) {
      // Platform does not support the flag (iOS/web/tests): ignore.
    }
  }

  /// Convenience for tests to reset cached state.
  static void resetForTests() {
    _awake = false;
  }
}
