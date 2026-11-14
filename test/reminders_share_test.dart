import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/calisthenics_reminder_service.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setCalisthenicsReminders(false);
    trainingState.setCalisthenicsReminderMinutes(60);
    WorkoutNotificationService.enabled = false;
    WorkoutNotificationService.debugReminderSchedules = 0;
    WorkoutNotificationService.debugReminderCancels = 0;
  });

  group('Calisthenics set reminders (issue #113)', () {
    test('reminder settings persist through backup', () async {
      final state = TrainingState();
      state.setCalisthenicsReminders(true);
      state.setCalisthenicsReminderMinutes(45);

      final restored = TrainingState();
      expect(await restored.importBackupJson(state.exportBackupJson()), isTrue);
      expect(restored.calisthenicsReminders, isTrue);
      expect(restored.calisthenicsReminderMinutes, 45);
    });

    test('minutes are clamped to a sane window', () {
      final state = TrainingState();
      state.setCalisthenicsReminderMinutes(1);
      expect(state.calisthenicsReminderMinutes, 15);
      state.setCalisthenicsReminderMinutes(999);
      expect(state.calisthenicsReminderMinutes, 240);
    });

    test('logging a set schedules only when enabled', () async {
      await CalisthenicsReminderService.noteSetLogged();
      expect(WorkoutNotificationService.debugReminderSchedules, 0);

      trainingState.setCalisthenicsReminders(true);
      await CalisthenicsReminderService.noteSetLogged();
      expect(WorkoutNotificationService.debugReminderSchedules, 1);

      await CalisthenicsReminderService.cancel();
      expect(WorkoutNotificationService.debugReminderCancels, 1);
    });
  });
}
