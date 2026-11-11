import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/widgets/custom_program_editor_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.resetCustomTemplateToDefault();
    trainingState.setBarbellTemplate(BarbellTemplate.custom);
    trainingState.setBarbellRotationIndex(0);
  });

  group('Custom Barbell Program - Unit & Business Logic Tests', () {
    test('Default custom program initializes with factory 2-day template', () {
      expect(trainingState.activeBarbellTemplate, BarbellTemplate.custom);
      expect(trainingState.isCustomTemplateActive, isTrue);
      expect(trainingState.customTemplateName,
          'Custom Program (Build from Zero)');
      expect(trainingState.customTemplateSubtitle,
          'User-designed linear progression template');

      final details = trainingState.activeBarbellTemplateDetails;
      expect(details.template, BarbellTemplate.custom);
      expect(details.workouts.length, 2);

      final dayA = details.workouts[0];
      expect(dayA.code, 'A');
      expect(dayA.coreLifts.length, 2);
      expect(dayA.coreLifts[0].name, 'Bench Press');
      expect(dayA.coreLifts[0].isUpperBody, isTrue);
      expect(dayA.coreLifts[1].name, 'Squat');
      expect(dayA.coreLifts[1].isUpperBody, isFalse);

      final dayB = details.workouts[1];
      expect(dayB.code, 'B');
      expect(dayB.coreLifts.length, 2);
      expect(dayB.coreLifts[0].name, 'Overhead Press');
      expect(dayB.coreLifts[0].isUpperBody, isTrue);
      expect(dayB.coreLifts[1].name, 'Deadlift');
      expect(dayB.coreLifts[1].sets, 1);
    });

    test('Custom program name and subtitle can be updated', () {
      trainingState.setCustomTemplateName('Powerbuilding Split');
      trainingState.setCustomTemplateSubtitle('Heavy compounds + volume');

      expect(trainingState.customTemplateName, 'Powerbuilding Split');
      expect(
          trainingState.customTemplateSubtitle, 'Heavy compounds + volume');
      expect(trainingState.isCustomTemplateModified, isTrue);

      final details = trainingState.activeBarbellTemplateDetails;
      expect(details.name, 'Powerbuilding Split');
      expect(details.subtitle, 'Heavy compounds + volume');
    });

    test('Add, reorder, and remove core lifts in custom workout day', () {
      expect(trainingState.customTemplateWorkouts[0].coreLifts.length, 2);

      // Add Incline Bench Press
      trainingState.addCoreLiftToCustomWorkout(
        0,
        const TemplateLift(
          name: 'Incline Bench Press',
          prescription: '2 x 5, 1 x 5+',
          sets: 3,
          defaultReps: 5,
          isAmrap: true,
          isUpperBody: true,
        ),
      );

      final liftsAfterAdd =
          trainingState.customTemplateWorkouts[0].coreLifts;
      expect(liftsAfterAdd.length, 3);
      expect(liftsAfterAdd.last.name, 'Incline Bench Press');

      // Reorder: move Incline Bench Press from index 2 to index 0
      trainingState.reorderCoreLiftsInCustomWorkout(0, 2, 0);
      final liftsAfterReorder =
          trainingState.customTemplateWorkouts[0].coreLifts;
      expect(liftsAfterReorder.first.name, 'Incline Bench Press');

      // Remove lift at index 1
      final removedName = liftsAfterReorder[1].name;
      trainingState.removeCoreLiftFromCustomWorkout(0, 1);
      final liftsAfterRemove =
          trainingState.customTemplateWorkouts[0].coreLifts;
      expect(liftsAfterRemove.length, 2);
      expect(
          liftsAfterRemove.any((l) => l.name == removedName), isFalse);
    });

    test('Add and remove workout days in custom program', () {
      expect(trainingState.customTemplateWorkouts.length, 2);

      // Add Day C
      trainingState.addCustomWorkoutDay(
        code: 'C',
        title: 'Workout C',
        subtitle: 'Shoulders & Arms',
      );

      expect(trainingState.customTemplateWorkouts.length, 3);
      expect(trainingState.customTemplateWorkouts[2].code, 'C');
      expect(trainingState.customTemplateWorkouts[2].title, 'Workout C');

      // Remove Day C
      trainingState.removeCustomWorkoutDay(2);
      expect(trainingState.customTemplateWorkouts.length, 2);
    });

    test('Duplicate from book preset clones days, lifts, and accessories', () {
      trainingState.duplicateTemplateFromPreset(BarbellTemplate.gladiator);

      expect(trainingState.customTemplateName, contains('Gladiator'));
      expect(trainingState.customTemplateWorkouts.length, 3);
      expect(trainingState.customTemplateWorkouts[2].coreLifts[0].name,
          'Incline Bench Press');
      expect(trainingState.customTemplateWorkouts[2].coreLifts[1].name,
          'Front Squat');

      // Verify official Gladiator template was not altered
      final officialGladiator =
          TrainingState.templateDefinitions[BarbellTemplate.gladiator]!;
      expect(officialGladiator.workouts.length, 3);
    });

    test('Reset to factory restores default 2-day custom program', () {
      trainingState.duplicateTemplateFromPreset(BarbellTemplate.fourDaySplit);
      expect(trainingState.customTemplateWorkouts.length, 4);

      trainingState.resetCustomTemplateToDefault();
      expect(trainingState.customTemplateName,
          'Custom Program (Build from Zero)');
      expect(trainingState.customTemplateWorkouts.length, 2);
      expect(trainingState.isCustomTemplateModified, isFalse);
    });

    test('Custom program survives JSON export and import without data loss',
        () async {
      trainingState.setCustomTemplateName('My Custom Strength Program');
      trainingState.setCustomTemplateSubtitle('3-Day modified GSLP');
      trainingState.addCustomWorkoutDay(
        code: 'C',
        title: 'Workout C (Conditioning)',
        coreLifts: const [
          TemplateLift(
            name: 'Power Clean',
            prescription: '5 x 3',
            sets: 5,
            defaultReps: 3,
            isAmrap: false,
            isUpperBody: false,
          ),
        ],
      );

      final jsonBackup = trainingState.exportBackupJson();
      expect(jsonBackup, contains('My Custom Strength Program'));
      expect(jsonBackup, contains('Power Clean'));

      // Restore into fresh state
      final freshState = TrainingState();
      final imported = await freshState.importBackupJson(jsonBackup);
      expect(imported, isTrue);

      expect(freshState.activeBarbellTemplate, BarbellTemplate.custom);
      expect(freshState.customTemplateName, 'My Custom Strength Program');
      expect(freshState.customTemplateSubtitle, '3-Day modified GSLP');
      expect(freshState.customTemplateWorkouts.length, 3);
      expect(freshState.customTemplateWorkouts[2].code, 'C');
      expect(freshState.customTemplateWorkouts[2].coreLifts[0].name,
          'Power Clean');
    });
  });

  group('Custom Barbell Program - Widget Flow Tests', () {
    testWidgets(
        'WorkoutPageWeight renders custom program controls and opens editor',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageWeight()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom program is selected
      expect(find.text('Custom Program (Build from Zero)'), findsOneWidget);
      expect(find.byKey(const Key('customize_program_btn')), findsOneWidget);
      expect(find.byKey(const Key('duplicate_preset_btn')), findsOneWidget);

      // Tap Customize Program button to open editor sheet
      await tester.tap(find.byKey(const Key('customize_program_btn')));
      await tester.pumpAndSettle();

      // Verify CustomProgramEditorSheet is open
      expect(find.text('Customize Barbell Program'), findsOneWidget);
      expect(find.text('Build from zero without book presets'), findsOneWidget);
      expect(find.text('Program Identity'), findsOneWidget);
      expect(find.text('Workout Days (2)'), findsOneWidget);

      // Tap Done to close sheet
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Customize Barbell Program'), findsNothing);
    });

    testWidgets('Duplicate Preset dialog clones template into custom program',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageWeight()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Duplicate Preset
      await tester.tap(find.byKey(const Key('duplicate_preset_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Duplicate from Book Preset'), findsOneWidget);
      expect(find.text('"Villain" Arms & Neck Plugin'), findsOneWidget);

      // Select Villain preset
      await tester.tap(find.text('"Villain" Arms & Neck Plugin'));
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation and updated custom program
      expect(
          find.textContaining('Cloned "Villain" Arms & Neck Plugin into Custom Program'),
          findsOneWidget);
      expect(trainingState.customTemplateName, contains('Villain'));
      expect(find.byKey(const Key('reset_custom_btn')), findsOneWidget);
    });

    testWidgets('Revert to factory dialog restores default custom template',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Modify custom program first
      trainingState.duplicateTemplateFromPreset(BarbellTemplate.villain);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageWeight()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Revert to Factory
      final resetBtn = find.byKey(const Key('reset_custom_btn'));
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset to Factory Defaults?'), findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Revert to Factory')));
      await tester.pumpAndSettle();

      expect(trainingState.customTemplateName,
          'Custom Program (Build from Zero)');
      expect(trainingState.isCustomTemplateModified, isFalse);
    });
  });
}
