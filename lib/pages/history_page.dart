import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryCategory? _selectedCategory;

  void _showDeleteDialog(BuildContext context, HistoryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
            'Are you sure you want to delete "${entry.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              trainingState.deleteHistoryEntry(entry.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, HistoryEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    final detailsController = TextEditingController(text: entry.details);
    final pushUpsController = TextEditingController(
        text: entry.pushUps != null ? entry.pushUps.toString() : '');
    final chinUpsController = TextEditingController(
        text: entry.chinUps != null ? entry.chinUps.toString() : '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit History Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              if (entry.category == HistoryCategory.daily) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pushUpsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Push-ups'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: chinUpsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Chin-ups'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: detailsController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Details / Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPushUps = int.tryParse(pushUpsController.text);
              final newChinUps = int.tryParse(chinUpsController.text);

              final updated = entry.copyWith(
                title: titleController.text.trim(),
                details: detailsController.text.trim(),
                pushUps: newPushUps ?? entry.pushUps,
                chinUps: newChinUps ?? entry.chinUps,
              );

              trainingState.updateHistoryEntry(updated);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry updated.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, HistoryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Logged: ${entry.timestamp.toLocal()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text('Category: ${_labelForCategory(entry.category)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (entry.method != null) ...[
                const SizedBox(height: 4),
                Text('Method: ${TrainingState.methodLabel(entry.method!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              const Divider(height: 20),
              Text(entry.details),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        var entries = trainingState.history;

        if (_selectedCategory != null) {
          entries =
              entries.where((e) => e.category == _selectedCategory).toList();
        }

        return Column(
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Daily Calisthenics'),
                    selected: _selectedCategory == HistoryCategory.daily,
                    onSelected: (sel) => setState(() =>
                        _selectedCategory = sel ? HistoryCategory.daily : null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Resistance'),
                    selected: _selectedCategory == HistoryCategory.weight,
                    onSelected: (sel) => setState(() => _selectedCategory =
                        sel ? HistoryCategory.weight : null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Diet'),
                    selected: _selectedCategory == HistoryCategory.diet,
                    onSelected: (sel) => setState(() =>
                        _selectedCategory = sel ? HistoryCategory.diet : null),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        _selectedCategory == null
                            ? 'No activity logged yet. Complete a workout to build history.'
                            : 'No entries for this filter.',
                      ),
                    )
                  : ListView.separated(
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
                            onTap: () => _showDetailsDialog(context, entry),
                            title: Row(
                              children: [
                                Expanded(
                                    child: Text(entry.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))),
                                if (entry.method != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      TrainingState.methodLabel(entry.method!),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '$stamp • ${_labelForCategory(entry.category)}\n${entry.details}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) {
                                if (val == 'view') {
                                  _showDetailsDialog(context, entry);
                                } else if (val == 'edit') {
                                  _showEditDialog(context, entry);
                                } else if (val == 'delete') {
                                  _showDeleteDialog(context, entry);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                    value: 'view', child: Text('View Details')),
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit Entry')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _labelForCategory(HistoryCategory category) {
    switch (category) {
      case HistoryCategory.weight:
        return 'Resistance';
      case HistoryCategory.daily:
        return 'Daily Calisthenics';
      case HistoryCategory.diet:
        return 'Diet';
    }
  }
}
