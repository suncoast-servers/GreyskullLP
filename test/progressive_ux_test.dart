import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/pages/workout_page.dart';
import 'package:greyskull_lp/pages/workout_page_ladder.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    trainingState.resetOnboarding();
  });

  group('Progressive UX - TrainingState unit tests', () {
    test('default starter level is Foundation (Level 1) with starter locks',
        () {
      expect(trainingState.programLevel, equals(ProgramLevel.foundation));
      expect(trainingState.hasCompletedOnboarding, isFalse);
      expect(trainingState.isLadderMethodUnlocked, isFalse);
      expect(trainingState.isTotalWorkMethodUnlocked, isFalse);
      expect(trainingState.isAccessoriesUnlocked, isFalse);
      expect(trainingState.isAdvancedSplitsUnlocked, isFalse);
    });

    test('level 2 (Villain) unlocks Ladder Method and accessories', () {
      trainingState.setProgramLevel(ProgramLevel.villain);
      expect(trainingState.programLevel, equals(ProgramLevel.villain));
      expect(trainingState.isLadderMethodUnlocked, isTrue);
      expect(trainingState.isAccessoriesUnlocked, isTrue);
      expect(trainingState.isTotalWorkMethodUnlocked, isFalse);
      expect(trainingState.isAdvancedSplitsUnlocked, isFalse);
    });

    test('level 3 (Gladiator) unlocks Total Work Method and advanced splits',
        () {
      trainingState.setProgramLevel(ProgramLevel.gladiator);
      expect(trainingState.programLevel, equals(ProgramLevel.gladiator));
      expect(trainingState.isLadderMethodUnlocked, isTrue);
      expect(trainingState.isAccessoriesUnlocked, isTrue);
      expect(trainingState.isTotalWorkMethodUnlocked, isTrue);
      expect(trainingState.isAdvancedSplitsUnlocked, isTrue);
    });

    test('completeOnboarding sets onboarding flag and selected level', () {
      trainingState.completeOnboarding(selectedLevel: ProgramLevel.villain);
      expect(trainingState.hasCompletedOnboarding, isTrue);
      expect(trainingState.programLevel, equals(ProgramLevel.villain));

      trainingState.resetOnboarding();
      expect(trainingState.hasCompletedOnboarding, isFalse);
      expect(trainingState.programLevel, equals(ProgramLevel.foundation));
    });

    test(
        'zero data loss: changing level preserves workout history, targets and notes',
        () async {
      // 1. Log a workout session and adjust targets
      trainingState.logWeightSession(
        coreLiftSummary: 'Bench Press, Squat',
        optionalExerciseSummary: 'Bicep Curls',
        volume: 3250.0,
        notes: 'Felt strong on AMRAP',
      );
      trainingState.setDailyPushUpTarget(120);
      trainingState.setDailyChinUpTarget(40);

      final historyCountBefore = trainingState.history.length;
      final latestEntry = trainingState.history.first;

      // 2. Cycle through program levels (Foundation -> Villain -> Gladiator -> Foundation)
      trainingState.setProgramLevel(ProgramLevel.villain);
      trainingState.setProgramLevel(ProgramLevel.gladiator);
      trainingState.setProgramLevel(ProgramLevel.foundation);

      // 3. Confirm all training history and targets are 100% intact
      expect(trainingState.history.length, equals(historyCountBefore));
      expect(trainingState.history.first.details,
          contains('Felt strong on AMRAP'));
      expect(trainingState.history.first.weightVolume, equals(3250.0));
      expect(trainingState.history.first.details, equals(latestEntry.details));
      expect(trainingState.dailyPushUpTarget, equals(120));
      expect(trainingState.dailyChinUpTarget, equals(40));
    });

    test(
        'backup payload serializes and restores program level and onboarding status',
        () async {
      trainingState.completeOnboarding(selectedLevel: ProgramLevel.gladiator);
      final jsonStr = trainingState.exportBackupJson();

      expect(jsonStr, contains('"programLevel":"gladiator"'));
      expect(jsonStr, contains('"hasCompletedOnboarding":true'));

      trainingState.resetOnboarding();
      expect(trainingState.programLevel, equals(ProgramLevel.foundation));

      final success = await trainingState.importBackupJson(jsonStr);
      expect(success, isTrue);
      expect(trainingState.programLevel, equals(ProgramLevel.gladiator));
      expect(trainingState.hasCompletedOnboarding, isTrue);
    });
  });

  group('Progressive UX - Widget tests', () {
    testWidgets(
        'shows starter onboarding sheet on first run and completes upon tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      trainingState.resetOnboarding();
      final titleNotifier = ValueNotifier<String>('Workout');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutPage(titleNotifier: titleNotifier),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Onboarding dialog is visible
      expect(find.text('Welcome to Greyskull LP'), findsOneWidget);
      expect(
          find.text('Select your initial programming level:'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);

      // Tap 'Start Training'
      final startBtn = find.widgetWithText(ElevatedButton, 'Start Training');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Dialog dismissed and state marked completed
      expect(find.text('Welcome to Greyskull LP'), findsNothing);
      expect(trainingState.hasCompletedOnboarding, isTrue);
      expect(trainingState.programLevel, equals(ProgramLevel.foundation));
    });

    testWidgets(
        'workout page displays active program level banner and level adjuster',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      trainingState.completeOnboarding(selectedLevel: ProgramLevel.foundation);
      final titleNotifier = ValueNotifier<String>('Workout');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutPage(titleNotifier: titleNotifier),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Active level badge and subtitle
      expect(find.text('Level 1: Foundation'), findsOneWidget);
      expect(find.text('Base Barbell Progression + Frequency Method'),
          findsOneWidget);

      // Tap 'Adjust Level'
      final adjustBtn = find.text('Adjust Level');
      expect(adjustBtn, findsOneWidget);
      await tester.tap(adjustBtn);
      await tester.pumpAndSettle();

      // Adjust sheet opens
      expect(find.text('Adjust Programming Level'), findsOneWidget);

      // Select Level 2
      final selectBtns = find.widgetWithText(TextButton, 'Select');
      expect(selectBtns, findsWidgets);
      await tester.tap(selectBtns.first);
      await tester.pumpAndSettle();

      expect(trainingState.programLevel, equals(ProgramLevel.villain));
    });

    testWidgets(
        'tapping locked Ladder Method shows graduation sheet with Try Once and Graduate options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      trainingState.completeOnboarding(selectedLevel: ProgramLevel.foundation);
      final titleNotifier = ValueNotifier<String>('Workout');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutPage(titleNotifier: titleNotifier),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Level 1 shows Level 2+ lock badge for Ladder Method
      expect(find.text('Level 2+'), findsOneWidget);

      // Tap Ladder Method
      final ladderBtn = find.text('Ladder Method');
      expect(ladderBtn, findsOneWidget);
      await tester.tap(ladderBtn);
      await tester.pumpAndSettle();

      // Graduation bottom sheet displays
      expect(find.text('Graduate to Level 2: Villain'), findsOneWidget);
      expect(find.text('Try Once Only'), findsOneWidget);
      expect(find.text('Graduate to Lvl 2'), findsOneWidget);

      // Tap Graduate to Lvl 2
      await tester.tap(find.text('Graduate to Lvl 2'));
      await tester.pumpAndSettle();

      // Trainee graduated without data loss and navigated to ladder page
      expect(trainingState.programLevel, equals(ProgramLevel.villain));
      expect(find.byType(WorkoutPageLadder), findsOneWidget);
    });

    testWidgets(
        'settings page displays Program Level & Progression with zero data loss guarantee',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      trainingState.completeOnboarding(selectedLevel: ProgramLevel.foundation);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Program Level & Progression'), findsOneWidget);
      expect(find.textContaining('Zero data loss:'), findsOneWidget);

      // Tap Villain radio option
      final villainTile = find.text('Level 2: Villain');
      expect(villainTile, findsOneWidget);
      await tester.tap(villainTile);
      await tester.pumpAndSettle();

      expect(trainingState.programLevel, equals(ProgramLevel.villain));

      // Tap Reset Starter Onboarding Prompt
      final resetBtn = find.text('Reset Starter Onboarding Prompt');
      expect(resetBtn, findsOneWidget);
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(trainingState.hasCompletedOnboarding, isFalse);
      expect(find.textContaining('Starter onboarding reset'), findsOneWidget);
    });

    testWidgets('workout weight page displays foundation tip when on Level 1',
        (WidgetTester tester) async {
      trainingState.completeOnboarding(selectedLevel: ProgramLevel.foundation);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkoutPageWeight(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Level 1 (Foundation): Keep it simple'),
        findsOneWidget,
      );

      // Switch to level 2 and verify tip disappears
      trainingState.setProgramLevel(ProgramLevel.villain);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Level 1 (Foundation): Keep it simple'),
        findsNothing,
      );
    });
  });
}
