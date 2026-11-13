import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final entry in trainingState.history.toList()) {
      trainingState.deleteHistoryEntry(entry.id);
    }
  });

  Future<void> pumpHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryPage())),
    );
    await tester.pumpAndSettle();
  }

  HistoryEntry seedBarbellEntry() {
    trainingState.logWeightSession(
      coreLiftSummary: 'Squat 3x5 @ 135.0 lb\nBench Press 3x5 @ 115.0 lb',
      optionalExerciseSummary: 'Bicep Curls',
      volume: 2000.0,
      templateName: '"OG" Base Program',
      workoutName: 'Workout A',
      notes: 'Felt solid',
    );
    return trainingState.history.first;
  }

  group('History edit and delete (issue #52)', () {
    testWidgets('barbell sessions can be edited from History', (tester) async {
      final original = seedBarbellEntry();
      await pumpHistory(tester);

      expect(find.textContaining('Workout A'), findsWidgets);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Barbell Session'), findsOneWidget);

      // Title, core lifts, accessories, volume, notes.
      await tester.enterText(find.byType(TextField).at(0), 'Heavy Squat Day');
      await tester.enterText(
          find.byType(TextField).at(1), 'Squat 3x5 @ 185 lb');
      await tester.enterText(find.byType(TextField).at(2), 'None');
      await tester.enterText(find.byType(TextField).at(3), '4321.0');
      await tester.enterText(find.byType(TextField).at(4), 'Edited note');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final updated = trainingState.history.first;
      expect(updated.id, original.id);
      expect(updated.timestamp, original.timestamp);
      expect(updated.title, 'Heavy Squat Day');
      expect(updated.weightVolume, 4321.0);
      expect(updated.details, contains('Squat 3x5 @ 185 lb'));
      expect(updated.details, contains('Total Volume: 4321.0 lbs'));
      expect(updated.details, contains('Notes: Edited note'));
    });

    testWidgets('edits flow into Stats totals', (tester) async {
      seedBarbellEntry();
      await pumpHistory(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(3), '3500.0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final total = trainingState.history
          .where((e) => e.category == HistoryCategory.weight)
          .fold<double>(0, (sum, e) => sum + (e.weightVolume ?? 0));
      expect(total, 3500.0);
    });

    testWidgets('barbell sessions can be deleted from History', (tester) async {
      seedBarbellEntry();
      await pumpHistory(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Entry?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(trainingState.history, isEmpty);
    });

    testWidgets('calisthenics entries keep their method-specific editor',
        (tester) async {
      trainingState.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 30,
        chinUps: 10,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
        metadata: {'setsCount': 4},
      );
      await pumpHistory(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Entry'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Frequency Method Entry'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), '55');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(trainingState.history.first.pushUps, 55);
    });

    test('edited entries survive backup export and import', () async {
      final state = TrainingState();
      state.logWeightSession(
        coreLiftSummary: 'Squat 3x5 @ 135 lb',
        optionalExerciseSummary: 'None',
        volume: 2000,
        templateName: '"OG" Base Program',
        workoutName: 'Workout A',
      );
      final original = state.history.first;
      state.updateHistoryEntry(original.copyWith(
        title: 'Edited in history',
        details: 'Core Lifts: Squat 3x5 @ 225 lb\nAccessories: None\n'
            'Total Volume: 3400.0 lbs',
        weightVolume: 3400,
      ));

      final payload = state.exportBackupJson();
      final restored = TrainingState();
      expect(await restored.importBackupJson(payload), isTrue);

      final restoredEntry = restored.history.first;
      expect(restoredEntry.title, 'Edited in history');
      expect(restoredEntry.weightVolume, 3400);
      expect(restoredEntry.details, contains('225 lb'));

      restored.deleteHistoryEntry(restoredEntry.id);
      final afterDelete = TrainingState();
      expect(
        await afterDelete.importBackupJson(restored.exportBackupJson()),
        isTrue,
      );
      expect(afterDelete.history, isEmpty);
    });
  });
}
