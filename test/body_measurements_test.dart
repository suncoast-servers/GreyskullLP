import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/body_measurement.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/diet_page.dart';
import 'package:greyskull_lp/pages/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final m in trainingState.bodyMeasurements.toList()) {
      trainingState.deleteBodyMeasurement(m.id);
    }
  });

  group('Body measurements model (issue #57)', () {
    test('every field is optional and round-trips through JSON', () {
      final measurement = BodyMeasurement(
        date: DateTime(2026, 11, 12),
        weightKg: 111.6,
        waistCm: 104,
      );
      expect(measurement.hasAnyValue, isTrue);

      final revived = BodyMeasurement.fromJsonMap(measurement.toJsonMap());
      expect(revived.weightKg, 111.6);
      expect(revived.waistCm, 104.0);
      expect(revived.bodyFatPct, isNull);
      expect(revived.date.day, 12);
    });

    test('entries without values are not considered measurable', () {
      expect(BodyMeasurement().hasAnyValue, isFalse);
    });
  });

  group('TrainingState body measurement storage', () {
    test('adds, updates, orders newest first and deletes', () {
      final state = TrainingState();
      final older = state.upsertBodyMeasurement(BodyMeasurement(
        date: DateTime.now().subtract(const Duration(days: 5)),
        weightKg: 112.4,
      ));
      final newer = state.upsertBodyMeasurement(BodyMeasurement(
        date: DateTime.now(),
        weightKg: 111.6,
      ));

      expect(older, isNotNull);
      expect(newer, isNotNull);
      expect(state.bodyMeasurements.first.weightKg, 111.6);

      state.upsertBodyMeasurement(newer!.copyWith(bodyFatPct: 24.5));
      expect(state.bodyMeasurements.length, 2);
      expect(state.latestBodyMeasurement!.bodyFatPct, 24.5);

      state.deleteBodyMeasurement(newer.id);
      expect(state.bodyMeasurements.length, 1);
      expect(state.latestBodyMeasurement!.weightKg, 112.4);
    });

    test('blank measurements are ignored', () {
      final state = TrainingState();
      expect(state.upsertBodyMeasurement(BodyMeasurement()), isNull);
      expect(state.bodyMeasurements, isEmpty);
    });

    test('progress photo survives JSON and backup round-trips', () async {
      final state = TrainingState();
      state.upsertBodyMeasurement(BodyMeasurement(
        weightKg: 110,
        photoBase64: 'ZmFrZS1qcGVn',
      ));

      final payload = state.exportBackupJson();
      expect(payload, contains('ZmFrZS1qcGVn'));

      final restored = TrainingState();
      expect(await restored.importBackupJson(payload), isTrue);
      expect(restored.bodyMeasurements.single.photoBase64,
          'ZmFrZS1qcgVn'.replaceAll('cgVn', 'cGVn'));
    });

    test('measurements survive backup export and import', () async {
      final state = TrainingState();
      state.upsertBodyMeasurement(BodyMeasurement(
        date: DateTime(2026, 11, 12),
        weightKg: 110.2,
        bodyFatPct: 22.4,
        waistCm: 101,
        chestCm: 112,
        armsCm: 38,
        notes: 'morning',
      ));

      final payload = state.exportBackupJson();
      final restored = TrainingState();
      expect(await restored.importBackupJson(payload), isTrue);

      final entry = restored.bodyMeasurements.single;
      expect(entry.weightKg, 110.2);
      expect(entry.bodyFatPct, 22.4);
      expect(entry.waistCm, 101);
      expect(entry.chestCm, 112);
      expect(entry.armsCm, 38);
      expect(entry.notes, 'morning');
    });
  });

  group('Diet card', () {
    testWidgets('logs a measurement through the bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DietPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Body Measurements'), findsOneWidget);
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      expect(find.text('Log Body Measurement'), findsOneWidget);
      final weightField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Bodyweight (kg)',
      );
      await tester.enterText(weightField, '111.2');
      await tester.tap(find.text('Save Measurement'));
      await tester.pumpAndSettle();

      expect(trainingState.bodyMeasurements.length, 1);
      expect(trainingState.latestBodyMeasurement!.weightKg, 111.2);
      expect(find.text('Weight'), findsOneWidget);
    });
  });

  group('Stats trend', () {
    testWidgets('shows a bodyweight trend card from logged measurements',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Stats requires at least one session in range to render the tabs.
      trainingState.logDailyMethodSession(
        method: DailyMethod.frequency,
        pushUps: 10,
        chinUps: 3,
        usedNegatives: false,
        optionalExerciseSummary: 'None',
      );
      trainingState.upsertBodyMeasurement(BodyMeasurement(
        weightKg: 114,
      ));
      trainingState.upsertBodyMeasurement(BodyMeasurement(
        weightKg: 111.5,
      ));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatsPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bodyweight Trend'), findsOneWidget);
      expect(find.textContaining('Latest: 111.5 kg'), findsOneWidget);
    });
  });
}
