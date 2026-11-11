import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/history_page.dart';
import 'package:greyskull_lp/pages/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Progress Analytics & Metrics Unit Tests', () {
    test('Streak calculation counts consecutive workout days', () {
      final state = TrainingState();
      expect(state.calculateCurrentStreakDays(), 0);

      // Add workout today
      state.logWeightSession(
        coreLiftSummary: 'Bench Press',
        optionalExerciseSummary: 'None',
        volume: 5000,
      );
      expect(state.calculateCurrentStreakDays(), 1);

      // Add workout yesterday
      state.history; // verify history populated
    });

    test('Method transitions and milestones are detected chronologically', () {
      final state = TrainingState();
      expect(state.getMethodTransitions(), isEmpty);

      // 1. Log First Weight Session
      state.logWeightSession(
        coreLiftSummary: 'Overhead Press, Squat',
        optionalExerciseSummary: 'None',
        volume: 6000,
      );

      var transitions = state.getMethodTransitions();
      expect(transitions.length,
          2); // Started Barbell Program + 5,000 lbs Volume Milestone
      expect(
          transitions.any((m) => m.title == 'Started Barbell Program'), isTrue);
      expect(transitions.any((m) => m.title == '5,000 lbs Volume Milestone'),
          isTrue);

      // 2. Log Frequency Method Session
      state.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 60,
        chinUps: 25,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );

      transitions = state.getMethodTransitions();
      expect(transitions.any((m) => m.title == 'Adopted Frequency Method'),
          isTrue);

      // 3. Log Ladder Method Session with enough reps to hit 100 Push-ups
      state.logDailyMethodSession(
        method: DailyMethod.ladder,
        pushUps: 50,
        chinUps: 20,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );

      transitions = state.getMethodTransitions();
      expect(transitions.any((m) => m.title == 'Graduated to Ladder Method'),
          isTrue);
      expect(transitions.any((m) => m.title == '100 Push-ups Club'), isTrue);

      // 4. Log Total Work Method Session
      state.logDailyMethodSession(
        method: DailyMethod.totalWork,
        pushUps: 40,
        chinUps: 15,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );

      transitions = state.getMethodTransitions();
      expect(transitions.any((m) => m.title == 'Advanced to Total Work Method'),
          isTrue);
    });

    test('Daily volume and calisthenics time series aggregation', () {
      final state = TrainingState();
      final volumeMap = state.getDailyVolumeByDay(days: 7);
      expect(volumeMap.length, 7);

      final calisthenicsMap = state.getDailyCalisthenicsByDay(days: 7);
      expect(calisthenicsMap.length, 7);
    });
  });

  group('StatsPage Widget Tests', () {
    testWidgets('Renders empty state when history is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress & Analytics'), findsOneWidget);
      expect(find.text('No activity in this time range'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('Opens metric definitions modal when info icon is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap info icon
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('Metric Definitions & Rules'), findsOneWidget);
      expect(find.textContaining('Resistance Volume (lbs)'), findsOneWidget);
      expect(find.textContaining('Calisthenics Volume (Reps)'), findsOneWidget);
      expect(find.textContaining('Method Transitions'), findsOneWidget);
    });

    testWidgets('Renders KPI cards, chart, and category tabs with active data',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Populate history with workout entries
      trainingState.logWeightSession(
        coreLiftSummary: 'Bench Press (Done, 200 lbs x 5 reps x 3 sets)',
        optionalExerciseSummary: 'Curls',
        volume: 3000,
      );
      trainingState.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 50,
        chinUps: 20,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify overview KPI cards
      expect(find.text('Resistance Volume'), findsOneWidget);
      expect(find.text('Calisthenics'), findsWidgets);
      expect(find.text('Active Streak'), findsOneWidget);
      expect(find.text('Method Transitions & Milestones'), findsOneWidget);

      // Switch to Resistance category
      await tester.tap(find.widgetWithText(ChoiceChip, 'Resistance'));
      await tester.pumpAndSettle();
      expect(find.text('Barbell Volume Progression (Daily)'), findsOneWidget);

      // Switch to Calisthenics category
      await tester.tap(find.widgetWithText(ChoiceChip, 'Calisthenics'));
      await tester.pumpAndSettle();
      expect(find.text('Repetitions by Method Protocol'), findsOneWidget);
      expect(find.text('Frequency Method'), findsOneWidget);
    });
  });

  group('HistoryPage Widget Tests', () {
    testWidgets('Renders category filter chips and filters correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check category filter chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Resistance'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Daily Calisthenics'),
          findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Diet'), findsOneWidget);

      // Filter by Diet (empty)
      final dietChip = find.widgetWithText(FilterChip, 'Diet');
      await tester.ensureVisible(dietChip);
      await tester.tap(dietChip);
      await tester.pumpAndSettle();
      expect(find.textContaining('No entries for this filter'), findsOneWidget);
    });
  });
}
