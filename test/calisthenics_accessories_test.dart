import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_frequency.dart';
import 'package:greyskull_lp/pages/workout_page_ladder.dart';
import 'package:greyskull_lp/pages/workout_page_totalwork.dart';
import 'package:greyskull_lp/widgets/calisthenics_accessories_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.frequency);
    trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.ladder);
    trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.totalWork);
  });

  group('Calisthenics Accessories - TrainingState Unit Tests', () {
    test('returns default accessories for each method', () {
      final freq =
          trainingState.getCalisthenicsAccessories(DailyMethod.frequency);
      expect(freq, contains('Dips'));
      expect(freq, contains('Hanging Knee Raises'));
      expect(
          trainingState.isCalisthenicsMethodCustomized(DailyMethod.frequency),
          isFalse);

      final ladder =
          trainingState.getCalisthenicsAccessories(DailyMethod.ladder);
      expect(ladder, contains('Dips'));
      expect(ladder, contains('Inverted Rows'));

      final total =
          trainingState.getCalisthenicsAccessories(DailyMethod.totalWork);
      expect(total, contains('Planks'));
      expect(total, contains('Walking Lunges'));
    });

    test('adds, reorders, removes and resets accessories per method', () {
      trainingState.addCalisthenicsAccessory(DailyMethod.frequency, 'Planks');
      expect(trainingState.getCalisthenicsAccessories(DailyMethod.frequency),
          contains('Planks'));
      expect(
          trainingState.isCalisthenicsMethodCustomized(DailyMethod.frequency),
          isTrue);

      final initialLength = trainingState
          .getCalisthenicsAccessories(DailyMethod.frequency)
          .length;
      trainingState.reorderCalisthenicsAccessories(
          DailyMethod.frequency, initialLength - 1, 0);
      expect(
          trainingState.getCalisthenicsAccessories(DailyMethod.frequency).first,
          equals('Planks'));

      trainingState.removeCalisthenicsAccessory(DailyMethod.frequency, 0);
      expect(trainingState.getCalisthenicsAccessories(DailyMethod.frequency),
          isNot(contains('Planks')));

      trainingState
          .resetCalisthenicsAccessoriesToDefault(DailyMethod.frequency);
      expect(
          trainingState.isCalisthenicsMethodCustomized(DailyMethod.frequency),
          isFalse);
    });

    test('survives JSON serialization and backup payload', () async {
      trainingState.addCalisthenicsAccessory(
          DailyMethod.frequency, 'Custom Burpees');
      trainingState.addCalisthenicsAccessory(
          DailyMethod.ladder, 'Custom Ring Dips');

      final backupJson = trainingState.exportBackupJson();
      expect(backupJson, contains('Custom Burpees'));
      expect(backupJson, contains('Custom Ring Dips'));

      trainingState
          .resetCalisthenicsAccessoriesToDefault(DailyMethod.frequency);
      trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.ladder);
      expect(trainingState.getCalisthenicsAccessories(DailyMethod.frequency),
          isNot(contains('Custom Burpees')));

      final restored = await trainingState.importBackupJson(backupJson);
      expect(restored, isTrue);
      expect(trainingState.getCalisthenicsAccessories(DailyMethod.frequency),
          contains('Custom Burpees'));
      expect(trainingState.getCalisthenicsAccessories(DailyMethod.ladder),
          contains('Custom Ring Dips'));
    });
  });

  group('Calisthenics Accessories - Widget Flow Tests', () {
    testWidgets(
        'CalisthenicsAccessoriesSection renders accessories and toggles',
        (tester) async {
      final completed = <String>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CalisthenicsAccessoriesSection(
                  method: DailyMethod.frequency,
                  completedAccessories: completed,
                  onCompletedChanged: (updated) {
                    setState(() {
                      completed
                        ..clear()
                        ..addAll(updated);
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Optional Accessories'), findsOneWidget);
      expect(find.text('Dips'), findsOneWidget);
      expect(find.text('Hanging Knee Raises'), findsOneWidget);

      // Tap checkbox next to Dips
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      expect(completed, contains('Dips'));
    });

    testWidgets('WorkoutPageFrequency displays accessories and logs to history',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageFrequency()),
        ),
      );
      await tester.pumpAndSettle();

      // Accessories are logged with the same counter row as push/chins.
      final increaseDips = find.byTooltip('Increase Dips');
      await tester.ensureVisible(increaseDips);
      await tester.tap(increaseDips);
      await tester.pumpAndSettle();

      final logSetBtn = find.text('Record This Set');
      expect(logSetBtn, findsOneWidget);
      await tester.ensureVisible(logSetBtn);
      await tester.tap(logSetBtn);
      await tester.pumpAndSettle();

      // Tap Log Today's Frequency Day to History
      final saveBtn = find.text("Log Today's Frequency Day to History");
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Session Saved'), findsOneWidget);
      final resetBtn = find.text("Reset Today's Tally");
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Verify in history
      final lastEntry = trainingState.history.first;
      expect(lastEntry.details, contains('Dips (11 reps)'));
    });

    testWidgets('WorkoutPageLadder displays accessories and logs to history',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageLadder()),
        ),
      );
      await tester.pumpAndSettle();

      // Log Rung 1
      final rungBtn = find.text('Hit Rung 1 (1 rep)');
      expect(rungBtn, findsOneWidget);
      await tester.tap(rungBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Ladder'));
      await tester.pumpAndSettle();

      // Count Inverted Rows with the same minus/value/plus row (#111).
      final increaseRows = find.byTooltip('Increase Inverted Rows');
      expect(increaseRows, findsOneWidget);
      await tester.ensureVisible(increaseRows);
      await tester.tap(increaseRows);
      await tester.pumpAndSettle();

      // Save to history
      final saveBtn = find.text('Log Ladder Session to History');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Ladder Session Saved'), findsOneWidget);
      await tester.tap(find.text('Clear Session'));
      await tester.pumpAndSettle();

      final lastEntry = trainingState.history.first;
      expect(lastEntry.details, contains('Inverted Rows (11 reps)'));
    });

    testWidgets('WorkoutPageTotalWork displays accessories and logs to history',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageTotalWork()),
        ),
      );
      await tester.pumpAndSettle();

      // Log set
      final recordSetBtn = find.text('Record Set (15 reps)');
      expect(recordSetBtn, findsOneWidget);
      await tester.tap(recordSetBtn);
      await tester.pumpAndSettle();

      // Count Planks (seconds) with the same row as push/chins (#111).
      final increasePlanks = find.byTooltip('Increase Planks');
      expect(increasePlanks, findsOneWidget);
      await tester.ensureVisible(increasePlanks);
      await tester.tap(increasePlanks);
      await tester.pumpAndSettle();

      // Save to history
      final saveBtn = find.text('Log Total Work Session to History');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Total Work Session Saved'), findsOneWidget);
      await tester.tap(find.text('Clear Session'));
      await tester.pumpAndSettle();

      final lastEntry = trainingState.history.first;
      expect(lastEntry.details, contains('Planks (35s)'));
    });
  });
}
