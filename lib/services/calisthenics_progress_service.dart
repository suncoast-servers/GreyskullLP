import 'package:greyskull_lp/models/training_state.dart';

/// One point in a calisthenics progression line.
class MethodPoint {
  const MethodPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

/// A calisthenics lift (push-ups, chin-ups or an accessory) with its history.
class MethodSeries {
  const MethodSeries({required this.name, required this.points});

  final String name;
  final List<MethodPoint> points;

  double get latest => points.isEmpty ? 0 : points.last.value;
  double get first => points.isEmpty ? 0 : points.first.value;
  double get change => latest - first;
}

/// Per-lift repetition progression for the calisthenics methods (#115).
///
/// Push-ups and chin-ups come from the session totals; accessories are read
/// from the accessory metadata the method pages already write.
class CalisthenicsProgressService {
  const CalisthenicsProgressService._();

  static final RegExp _reps = RegExp(r'^(.+?)\s*\((\d+)\s*reps?\)$');
  static final RegExp _seconds = RegExp(r'^(.+?)\s*\((\d+)\s*s\)$');

  static List<MethodSeries> seriesFor(Iterable<HistoryEntry> entries) {
    final chronological = entries
        .where((e) => e.category == HistoryCategory.daily)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final points = <String, List<MethodPoint>>{};

    void add(String name, DateTime date, double value) {
      if (name.trim().isEmpty || value <= 0) return;
      points.putIfAbsent(name.trim(), () => <MethodPoint>[]).add(
            MethodPoint(date: date, value: value),
          );
    }

    for (final entry in chronological) {
      final pushUps = entry.pushUps ?? 0;
      final chinUps = entry.chinUps ?? 0;
      if (pushUps > 0) add('Push-ups', entry.timestamp, pushUps.toDouble());
      if (chinUps > 0) add('Chin-ups', entry.timestamp, chinUps.toDouble());

      final raw = entry.methodMetadata?['accessories'];
      final summaries = raw is List
          ? raw.map((e) => e.toString())
          : <String>[
              if (entry.details.contains('Optional Accessories:'))
                ...entry.details
                    .split('Optional Accessories:')
                    .last
                    .split('\n')
                    .first
                    .split(',')
            ];

      for (final summary in summaries) {
        final text = summary.trim();
        final seconds = _seconds.firstMatch(text);
        if (seconds != null) {
          add(
            seconds.group(1)!,
            entry.timestamp,
            double.tryParse(seconds.group(2)!) ?? 0,
          );
          continue;
        }
        final reps = _reps.firstMatch(text);
        if (reps != null) {
          add(
            reps.group(1)!,
            entry.timestamp,
            double.tryParse(reps.group(2)!) ?? 0,
          );
        }
      }
    }

    final series = points.entries
        .where((e) => e.value.length >= 2)
        .map((e) => MethodSeries(name: e.key, points: e.value))
        .toList()
      ..sort((a, b) {
        const order = ['Push-ups', 'Chin-ups'];
        final indexA = order.indexOf(a.name);
        final indexB = order.indexOf(b.name);
        if (indexA >= 0 && indexB >= 0) return indexA.compareTo(indexB);
        if (indexA >= 0) return -1;
        if (indexB >= 0) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return series;
  }
}
