import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/history_page.dart';
import 'package:greyskull_lp/pages/workout_page_frequency.dart';
import 'package:greyskull_lp/pages/workout_page_ladder.dart';
import 'package:greyskull_lp/pages/workout_page_totalwork.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TrainingState Calisthenics & History Unit Tests', () {
    test('FrequencySet serializes to/from json cleanly', () {
      final set = FrequencySet(pushUps: 15, chinUps: 5, usedNegatives: true);
      final json = set.toJsonMap();
      final revived = FrequencySet.fromJsonMap(json);

      expect(revived.pushUps, 15);
      expect(revived.chinUps, 5);
      expect(revived.usedNegatives, true);
    });

    test('addFrequencySet and clearTodayFrequencySets work correctly', () {
      final state = TrainingState();
      expect(state.todayFrequencySets, isEmpty);

      state.addFrequencySet(pushUps: 10, chinUps: 3, usedNegatives: false);
      state.addFrequencySet(pushUps: 15, chinUps: 4, usedNegatives: true);

      expect(state.todayFrequencySets.length, 2);
      expect(state.todayFrequencyPushUps, 25);
      expect(state.todayFrequencyChinUps, 7);

      state.removeFrequencySet(0);
      expect(state.todayFrequencySets.length, 1);
      expect(state.todayFrequencyPushUps, 15);

      state.clearTodayFrequencySets();
      expect(state.todayFrequencySets, isEmpty);
    });

    test('Method switching preserves history entries', () {
      final state = TrainingState();
      state.setActiveDailyMethod(DailyMethod.frequency);

      state.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 30,
        chinUps: 10,
        usedNegatives: false,
        optionalExerciseSummary: 'Dips',
      );

      expect(state.history.length, 1);
      expect(state.history.first.method, DailyMethod.frequency);

      // Switch to ladder
      state.setActiveDailyMethod(DailyMethod.ladder);
      expect(state.activeDailyMethod, DailyMethod.ladder);
      expect(state.history.length, 1);

      // Log ladder session
      state.logDailyMethodSession(
        method: DailyMethod.ladder,
        pushUps: 25,
        chinUps: 0,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );

      expect(state.history.length, 2);

      // Switch to total work
      state.setActiveDailyMethod(DailyMethod.totalWork);
      expect(state.activeDailyMethod, DailyMethod.totalWork);
      expect(state.history.length, 2);
    });

    test('updateHistoryEntry and deleteHistoryEntry modify history', () {
      final state = TrainingState();
      state.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 20,
        chinUps: 5,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );

      final entry = state.history.first;
      expect(entry.pushUps, 20);

      // Update
      final updated = entry.copyWith(title: 'Edited Title', pushUps: 25);
      state.updateHistoryEntry(updated);

      final fetched = state.history.first;
      expect(fetched.title, 'Edited Title');
      expect(fetched.pushUps, 25);

      // Delete
      state.deleteHistoryEntry(fetched.id);
      expect(state.history, isEmpty);
    });
  });

  group('Calisthenics Method Widget Tests', () {
    testWidgets('WorkoutPageFrequency displays progress and records a set',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageFrequency()),
        ),
      );

      expect(find.text('Frequency Method'), findsOneWidget);
      expect(find.text('Log a Frequency Set'), findsOneWidget);

      final recordBtn = find.text('Record This Set');
      await tester.scrollUntilVisible(recordBtn, 100);
      await tester.tap(recordBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Today\'s Sets'), findsOneWidget);
    });

    testWidgets('WorkoutPageLadder hits rungs and tracks volume',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageLadder()),
        ),
      );

      expect(find.text('Ladder Method'), findsOneWidget);
      expect(find.text('Hit Rung 1 (1 rep)'), findsOneWidget);

      // Hit rung 1
      await tester.tap(find.text('Hit Rung 1 (1 rep)'));
      await tester.pump();

      expect(find.text('Hit Rung 2 (2 reps)'), findsOneWidget);
      expect(find.text('Finish Ladder'), findsOneWidget);

      // Finish ladder
      await tester.tap(find.text('Finish Ladder'));
      await tester.pumpAndSettle();

      expect(find.text('Completed Ladders:'), findsOneWidget);
      expect(find.text('Total Reps'), findsOneWidget);
    });

    testWidgets('WorkoutPageTotalWork logs sets towards target volume',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageTotalWork()),
        ),
      );

      expect(find.text('Total Work Method'), findsOneWidget);
      expect(find.text('Volume Progress'), findsOneWidget);
      expect(find.text('Session Time'), findsOneWidget);

      // Tap to record set
      final recordButton = find.textContaining('Record Set');
      await tester.scrollUntilVisible(recordButton, 100);
      expect(recordButton, findsOneWidget);

      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      expect(find.text('Sets Completed:'), findsOneWidget);
    });

    testWidgets('HistoryPage renders category chips and empty state or entries',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryPage()),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Daily Calisthenics'), findsOneWidget);
      expect(find.text('Resistance'), findsOneWidget);
      expect(find.text('Diet'), findsOneWidget);
    });
  });
}
