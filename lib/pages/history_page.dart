import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final entries = trainingState.history;
        if (entries.isEmpty) {
          return const Center(
            child: Text(
                'No activity logged yet. Complete a workout to build history.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final date = entry.timestamp;
            final stamp =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

            return Card(
              child: ListTile(
                title: Text(entry.title),
                subtitle: Text(
                  '$stamp\n${_labelForCategory(entry.category)}\n${entry.details}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  String _labelForCategory(HistoryCategory category) {
    switch (category) {
      case HistoryCategory.weight:
        return 'Category: Resistance';
      case HistoryCategory.daily:
        return 'Category: Daily Calisthenics';
      case HistoryCategory.diet:
        return 'Category: Diet';
    }
  }
}
