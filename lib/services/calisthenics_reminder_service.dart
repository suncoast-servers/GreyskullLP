import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';

/// Opt-in reminder when no calisthenics set is logged for a while (#113).
///
/// Each logged set re-arms the timer, so the alert only fires after a full
/// quiet interval. Saving or clearing a session cancels it.
class CalisthenicsReminderService {
  const CalisthenicsReminderService._();

  static Future<void> noteSetLogged() async {
    if (!trainingState.calisthenicsReminders) return;
    await WorkoutNotificationService.instance.scheduleCalisthenicsReminder(
      minutes: trainingState.calisthenicsReminderMinutes,
    );
  }

  static Future<void> cancel() async {
    await WorkoutNotificationService.instance.cancelCalisthenicsReminder();
  }
}
