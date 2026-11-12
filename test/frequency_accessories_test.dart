import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_frequency.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Accessory measurement (issue #51)', () {
    test('holds log seconds, dynamic movements log reps', () {
      expect(TrainingState.measurementForAccessory('Planks'),
          AccessoryMeasurement.seconds);
      expect(TrainingState.measurementForAccessory('Hollow Body Hold'),
          AccessoryMeasurement.seconds);
      expect(TrainingState.measurementForAccessory('Wall Sit'),
          AccessoryMeasurement.seconds);

      expect(TrainingState.measurementForAccessory('Dips'),
          AccessoryMeasurement.reps);
      expect(TrainingState.measurementForAccessory('Sit-ups'),
          AccessoryMeasurement.reps);
      expect(TrainingState.measurementForAccessory('Hanging Knee Raises'),
          AccessoryMeasurement.reps);
    });

    test('default values follow the measurement unit', () {
      expect(TrainingState.defaultAccessoryValue('Planks'), 30);
      expect(TrainingState.defaultAccessoryValue('Dips'), 10);
    });
  });

  group('Frequency accessory logging', () {
    test('logs, summarises, undoes and clears accessories', () {
      final state = TrainingState();
      expect(state.todayFrequencyAccessories, isEmpty);
      expect(state.todayFrequencyAccessorySummary, 'None');

      final plank = state.logFrequencyAccessory('Planks');
      expect(plank.unit, AccessoryMeasurement.seconds);
      expect(plank.value, 30);
      expect(state.todayFrequencyAccessorySummary, 'Planks (30s)');
      expect(state.completedFrequencyAccessories, {'Planks'});

      state.logFrequencyAccessory('Dips', value: 12);
      expect(state.todayFrequencyAccessories.length, 2);
      expect(state.completedFrequencyAccessories, {'Planks', 'Dips'});
      expect(state.frequencyAccessoryLogFor('Dips')?.formattedValue, '12 reps');
      expect(
          state.todayFrequencyAccessorySummary, 'Planks (30s), Dips (12 reps)');

      state.undoFrequencyAccessory('Dips');
      expect(state.todayFrequencyAccessories.length, 1);
      expect(state.frequencyAccessoryLogFor('Dips'), isNull);

      state.clearTodayFrequencyAccessories();
      expect(state.todayFrequencyAccessories, isEmpty);
    });

    test('accessory logs survive backup export and import', () async {
      final state = TrainingState();
      state.logFrequencyAccessory('Planks', value: 45);
      state.logFrequencyAccessory('Dips', value: 15);

      final payload = state.exportBackupJson();
      final restored = TrainingState();
      expect(await restored.importBackupJson(payload), isTrue);

      expect(restored.todayFrequencyAccessories.length, 2);
      expect(
          restored.frequencyAccessoryLogFor('Planks')?.formattedValue, '45s');
      expect(
          restored.frequencyAccessoryLogFor('Dips')?.formattedValue, '15 reps');
    });
  });

  group('Daily auto-save rollover', () {
    DateTime dayBefore(int days) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days));
    }

    Map<String, dynamic> payloadWithYesterdaySets({
      required int savedSetCount,
      required int setCount,
    }) {
      final yesterday = dayBefore(1);
      final sets = List.generate(setCount, (index) {
        final timestamp =
            yesterday.add(Duration(hours: 8 + index, minutes: 15));
        return {
          'pushUps': 10 + index,
          'chinUps': 2,
          'usedNegatives': index.isOdd,
          'timestamp': timestamp.toIso8601String(),
        };
      });
      return {
        'schemaVersion': 2,
        'frequencyTrackingDate': yesterday.toIso8601String(),
        'frequencyDaySavedSetCount': savedSetCount,
        'todayFrequencySets': sets,
        'todayFrequencyAccessories': [
          {
            'name': 'Planks',
            'value': 60,
            'unit': 'seconds',
            'timestamp': yesterday.toIso8601String(),
          },
        ],
      };
    }

    test('archives unsaved sets and clears the day when the day rolls over',
        () async {
      final yesterday = dayBefore(1);
      SharedPreferences.setMockInitialValues({
        'greyskull_training_state_v1':
            jsonEncode(payloadWithYesterdaySets(savedSetCount: 0, setCount: 2)),
      });

      final state = TrainingState();
      await state.loadFromDisk();

      // Today's tally starts empty.
      expect(state.todayFrequencySets, isEmpty);
      expect(state.todayFrequencyAccessories, isEmpty);

      // ...and yesterday's work was auto-saved into history.
      expect(state.history.length, 1);
      final entry = state.history.first;
      expect(entry.method, DailyMethod.frequency);
      expect(entry.pushUps, 21); // 10 + 11
      expect(entry.chinUps, 4);
      expect(entry.title, contains('Frequency Method Day Summary'));
      expect(entry.details, contains('Auto-saved at day rollover'));
      expect(entry.details, contains('Planks (60s)'));
      expect(entry.methodMetadata?['autoSaved'], isTrue);
      expect(entry.timestamp.day, yesterday.day);
    });

    test('does not duplicate a day that was already logged manually', () async {
      SharedPreferences.setMockInitialValues({
        'greyskull_training_state_v1':
            jsonEncode(payloadWithYesterdaySets(savedSetCount: 2, setCount: 2)),
      });

      final state = TrainingState();
      await state.loadFromDisk();

      expect(state.todayFrequencySets, isEmpty);
      expect(state.history, isEmpty);
    });

    test('auto-saves only the sets added after a manual save', () async {
      SharedPreferences.setMockInitialValues({
        'greyskull_training_state_v1':
            jsonEncode(payloadWithYesterdaySets(savedSetCount: 1, setCount: 2)),
      });

      final state = TrainingState();
      await state.loadFromDisk();

      expect(state.history.length, 1);
      final entry = state.history.first;
      expect(entry.pushUps, 11); // only the second set
      expect(entry.title, contains('(Continued)'));
    });

    test('ensureCurrentDay is a no-op while the day is current', () {
      final state = TrainingState();
      state.addFrequencySet(pushUps: 10, chinUps: 3, usedNegatives: false);

      state.ensureCurrentDay();

      expect(state.todayFrequencySets.length, 1);
      expect(state.history, isEmpty);
    });
  });

  group('Frequency widget wiring (issue #51)', () {
    testWidgets('push-up stepper increments one rep at a time', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      trainingState.clearTodayFrequencySets();
      trainingState.clearTodayFrequencyAccessories();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageFrequency()),
        ),
      );

      await tester.scrollUntilVisible(find.text('Push-ups: 10 reps'), 100);
      expect(find.text('Push-ups: 10 reps'), findsOneWidget);

      final stepperRow = find
          .ancestor(
            of: find.text('Push-ups: 10 reps'),
            matching: find.byType(Row),
          )
          .first;
      await tester.tap(
        find.descendant(
          of: stepperRow,
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await tester.pump();

      expect(find.text('Push-ups: 11 reps'), findsOneWidget);
      expect(find.text('Push-ups: 16 reps'), findsNothing);
    });

    testWidgets('tapping a configured accessory logs it with the right unit',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      trainingState.clearTodayFrequencySets();
      trainingState.clearTodayFrequencyAccessories();
      trainingState.addCalisthenicsAccessory(DailyMethod.frequency, 'Planks');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageFrequency()),
        ),
      );

      final planksTile = find.text('Planks').first;
      await tester.scrollUntilVisible(planksTile, 100);
      await tester.tap(planksTile);
      await tester.pumpAndSettle();

      // Time-based accessory asks for seconds, not reps.
      expect(find.text('Log Planks'), findsOneWidget);
      expect(find.text('30 s'), findsOneWidget);

      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();

      expect(trainingState.todayFrequencyAccessories.single.name, 'Planks');
      expect(
          trainingState.todayFrequencyAccessories.single.formattedValue, '30s');
      expect(find.text('Logged 30s'), findsOneWidget);
    });
  });
}
