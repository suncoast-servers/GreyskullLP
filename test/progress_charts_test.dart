import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/calisthenics_progress_service.dart';
import 'package:greyskull_lp/services/lift_progress_service.dart';

HistoryEntry _weight(DateTime date, String details) => HistoryEntry(
      timestamp: date,
      title: 'Workout',
      category: HistoryCategory.weight,
      details: details,
    );

HistoryEntry _daily(
  DateTime date, {
  int pushUps = 0,
  int chinUps = 0,
  List<String> accessories = const [],
}) =>
    HistoryEntry(
      timestamp: date,
      title: 'Daily',
      category: HistoryCategory.daily,
      details: 'Session',
      pushUps: pushUps,
      chinUps: chinUps,
      methodMetadata: {'accessories': accessories},
    );

void main() {
  group('Resistance chart order (issue #115)', () {
    test('bench, squat, overhead press, deadlift, then accessories A-Z', () {
      final day = DateTime(2026, 1, 1);
      final entries = <HistoryEntry>[];
      for (var i = 0; i < 2; i++) {
        entries.add(_weight(
          day.add(Duration(days: i)),
          'Zercher Squat (Done, 100.0 lbs x 5 reps x 3 sets)\n'
          'Deadlift (Done, 200.0 lbs x 5 reps x 1 set)\n'
          'Squat (Done, 150.0 lbs x 5 reps x 3 sets)\n'
          'Bench Press (Done, 185.0 lbs x 8 reps x 3 sets)\n'
          'Overhead Press (Done, 95.0 lbs x 5 reps x 3 sets)\n'
          'Dips (Done, 45.0 lbs x 8 reps x 3 sets)',
        ));
      }

      final series = LiftProgressService.seriesFor(entries, maxLifts: null);
      expect(series.map((s) => s.lift).toList(), [
        'Bench Press',
        'Squat',
        'Overhead Press',
        'Deadlift',
        'Dips',
        'Zercher Squat',
      ]);
    });
  });

  group('Calisthenics chart order (issue #115)', () {
    test('push-ups, chins, then accessories A-Z', () {
      final day = DateTime(2026, 2, 1);
      final entries = [
        _daily(day, pushUps: 20, chinUps: 5, accessories: ['Planks (30s)']),
        _daily(day.add(const Duration(days: 1)),
            pushUps: 25,
            chinUps: 7,
            accessories: ['Dips (10 reps)', 'Planks (35s)']),
        _daily(day.add(const Duration(days: 2)),
            pushUps: 30, chinUps: 9, accessories: ['Dips (12 reps)']),
      ];

      final series = CalisthenicsProgressService.seriesFor(entries);
      expect(series.map((s) => s.name).toList(),
          ['Push-ups', 'Chin-ups', 'Dips', 'Planks']);
      expect(series.first.points.map((p) => p.value).toList(), [20, 25, 30]);
      expect(series[2].latest, 12);
    });
  });
}
