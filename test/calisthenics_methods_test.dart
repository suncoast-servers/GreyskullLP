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

    test('In-progress Ladder and Total Work sessions survive method switching',
        () {
      final state = TrainingState();

      // Configure in-progress Ladder session
      state.setActiveDailyMethod(DailyMethod.ladder);
      state.setLadderExercise('Chin-ups');
      state.setLadderUsedNegatives(true);
      state.recordLadderRung(); // 1 rep
      state.recordLadderRung(); // 2 reps
      state.finishCurrentLadder();
      state.recordLadderRung(); // active rung in second ladder (1 rep)

      expect(state.activeCompletedLadders.length, 1);
      expect(state.activeCompletedLadders.first, [1, 2]);
      expect(state.activeCurrentLadderRungs, [1]);
      expect(state.activeLadderTotalReps, 4); // 1 + 2 + 1
      expect(state.activeLadderPeakRung, 2);

      // Configure in-progress Total Work session
      state.setActiveDailyMethod(DailyMethod.totalWork);
      state.setTotalWorkExercise('Push-ups');
      state.setTotalWorkModel('weekly');
      state.setTotalWorkTargetReps(420);
      state.addTotalWorkSet(20);
      state.addTotalWorkSet(25);

      expect(state.activeTotalWorkSets, [20, 25]);
      expect(state.activeTotalWorkCompletedReps, 45);
      expect(state.activeTotalWorkRemainingReps, 375);

      // Switch to Frequency method and back to Ladder
      state.setActiveDailyMethod(DailyMethod.frequency);
      expect(state.activeDailyMethod, DailyMethod.frequency);

      state.setActiveDailyMethod(DailyMethod.ladder);
      // Verify Ladder in-progress state is fully preserved!
      expect(state.activeLadderExercise, 'Chin-ups');
      expect(state.activeLadderUsedNegatives, true);
      expect(state.activeCompletedLadders.length, 1);
      expect(state.activeCurrentLadderRungs, [1]);
      expect(state.activeLadderTotalReps, 4);
      expect(state.activeLadderPeakRung, 2);

      // Switch back to Total Work
      state.setActiveDailyMethod(DailyMethod.totalWork);
      // Verify Total Work in-progress state is fully preserved!
      expect(state.activeTotalWorkExercise, 'Push-ups');
      expect(state.activeTotalWorkModel, 'weekly');
      expect(state.activeTotalWorkTargetReps, 420);
      expect(state.activeTotalWorkSets, [20, 25]);
      expect(state.activeTotalWorkCompletedReps, 45);
    });

    test(
        'updateHistoryEntry preserves and updates methodMetadata for each method',
        () {
      final state = TrainingState();

      // Frequency history entry with metadata
      state.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 30,
        chinUps: 12,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        metadata: {
          'setsCount': 6,
          'pushUps': 30,
          'chinUps': 12,
          'usedNegatives': false,
        },
      );
      var entry = state.history.first;
      expect(entry.methodMetadata?['setsCount'], 6);

      // Edit Frequency entry metadata
      state.updateHistoryEntry(entry.copyWith(
        pushUps: 40,
        chinUps: 15,
        methodMetadata: {
          'setsCount': 8,
          'pushUps': 40,
          'chinUps': 15,
          'usedNegatives': true,
        },
      ));
      entry = state.history.first;
      expect(entry.pushUps, 40);
      expect(entry.chinUps, 15);
      expect(entry.methodMetadata?['setsCount'], 8);
      expect(entry.methodMetadata?['usedNegatives'], true);

      // Ladder history entry with metadata
      state.logDailyMethodSession(
        method: DailyMethod.ladder,
        pushUps: 0,
        chinUps: 75,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        metadata: {
          'exercise': 'Chin-ups',
          'totalReps': 75,
          'peakRung': 5,
          'laddersCount': 5,
          'usedNegatives': false,
        },
      );
      var ladderEntry = state.history.first;
      expect(ladderEntry.method, DailyMethod.ladder);
      expect(ladderEntry.methodMetadata?['peakRung'], 5);
      expect(ladderEntry.methodMetadata?['laddersCount'], 5);

      // Edit Ladder entry metadata
      state.updateHistoryEntry(ladderEntry.copyWith(
        chinUps: 90,
        methodMetadata: {
          'exercise': 'Chin-ups',
          'totalReps': 90,
          'peakRung': 6,
          'laddersCount': 6,
          'usedNegatives': false,
        },
      ));
      ladderEntry = state.history.first;
      expect(ladderEntry.chinUps, 90);
      expect(ladderEntry.methodMetadata?['peakRung'], 6);
      expect(ladderEntry.methodMetadata?['laddersCount'], 6);

      // Total Work entry with metadata
      state.logDailyMethodSession(
        method: DailyMethod.totalWork,
        pushUps: 70,
        chinUps: 0,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        metadata: {
          'exercise': 'Push-ups',
          'totalReps': 70,
          'targetReps': 70,
          'model': 'daily',
          'setsCount': 5,
          'usedNegatives': false,
        },
      );
      var twEntry = state.history.first;
      expect(twEntry.method, DailyMethod.totalWork);
      expect(twEntry.methodMetadata?['model'], 'daily');
      expect(twEntry.methodMetadata?['setsCount'], 5);

      // Edit Total Work entry metadata
      state.updateHistoryEntry(twEntry.copyWith(
        pushUps: 420,
        methodMetadata: {
          'exercise': 'Push-ups',
          'totalReps': 420,
          'targetReps': 420,
          'model': 'weekly',
          'setsCount': 14,
          'usedNegatives': false,
        },
      ));
      twEntry = state.history.firstWhere((e) => e.id == twEntry.id);
      expect(twEntry.pushUps, 420);
      expect(twEntry.methodMetadata?['model'], 'weekly');
      expect(twEntry.methodMetadata?['setsCount'], 14);
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

      expect(find.textContaining('Completed Ladders'), findsOneWidget);
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
      expect(find.text('Target Model:'), findsOneWidget);

      // Tap to record set
      final recordButton = find.textContaining('Record Set');
      await tester.scrollUntilVisible(recordButton, 100);
      expect(recordButton, findsOneWidget);

      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      expect(find.text('Sets completed: 1'), findsOneWidget);
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

    testWidgets(
        'HistoryPage opens method-specific edit dialogs for Frequency, Ladder, and Total Work',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Seed entries for all 3 calisthenics methods
      trainingState.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 30,
        chinUps: 10,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        title: 'Morning Frequency',
        metadata: {'setsCount': 5, 'usedNegatives': false},
      );
      trainingState.logDailyMethodSession(
        method: DailyMethod.ladder,
        pushUps: 0,
        chinUps: 75,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        title: 'Afternoon Ladder',
        metadata: {
          'exercise': 'Chin-ups',
          'totalReps': 75,
          'peakRung': 5,
          'laddersCount': 5,
        },
      );
      trainingState.logDailyMethodSession(
        method: DailyMethod.totalWork,
        pushUps: 70,
        chinUps: 0,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        title: 'Evening Total Work',
        metadata: {
          'exercise': 'Push-ups',
          'totalReps': 70,
          'targetReps': 70,
          'model': 'daily',
          'setsCount': 5,
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryPage()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Frequency Edit Dialog
      expect(find.text('Morning Frequency'), findsOneWidget);
      final freqMoreButtons = find.byIcon(Icons.more_vert);
      // The newest entry is at top (Total Work, Ladder, Frequency)
      // Tap on the Frequency entry (last more_vert icon)
      await tester.tap(freqMoreButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsOneWidget);
      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Frequency Method Entry'), findsOneWidget);
      expect(find.text('Used Chin-up Negatives'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 2. Verify Ladder Edit Dialog (middle entry)
      expect(find.text('Afternoon Ladder'), findsOneWidget);
      final ladderMoreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(ladderMoreButtons.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Ladder Method Entry'), findsOneWidget);
      expect(find.text('Movement'), findsOneWidget);
      expect(find.text('Peak Rung'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 3. Verify Total Work Edit Dialog (first entry)
      expect(find.text('Evening Total Work'), findsOneWidget);
      final twMoreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(twMoreButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Total Work Method Entry'), findsOneWidget);
      expect(find.text('Target Model'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Total Work Method Entry'), findsNothing);
      expect(find.text('Evening Total Work'), findsAtLeast(1));
      expect(find.text('Afternoon Ladder'), findsAtLeast(1));
      expect(find.text('Morning Frequency'), findsAtLeast(1));
    });
  });
}
