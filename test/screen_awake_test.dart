import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/live_workout_page.dart';
import 'package:greyskull_lp/services/screen_awake_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    ScreenAwakeService.resetForTests();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('greyskull/screen'),
      (call) async {
        calls.add('${call.method}:${call.arguments}');
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('greyskull/screen'), null);
  });

  group('Keep screen awake (issue #82)', () {
    test('setting persists through backups', () async {
      final state = TrainingState();
      expect(state.keepScreenAwake, isTrue);
      state.setKeepScreenAwake(false);

      final restored = TrainingState();
      expect(await restored.importBackupJson(state.exportBackupJson()), isTrue);
      expect(restored.keepScreenAwake, isFalse);
    });

    test('notification toggle persists through backups', () async {
      final state = TrainingState();
      expect(state.workoutNotifications, isTrue);
      state.setWorkoutNotifications(false);

      final restored = TrainingState();
      expect(await restored.importBackupJson(state.exportBackupJson()), isTrue);
      expect(restored.workoutNotifications, isFalse);
    });

    testWidgets('live workout turns the flag on and releases it on exit',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: LiveWorkoutPage()));
      await tester.pumpAndSettle();

      expect(ScreenAwakeService.isAwake, isTrue);
      expect(calls, contains('setAwake:{awake: true}'));

      // Leave the session (confirm dialog -> End workout).
      await tester.tap(find.byTooltip('End workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End workout'));
      await tester.pumpAndSettle();

      expect(ScreenAwakeService.isAwake, isFalse);
    });
  });
}
