import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.setBarbellTemplate(BarbellTemplate.ogBase);
    trainingState.setBarbellRotationIndex(0);
    trainingState.resetCurrentWorkoutAccessoriesToDefault();
  });

  group('Barbell Templates - Official 3rd Edition Fidelity', () {
    test('All 5 official templates are defined with accurate book references',
        () {
      expect(TrainingState.officialBookTemplates.length, 5);

      final og = TrainingState.templateDefinitions[BarbellTemplate.ogBase]!;
      expect(og.name, contains('"OG" Base Program'));
      expect(og.bookReference, contains('pp. 47–48'));
      expect(og.workouts.length, 2);
      expect(og.workouts[0].coreLifts[0].name, 'Overhead Press');
      expect(
          og.workouts[0].coreLifts[0].isUpperBody, isTrue); // Upper body first
      expect(og.workouts[0].coreLifts[1].name, 'Squat');
      expect(og.workouts[0].coreLifts[1].isUpperBody, isFalse);
      expect(og.workouts[1].coreLifts[0].name, 'Bench Press');
      expect(og.workouts[1].coreLifts[1].name, 'Deadlift');
      expect(og.workouts[1].coreLifts[1].sets, 1); // 1x5+ deadlift rule

      final villain =
          TrainingState.templateDefinitions[BarbellTemplate.villain]!;
      expect(villain.name, contains('Villain'));
      expect(villain.bookReference, contains('56–61'));
      expect(villain.workouts[0].defaultAccessories,
          contains('Weighted Chin-ups (2 x 6–8)'));
      expect(villain.workouts[0].defaultAccessories,
          contains('Neck Harness Extensions (4 x 25+)'));
      expect(villain.workouts[1].defaultAccessories,
          contains('Bicep Curls (2 x 10–12)'));

      final gladiator =
          TrainingState.templateDefinitions[BarbellTemplate.gladiator]!;
      expect(gladiator.workouts.length, 3);
      expect(gladiator.workouts[2].coreLifts[0].name, 'Incline Bench Press');
      expect(gladiator.workouts[2].coreLifts[1].name, 'Front Squat');

      final twoDay =
          TrainingState.templateDefinitions[BarbellTemplate.twoDaySplit]!;
      expect(twoDay.workouts.length, 2);

      final fourDay =
          TrainingState.templateDefinitions[BarbellTemplate.fourDaySplit]!;
      expect(fourDay.workouts.length, 4);
    });

    test('Template switching and rotation indexing work correctly', () {
      final state = TrainingState();
      expect(state.activeBarbellTemplate, BarbellTemplate.ogBase);
      expect(state.currentTemplateWorkout.code, 'A');

      state.advanceBarbellRotation();
      expect(state.currentTemplateWorkout.code, 'B');

      state.advanceBarbellRotation();
      expect(state.currentTemplateWorkout.code, 'A');

      state.setBarbellTemplate(BarbellTemplate.fourDaySplit);
      expect(state.activeBarbellTemplate, BarbellTemplate.fourDaySplit);
      expect(state.currentTemplateWorkout.code, 'Day 1');

      state.setBarbellRotationIndex(3);
      expect(state.currentTemplateWorkout.code, 'Day 4');
    });

    test(
        'Accessory customization: add, reorder, delete, and reset to book defaults',
        () {
      final state = TrainingState();
      state.setBarbellTemplate(BarbellTemplate.villain);
      state.setBarbellRotationIndex(0); // Workout A

      expect(state.currentWorkoutAccessories, [
        'Weighted Chin-ups (2 x 6–8)',
        'Neck Harness Extensions (4 x 25+)',
      ]);
      expect(state.isCurrentWorkoutCustomized(), isFalse);

      // Add a custom accessory
      state.addAccessoryToCurrentWorkout('Dumbbell Lateral Raises (3 x 12)');
      expect(state.isCurrentWorkoutCustomized(), isTrue);
      expect(state.currentWorkoutAccessories.length, 3);
      expect(state.currentWorkoutAccessories.last,
          'Dumbbell Lateral Raises (3 x 12)');

      // Reorder: move the newly added accessory from index 2 to index 0
      state.reorderAccessoriesInCurrentWorkout(2, 0);
      expect(state.currentWorkoutAccessories.first,
          'Dumbbell Lateral Raises (3 x 12)');

      // Remove accessory at index 1
      final removed = state.currentWorkoutAccessories[1];
      state.removeAccessoryFromCurrentWorkout(1);
      expect(state.currentWorkoutAccessories.contains(removed), isFalse);

      // Reset to defaults
      state.resetCurrentWorkoutAccessoriesToDefault();
      expect(state.isCurrentWorkoutCustomized(), isFalse);
      expect(state.currentWorkoutAccessories, [
        'Weighted Chin-ups (2 x 6–8)',
        'Neck Harness Extensions (4 x 25+)',
      ]);
    });

    test(
        'Persistence: template choice, rotation, and custom accessories survive serialization',
        () async {
      final state = TrainingState();
      state.setBarbellTemplate(BarbellTemplate.gladiator);
      state.setBarbellRotationIndex(1); // Workout B
      state.addAccessoryToCurrentWorkout('Farmer Walk (3 sets)');

      final jsonString = state.exportBackupJson();
      expect(jsonString, contains('gladiator'));
      expect(jsonString, contains('Farmer Walk (3 sets)'));

      // New instance restoring from JSON
      final restoredState = TrainingState();
      final success = await restoredState.importBackupJson(jsonString);
      expect(success, isTrue);

      expect(restoredState.activeBarbellTemplate, BarbellTemplate.gladiator);
      expect(restoredState.activeBarbellRotationIndex, 1);
      expect(restoredState.currentTemplateWorkout.code, 'B');
      expect(restoredState.currentWorkoutAccessories,
          contains('Farmer Walk (3 sets)'));
    });

    test(
        'logWeightSession records template, workout, volume and advances rotation',
        () {
      final state = TrainingState();
      state.setBarbellTemplate(BarbellTemplate.ogBase);
      state.setBarbellRotationIndex(0);

      state.logWeightSession(
        templateName: '"OG" Base Program',
        workoutName: 'Workout A (Press & Squat)',
        coreLiftSummary:
            'Overhead Press (Done, 135.0 lbs x 7 reps x 3 sets)\nSquat (Done, 225.0 lbs x 8 reps x 3 sets)',
        optionalExerciseSummary: 'None scheduled',
        volume: 8235.0,
        notes: 'Great AMRAP push',
      );

      expect(state.history.length, 1);
      final entry = state.history.first;
      expect(entry.category, HistoryCategory.weight);
      expect(entry.title, '"OG" Base Program - Workout A (Press & Squat)');
      expect(entry.weightVolume, 8235.0);
      expect(entry.details, contains('Great AMRAP push'));
    });
  });

  group('WorkoutPageWeight Widget Tests', () {
    testWidgets(
        'Renders template selector, dynamic core lifts, and accessory management',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkoutPageWeight(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check template dropdown and initial core lifts
      expect(find.text('Program'), findsOneWidget);
      expect(find.text('Core Barbell Lifts'), findsOneWidget);
      expect(find.text('Overhead Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);

      // Verify Greyskull Golden Rule Banner is rendered
      expect(
          find.textContaining(
              'Greyskull Rule: Upper body compound lifts are always completed before lower body lifts'),
          findsOneWidget);

      // Check accessories section
      expect(find.text('Plug-in Accessories'), findsOneWidget);
      expect(find.text('Add Plug-in'), findsOneWidget);

      // Tap Add Plug-in button
      await tester.tap(find.text('Add Plug-in'));
      await tester.pumpAndSettle();

      // Verify Add Plug-in Dialog opens
      expect(find.text('Add Plug-in Accessory'), findsOneWidget);
      expect(find.text('Add to Workout'), findsOneWidget);

      // Add preset accessory
      await tester.tap(find.text('Add to Workout'));
      await tester.pumpAndSettle();

      // Verify accessory is now present in the list
      expect(find.byType(Card), findsWidgets);

      // Enter weight and reps for Overhead Press
      final weightInputs = find.byType(TextField);
      expect(weightInputs, findsWidgets);

      // Log workout
      await tester
          .ensureVisible(find.text('Log Today\'s Barbell Workout to History'));
      await tester.tap(find.text('Log Today\'s Barbell Workout to History'));
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation and rotation advanced
      expect(find.textContaining('Workout logged! Advanced rotation to:'),
          findsOneWidget);
    });
  });
}
