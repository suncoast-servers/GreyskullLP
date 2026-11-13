import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorkoutPageWeight())),
    );
    await tester.pumpAndSettle();
  }

  group('Weight workout set taps (issue #50)', () {
    testWidgets('each lift exposes 1 / 2 / 5+ circles with AMRAP distinct',
        (tester) async {
      await pumpPage(tester);

      // 5+ only appears on AMRAP set circles.
      expect(find.text('5+'), findsWidgets);
      expect(_setCircles(), findsNWidgets(6));
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('tapping all three circles marks the lift complete',
        (tester) async {
      await pumpPage(tester);

      expect(find.textContaining('0/'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(_setCircles().at(i));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('1/'), findsOneWidget);

      // Tapping a completed circle un-completes the lift.
      await tester.tap(_setCircles().at(2));
      await tester.pumpAndSettle();
      expect(find.textContaining('0/'), findsOneWidget);
    });

    testWidgets('logging a finished session still writes history',
        (tester) async {
      await pumpPage(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(_setCircles().at(i));
        await tester.pumpAndSettle();
      }

      final historyBefore = trainingState.history.length;
      final logButton = find.text('Log Today\'s Barbell Workout to History');
      await tester.scrollUntilVisible(
        logButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(logButton);
      await tester.pumpAndSettle();

      expect(trainingState.history.length, historyBefore + 1);
      expect(trainingState.history.first.details, contains('Done'));
      expect(trainingState.history.first.category, HistoryCategory.weight);
    });
  });
}
