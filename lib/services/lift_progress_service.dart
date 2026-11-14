import 'package:greyskull_lp/models/training_state.dart';

/// One data point in a lift's progression line.
class LiftPoint {
  const LiftPoint({required this.date, required this.estimatedOneRm});

  final DateTime date;
  final double estimatedOneRm;
}

/// A lift with its chronological estimated-1RM points.
class LiftSeries {
  const LiftSeries({required this.lift, required this.points});

  final String lift;
  final List<LiftPoint> points;

  double get latest => points.isEmpty ? 0 : points.last.estimatedOneRm;
  double get first => points.isEmpty ? 0 : points.first.estimatedOneRm;
  double get change => latest - first;
}

/// Derives per-lift progression from logged resistance sessions (#87).
///
/// Johnny Pain's programs are progress-driven rather than volume-driven, so
/// Stats charts estimated 1RM per lift. Data is parsed from the human-readable
/// history details the logger already writes.
class LiftProgressService {
  const LiftProgressService._();

  /// App log format: `Bench Press (Done, 185.0 lbs x 8 reps x 3 sets)`.
  static final RegExp _appFormat = RegExp(
    r'([A-Za-z][A-Za-z /()\-]+?)\s*\((?:Done|Not marked)[^,]*,\s*'
    r'([\d.]+)\s*lbs?\s*x\s*(\d+)\s*reps',
  );

  /// Book/demo format: `Bench Press 3x5 @ 185 lb (AMRAP 8)`.
  static final RegExp _bookFormat = RegExp(
    r'([A-Za-z][A-Za-z /()\-]+?)\s+(\d+)x(\d+)\s*@\s*([\d.]+)\s*lb'
    r'(?:\s*\(AMRAP\s*(\d+)\))?',
  );

  /// Epley estimate, using the AMRAP reps when the set recorded them.
  static double estimatedOneRm(double weight, int reps) {
    if (weight <= 0) return 0;
    final effectiveReps = reps <= 0 ? 1 : reps;
    return weight * (1 + effectiveReps / 30);
  }

  /// Extracts (lift, 1RM estimate) pairs from one resistance entry.
  static Map<String, double> entryEstimates(HistoryEntry entry) {
    if (entry.category != HistoryCategory.weight) return const {};
    final output = <String, double>{};

    void record(String name, double weight, int reps) {
      final clean = name.trim();
      final estimate = estimatedOneRm(weight, reps);
      if (clean.isEmpty || estimate <= 0) return;
      if (!output.containsKey(clean) || output[clean]! < estimate) {
        output[clean] = estimate;
      }
    }

    for (final line in entry.details.split('\n')) {
      var matched = false;
      for (final app in _appFormat.allMatches(line)) {
        matched = true;
        record(
          app.group(1)!,
          double.tryParse(app.group(2) ?? '') ?? 0,
          int.tryParse(app.group(3) ?? '') ?? 0,
        );
      }
      if (matched) continue;
      for (final book in _bookFormat.allMatches(line)) {
        final prescribed = int.tryParse(book.group(3) ?? '') ?? 5;
        final amrap = int.tryParse(book.group(5) ?? '');
        record(
          book.group(1)!,
          double.tryParse(book.group(4) ?? '') ?? 0,
          amrap ?? prescribed,
        );
      }
    }
    return output;
  }

  /// Canonical display order (issue #115): the four main barbell lifts first,
  /// then plug-in accessories alphabetically.
  static const List<String> canonicalOrder = [
    'Bench Press',
    'Squat',
    'Overhead Press',
    'Deadlift',
  ];

  /// Bench, squat, OHP, deadlift, then accessories A-Z.
  static int compareLifts(String a, String b) {
    final indexA = canonicalOrder.indexOf(a);
    final indexB = canonicalOrder.indexOf(b);
    if (indexA >= 0 && indexB >= 0) return indexA.compareTo(indexB);
    if (indexA >= 0) return -1;
    if (indexB >= 0) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  /// Builds chronological series for every lift found in [entries]
  /// (entries are expected newest-first, as returned by TrainingState).
  ///
  /// Pass `maxLifts: null` to keep every lift (the Stats page does).
  static List<LiftSeries> seriesFor(
    Iterable<HistoryEntry> entries, {
    int? maxLifts = 3,
  }) {
    final chronological = entries
        .where((e) => e.category == HistoryCategory.weight)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final points = <String, List<LiftPoint>>{};
    for (final entry in chronological) {
      entryEstimates(entry).forEach((lift, estimate) {
        points.putIfAbsent(lift, () => <LiftPoint>[]).add(
              LiftPoint(date: entry.timestamp, estimatedOneRm: estimate),
            );
      });
    }

    final series = points.entries
        .where((e) => e.value.length >= 2)
        .map((e) => LiftSeries(lift: e.key, points: e.value))
        .toList()
      ..sort((a, b) => compareLifts(a.lift, b.lift));

    return maxLifts == null ? series : series.take(maxLifts).toList();
  }
}
