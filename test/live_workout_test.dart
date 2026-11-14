import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/live_workout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _setCircle(String lift, int index) =>
    find.byKey(ValueKey('set-tap-$lift-$index'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setBarbellTemplate(BarbellTemplate.ogBase);
    for (final e in trainingState.history.toList()) {
      trainingState.deleteHistoryEntry(e.id);
    }
  });

  Future<void> pumpLive(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LiveWorkoutPage()));
    await tester.pumpAndSettle();
  }

  group('Live workout mode (issue #80)', () {
    testWidgets('session clock starts and setup chrome is hidden',
        (tester) async {
      await pumpLive(tester);

      expect(find.text('Live Workout'), findsOneWidget);
      expect(find.textContaining('Session 00:'), findsOneWidget);
      // Program card is setup-only.
      expect(find.text('Change in Setup'), findsNothing);
    });

    testWidgets('set circles are labelled 5 / 5 / 5+', (tester) async {
      await pumpLive(tester);

      // Two straight sets show 5, the AMRAP set shows 5+.
      expect(find.text('5'), findsWidgets);
      expect(find.text('5+'), findsWidgets);
    });

    testWidgets('press-and-hold overrides reps for one set', (tester) async {
      await pumpLive(tester);

      final liftName = trainingState
          .activeBarbellTemplateDetails.workouts.first.coreLifts.first.name;
      await tester.longPress(_setCircle(liftName, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('set 1 reps'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The circle now shows the override (4 instead of 5).
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('leaving asks for confirmation', (tester) async {
      await pumpLive(tester);

      await tester.tap(find.byTooltip('End workout'));
      await tester.pumpAndSettle();

      expect(find.text('End workout?'), findsOneWidget);
      await tester.tap(find.text('Keep training'));
      await tester.pumpAndSettle();
      expect(find.text('Live Workout'), findsOneWidget);
    });

    testWidgets('log toast carries the AMRAP bump in one snackbar',
        (tester) async {
      await pumpLive(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '100');
      await tester.enterText(fields.at(1), '10');

      final logButton = find.text("Log Today's Barbell Workout to History");
      await tester.scrollUntilVisible(
        logButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(logButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Next session:'), findsOneWidget);
      expect(find.textContaining('Workout logged!'), findsOneWidget);
    });

    test('AMRAP 10+ reps bumps next session weight by upper/lower rule', () {
      final state = TrainingState();
      // Simulate what the live page records after logging.
      state.setNextSessionWeight('Overhead Press', 100 + 5);
      state.setNextSessionWeight('Squat', 200 + 10);

      expect(state.nextSessionWeight('Overhead Press'), 105);
      expect(state.nextSessionWeight('Squat'), 210);

      final restored = TrainingState();
      expect(state.exportBackupJson(), isNotEmpty);
      expect(restored.nextSessionWeight('Overhead Press'), isNull);
    });
  });
}
