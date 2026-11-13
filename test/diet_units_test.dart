import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/body_measurement.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setTapeMeasurementsInInches(false);
  });

  group('Tape unit preference (issue #85)', () {
    test('converts cm <-> inches and persists in backups', () async {
      final state = TrainingState();
      expect(state.tapeMeasurementsInInches, isFalse);
      expect(state.tapeFromCm(254), 254);

      state.setTapeMeasurementsInInches(true);
      expect(state.tapeFromCm(254), closeTo(100, 0.001));
      expect(state.tapeToCm(100), closeTo(254, 0.001));

      final restored = TrainingState();
      expect(await restored.importBackupJson(state.exportBackupJson()), isTrue);
      expect(restored.tapeMeasurementsInInches, isTrue);
    });

    test('stored measurement stays in cm regardless of display unit', () {
      final entry = BodyMeasurement(waistCm: 101.6, chestCm: 114.3);
      expect(entry.waistCm, 101.6);
      expect(entry.chestCm, 114.3);
    });
  });
}
