import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Live-workout notifications (issue #82).
///
/// An ongoing, silent notification shows that a session is running, and a
/// high-importance notification announces the end of a rest period. Everything
/// is best-effort: failures never interrupt a workout.
class WorkoutNotificationService {
  WorkoutNotificationService._();

  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();

  static const int liveId = 666;
  static const int restId = 667;

  static const String liveChannelId = 'workout_live';
  static const String restChannelId = 'workout_rest';

  /// Disable in tests or when the user turns notifications off.
  static bool enabled = true;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    _initialised = true;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
    } catch (_) {
      // Notifications are optional; ignore platform failures.
    }
  }

  Future<void> requestPermission() async {
    await _ensureInitialised();
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> showLive({
    required String title,
    required String body,
  }) async {
    if (!enabled) return;
    await _ensureInitialised();
    try {
      await _plugin.show(
        id: liveId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            liveChannelId,
            'Live workout',
            channelDescription: 'Shown while a workout session is running.',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            playSound: false,
            showWhen: false,
          ),
          iOS: DarwinNotificationDetails(presentSound: false),
        ),
      );
    } catch (_) {}
  }

  Future<void> showRestComplete() async {
    if (!enabled) return;
    await _ensureInitialised();
    try {
      await _plugin.show(
        id: restId,
        title: 'Rest complete',
        body: 'Time for your next set.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            restChannelId,
            'Rest timer',
            channelDescription: 'Alerts when a rest period ends.',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
      );
    } catch (_) {}
  }

  Future<void> cancelLive() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _plugin.cancel(id: liveId);
    } catch (_) {}
  }
}
