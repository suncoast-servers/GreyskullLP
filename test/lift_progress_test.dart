import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/lift_progress_service.dart';

HistoryEntry _entry(String details, DateTime date, {double volume = 0}) =>
    HistoryEntry(
      timestamp: date,
      title: 'Session',
      details: details,
      category: HistoryCategory.weight,
      weightVolume: volume,
    );

void main() {
  group('Lift progress service (issue #87)', () {
    test('Epley estimate uses AMRAP reps when present', () {
      expect(LiftProgressService.estimatedOneRm(100, 5), closeTo(116.67, 0.01));
      expect(
          LiftProgressService.estimatedOneRm(100, 10), closeTo(133.33, 0.01));
      expect(LiftProgressService.estimatedOneRm(0, 5), 0);
    });

    test('parses lifts from the logged details format', () {
      final appFormat = _entry(
        'Bench Press (Done, 185.0 lbs x 8 reps x 3 sets); '
        'Deadlift (Not marked, 225.0 lbs x 6 reps x 1 sets)',
        DateTime(2026, 11, 2),
      );
      final appEstimates = LiftProgressService.entryEstimates(appFormat);
      expect(appEstimates['Bench Press'], closeTo(234.33, 0.5));
      expect(appEstimates['Deadlift'], closeTo(270, 0.5));

      final bookFormat = _entry(
        'Core Lifts: Bench Press 3x5 @ 185 lb (AMRAP 8); '
        'Deadlift 1x5 @ 225 lb (AMRAP 6)\n'
        'Accessories: None\nTotal Volume: 3000.0 lbs',
        DateTime(2026, 11, 1),
      );
      final bookEstimates = LiftProgressService.entryEstimates(bookFormat);
      expect(bookEstimates['Bench Press'], closeTo(234.33, 0.5));
      expect(bookEstimates['Deadlift'], closeTo(270, 0.5));
    });

    test('builds chronological series and ranks by improvement', () {
      final entries = [
        _entry('Core Lifts: Bench Press 3x5 @ 205 lb (AMRAP 6)',
            DateTime(2026, 11, 10)),
        _entry(
            'Core Lifts: Squat 3x5 @ 275 lb (AMRAP 5)', DateTime(2026, 11, 9)),
        _entry('Core Lifts: Bench Press 3x5 @ 185 lb (AMRAP 5)',
            DateTime(2026, 11, 3)),
        _entry(
            'Core Lifts: Squat 3x5 @ 265 lb (AMRAP 5)', DateTime(2026, 11, 2)),
      ];

      final series = LiftProgressService.seriesFor(entries);
      expect(series, isNotEmpty);
      final bench = series.firstWhere((s) => s.lift == 'Bench Press');
      expect(bench.points.length, 2);
      expect(bench.points.first.date.isBefore(bench.points.last.date), isTrue);
      expect(bench.change, greaterThan(0));
      expect(series.first.lift, 'Bench Press');
    });

    test('ignores calisthenics and diet entries', () {
      final daily = HistoryEntry(
        timestamp: DateTime(2026, 11, 1),
        title: 'Frequency',
        details: 'Total Push-ups: 40',
        category: HistoryCategory.daily,
      );
      expect(LiftProgressService.seriesFor([daily]), isEmpty);
    });
  });
}
