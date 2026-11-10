import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  _Range _range = _Range.week;

  bool _isInRange(DateTime date) {
    final now = DateTime.now();
    switch (_range) {
      case _Range.week:
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case _Range.month:
        return date.isAfter(now.subtract(const Duration(days: 30)));
      case _Range.year:
        return date.isAfter(now.subtract(const Duration(days: 365)));
      case _Range.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final rangedEntries = trainingState.history
            .where((entry) => _isInRange(entry.timestamp))
            .toList();
        final weightEntries = rangedEntries
            .where((entry) => entry.category == HistoryCategory.weight)
            .toList();
        final dailyEntries = rangedEntries
            .where((entry) => entry.category == HistoryCategory.daily)
            .toList();
        final dietEntries = rangedEntries
            .where((entry) => entry.category == HistoryCategory.diet)
            .toList();

        final totalVolume = weightEntries.fold<double>(
          0,
          (sum, entry) => sum + (entry.weightVolume ?? 0),
        );
        final totalPushUps = dailyEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.pushUps ?? 0),
        );
        final totalChinUps = dailyEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.chinUps ?? 0),
        );
        final totalProtein = dietEntries.fold<int>(
          0,
          (sum, entry) => sum + (entry.proteinGrams ?? 0),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Progress Stats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<_Range>(
              segments: const [
                ButtonSegment(value: _Range.week, label: Text('7d')),
                ButtonSegment(value: _Range.month, label: Text('30d')),
                ButtonSegment(value: _Range.year, label: Text('1y')),
                ButtonSegment(value: _Range.all, label: Text('All')),
              ],
              selected: {_range},
              onSelectionChanged: (selection) =>
                  setState(() => _range = selection.first),
            ),
            const SizedBox(height: 12),
            _StatCard(
                title: 'Weight Volume', value: totalVolume.toStringAsFixed(1)),
            _StatCard(title: 'Push-ups Logged', value: '$totalPushUps'),
            _StatCard(
                title: 'Chin-ups / Negatives Logged', value: '$totalChinUps'),
            _StatCard(title: 'Protein Logged (g)', value: '$totalProtein'),
            const SizedBox(height: 12),
            const Text(
              'Recent Sessions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (rangedEntries.isEmpty)
              const Text('No activity in selected range.')
            else
              ...rangedEntries.take(12).map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.title),
                        subtitle: Text(entry.details),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

enum _Range {
  week,
  month,
  year,
  all,
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
