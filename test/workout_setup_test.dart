import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/pages/workout_setup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setBarbellTemplate(BarbellTemplate.ogBase);
  });

  Future<void> pumpSetup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WorkoutSetupPage()));
    await tester.pumpAndSettle();
  }

  group('Workout setup vs live session (issue #79)', () {
    testWidgets('lists programs in plain language without book jargon',
        (tester) async {
      await pumpSetup(tester);

      for (final label in [
        'OG Base',
        'Villain',
        'Gladiator',
        'Two-Day Split',
        'Four-Day Split',
        'Custom',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // Jargon removed from setup surfaces.
      expect(find.textContaining('Dan'), findsNothing);
      expect(find.textContaining('LCI'), findsNothing);
      expect(find.textContaining('Book ref'), findsNothing);
      expect(find.textContaining('Cadence:'), findsNothing);
    });

    testWidgets('selecting a program updates the active template',
        (tester) async {
      await pumpSetup(tester);

      await tester.tap(find.text('Villain'));
      await tester.pumpAndSettle();

      expect(trainingState.activeBarbellTemplate, BarbellTemplate.villain);
    });

    testWidgets('Start Workout opens the live session page', (tester) async {
      await pumpSetup(tester);

      await tester.tap(find.byKey(const Key('start_workout_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutPageWeight), findsOneWidget);
      expect(find.text('Core Barbell Lifts'), findsOneWidget);
    });

    testWidgets('custom actions appear only for the custom program',
        (tester) async {
      await pumpSetup(tester);
      expect(find.byKey(const Key('setup_customize_btn')), findsNothing);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('setup_customize_btn')), findsOneWidget);
      expect(find.byKey(const Key('setup_duplicate_btn')), findsOneWidget);
    });
  });
}
