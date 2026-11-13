import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Workout timing settings (issue #75)', () {
    test('defaults, clamping and persistence', () async {
      final state = TrainingState();
      expect(state.restTimerEnabled, isTrue);
      expect(state.restTimerSeconds, 90);
      expect(state.restTimerSoundEnabled, isTrue);

      state.setRestTimerEnabled(false);
      state.setRestTimerSeconds(120);
      state.setRestTimerSoundEnabled(false);

      final payload = state.exportBackupJson();
      final restored = TrainingState();
      expect(await restored.importBackupJson(payload), isTrue);

      expect(restored.restTimerEnabled, isFalse);
      expect(restored.restTimerSeconds, 120);
      expect(restored.restTimerSoundEnabled, isFalse);

      restored.setRestTimerSeconds(1);
      expect(restored.restTimerSeconds, 15, reason: 'clamped to minimum');
    });
  });
}
