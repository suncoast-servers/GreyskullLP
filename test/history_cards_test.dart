import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final e in trainingState.history.toList()) {
      trainingState.deleteHistoryEntry(e.id);
    }
  });

  Future<void> pumpHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryPage())),
    );
    await tester.pumpAndSettle();
  }

  group('Resistance history card (issue #88)', () {
    testWidgets('shows structure: lifts, accessories and volume badge',
        (tester) async {
      trainingState.logWeightSession(
        coreLiftSummary:
            'Bench Press 3x5 @ 185 lb (AMRAP 8); Deadlift 1x5 @ 225 lb (AMRAP 6)',
        optionalExerciseSummary: 'Bicep Curls, Yates Rows',
        volume: 3110,
        templateName: 'OG Base',
        workoutName: 'Workout A',
      );
      await pumpHistory(tester);

      expect(find.text('OG Base - Workout A'), findsOneWidget);
      expect(find.textContaining('2 lifts'), findsOneWidget);
      expect(find.textContaining('Bench Press 3x5 @ 185 lb'), findsOneWidget);
      expect(find.textContaining('Deadlift 1x5 @ 225 lb'), findsOneWidget);
      expect(find.textContaining('Accessories: Bicep Curls'), findsOneWidget);
      expect(find.text('3.1 k lb'), findsOneWidget);
    });

    testWidgets('pencil opens the barbell editor', (tester) async {
      trainingState.logWeightSession(
        coreLiftSummary: 'Squat 3x5 @ 135 lb',
        optionalExerciseSummary: 'None',
        volume: 2000,
        templateName: 'OG Base',
        workoutName: 'Workout A',
      );
      await pumpHistory(tester);

      await tester.tap(find.byTooltip('Edit workout'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Barbell Session'), findsOneWidget);
    });

    testWidgets('delete from the card menu removes the session',
        (tester) async {
      trainingState.logWeightSession(
        coreLiftSummary: 'Squat 3x5 @ 135 lb',
        optionalExerciseSummary: 'None',
        volume: 2000,
        templateName: 'OG Base',
        workoutName: 'Workout A',
      );
      await pumpHistory(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(trainingState.history, isEmpty);
    });
  });
}
