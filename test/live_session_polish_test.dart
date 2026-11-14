import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/live_workout_page.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';
import 'package:greyskull_lp/widgets/circular_rest_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _setCircle(String lift, int index) =>
    find.byKey(ValueKey('set-tap-$lift-$index'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setBarbellTemplate(BarbellTemplate.ogBase);
    trainingState.setRestTimerEnabled(true);
    trainingState.setRestTimerSeconds(90);
    trainingState.setRestAfterExerciseSeconds(0);
    trainingState.setPerExerciseRestSeconds('Bench Press', 0);
    WorkoutNotificationService.enabled = false;
    WorkoutNotificationService.debugCancelAllCount = 0;
  });

  Future<void> pumpLive(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LiveWorkoutPage()));
    await tester.pumpAndSettle();
  }

  group('Live session polish (issues #106-#109, #112)', () {
    testWidgets('rest timer honours the configured 90s duration on set one',
        (tester) async {
      await pumpLive(tester);
      final lift = trainingState
          .activeBarbellTemplateDetails.workouts.first.coreLifts.first;

      await tester.tap(_setCircle(lift.name, 0));
      await tester.pump();

      final timer =
          tester.widget<CircularRestTimer>(find.byType(CircularRestTimer));
      expect(timer.seconds, 90);

      // Advance near the end and confirm it does not stop at 60 (#107).
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('1:01'), findsOneWidget);
      expect(find.byType(CircularRestTimer), findsOneWidget);
    });

    testWidgets('last set uses the configured post-exercise rest',
        (tester) async {
      await pumpLive(tester);
      final lift = trainingState
          .activeBarbellTemplateDetails.workouts.first.coreLifts
          .firstWhere((l) => l.sets >= 2);
      final totalSets = lift.sets <= 0 ? 3 : lift.sets;

      await tester.tap(_setCircle(lift.name, 0));
      await tester.pump();
      await tester.tap(_setCircle(lift.name, 1));
      await tester.pump();

      if (totalSets > 2) {
        trainingState.setRestAfterExerciseSeconds(45);
        // Completing the AMRAP set opens the rep dialog first (#106).
        await tester.tap(_setCircle(lift.name, totalSets - 1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pump();
      }

      final timer =
          tester.widget<CircularRestTimer>(find.byType(CircularRestTimer));
      expect(timer.seconds, totalSets > 2 ? 45 : 90);
    });

    testWidgets('live mode drops the rule banner and tap hints (#108)',
        (tester) async {
      await pumpLive(tester);

      expect(find.textContaining('Greyskull Rule'), findsNothing);
      expect(find.textContaining('Tap 5, 5, then 5+'), findsNothing);
      expect(find.textContaining('Level 1 (Foundation)'), findsNothing);
    });

    testWidgets('live mode freezes the plan (#109)', (tester) async {
      await pumpLive(tester);

      expect(find.text('Add Plug-in'), findsNothing);
      expect(find.text('Add Official Accessory'), findsNothing);
      expect(find.byTooltip('Remove'), findsNothing);
      expect(find.byTooltip('Move Up'), findsNothing);
      expect(find.text('Reset to Book Defaults'), findsNothing);

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips, isNotEmpty);
      expect(chips.every((c) => c.onSelected == null), isTrue);
    });

    testWidgets('logging clears the session notifications (#112)',
        (tester) async {
      await pumpLive(tester);

      final logButton = find.text("Log Today's Barbell Workout to History");
      await tester.scrollUntilVisible(
        logButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(logButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(WorkoutNotificationService.debugCancelAllCount, greaterThan(0));
    });

    testWidgets('non-live page keeps the guidance copy', (tester) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageWeight()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Greyskull Rule'), findsOneWidget);
      expect(find.text('Add Plug-in'), findsOneWidget);
    });
  });
}
