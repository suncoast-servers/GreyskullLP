import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/widgets/circular_rest_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _setCircles() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('set-tap-'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setRestTimerCountUp(true);
    trainingState.setRestTimerSize(2);
  });

  group('Circular rest timer (issue #75 parity)', () {
    testWidgets('count-up shows elapsed and reaches rest complete',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularRestTimer(
              seconds: 3,
              soundEnabled: false,
              countUp: true,
            ),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('0:02'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Rest complete'), findsOneWidget);
    });

    testWidgets('count-down shows remaining', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularRestTimer(
              seconds: 90,
              soundEnabled: false,
              countUp: false,
              coachingText: 'Rest, then Bench Press set 2.',
            ),
          ),
        ),
      );

      expect(find.text('1:30'), findsOneWidget);
      expect(find.textContaining('Bench Press set 2'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('1:20'), findsOneWidget);
    });
  });

  group('Rest settings parity', () {
    test('per-lift rest, size and count-up persist through backup', () async {
      final state = TrainingState();
      state.setPerExerciseRestSeconds('Bench Press', 150);
      state.setRestTimerSize(3);
      state.setRestTimerCountUp(false);
      state.setRestAfterExerciseSeconds(45);

      expect(state.restSecondsForLift('Bench Press'), 150);
      expect(state.restSecondsForLift('Squat'), state.restTimerSeconds);

      final restored = TrainingState();
      expect(await restored.importBackupJson(state.exportBackupJson()), isTrue);
      expect(restored.restSecondsForLift('Bench Press'), 150);
      expect(restored.restTimerSize, 3);
      expect(restored.restTimerCountUp, isFalse);
      expect(restored.restAfterExerciseSeconds, 45);
    });
  });

  group('Weight page timer integration', () {
    testWidgets('completing a set shows the arc timer with coaching text',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WorkoutPageWeight())),
      );
      await tester.pumpAndSettle();

      await tester.tap(_setCircles().first);
      await tester.pump();

      expect(find.byType(CircularRestTimer), findsOneWidget);
      expect(find.textContaining('Rest, then'), findsOneWidget);
    });

    testWidgets('AMRAP stopwatch records a time for the lift', (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WorkoutPageWeight())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Time AMRAP'), findsWidgets);
      await tester.tap(find.text('Time AMRAP').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Stop 0:02'), findsOneWidget);

      await tester.tap(find.textContaining('Stop 0:02'));
      await tester.pump();

      expect(find.textContaining('AMRAP 0:02'), findsOneWidget);
    });
  });
}
