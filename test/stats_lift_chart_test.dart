import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final e in trainingState.history.toList()) {
      trainingState.deleteHistoryEntry(e.id);
    }
  });

  void seedBench(double weight, int amrap) {
    trainingState.logWeightSession(
      coreLiftSummary: 'Bench Press (Done, ${weight.toStringAsFixed(1)} lbs '
          'x $amrap reps x 3 sets)',
      optionalExerciseSummary: 'None',
      volume: weight * 5 * 3,
      templateName: 'OG Base',
      workoutName: 'Workout A',
    );
  }

  group('Stats lift progression (issue #87)', () {
    testWidgets('shows per-lift estimated 1RM lines instead of only volume',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      seedBench(185, 8);
      seedBench(205, 6);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatsPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lift Progression (est. 1RM)'), findsOneWidget);
      expect(find.text('Bench Press'), findsWidgets);
      // Volume is demoted to a secondary chart title.
      expect(find.text('Volume (secondary)'), findsOneWidget);
    });
  });
}
