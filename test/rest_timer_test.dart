import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/widgets/rest_timer_bar.dart';
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

  group('Rest countdown', () {
    testWidgets('counts down and reports completion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimerBar(seconds: 2, soundEnabled: false),
          ),
        ),
      );

      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('0:02'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Rest complete — next set'), findsOneWidget);
    });

    testWidgets('skip dismisses the timer', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestTimerBar(
              seconds: 90,
              soundEnabled: false,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Skip rest'));
      await tester.pump();
      expect(dismissed, isTrue);
    });
  });

  group('Weight page integration', () {
    testWidgets('completing a set starts the rest timer', (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WorkoutPageWeight())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RestTimerBar), findsNothing);

      await tester.tap(_setCircles().first);
      await tester.pump();

      expect(find.byType(RestTimerBar), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
    });

    testWidgets('timer stays hidden when disabled in settings', (tester) async {
      trainer() => trainingState.setRestTimerEnabled(false);
      trainer();
      addTearDown(() => trainingState.setRestTimerEnabled(true));

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

      expect(find.byType(RestTimerBar), findsNothing);
    });
  });
}
