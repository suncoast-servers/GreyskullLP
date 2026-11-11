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
    if (entry.method == DailyMethod.frequency) {
      _showFrequencyEditDialog(context, entry);
    } else if (entry.method == DailyMethod.ladder) {
      _showLadderEditDialog(context, entry);
    } else if (entry.method == DailyMethod.totalWork) {
      _showTotalWorkEditDialog(context, entry);
    } else {
      _showGenericEditDialog(context, entry);
    }
  }

  void _showFrequencyEditDialog(BuildContext context, HistoryEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    final pushUpsController =
        TextEditingController(text: (entry.pushUps ?? 0).toString());
    final chinUpsController =
        TextEditingController(text: (entry.chinUps ?? 0).toString());
    final setsCountController = TextEditingController(
      text: (entry.methodMetadata?['setsCount'] as int? ?? 1).toString(),
    );
    bool usedNegatives = entry.details.contains('negatives used') ||
        (entry.methodMetadata?['usedNegatives'] as bool? ?? false);
    final notesController = TextEditingController(text: entry.details);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Frequency Method Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pushUpsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Total Push-ups'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: chinUpsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Total Chin-ups'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: setsCountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Sets Completed'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Used Chin-up Negatives'),
                  value: usedNegatives,
                  onChanged: (val) => setDialogState(() => usedNegatives = val),
                ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Notes / Details'),
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
                final newPushUps =
                    int.tryParse(pushUpsController.text) ?? entry.pushUps ?? 0;
                final newChinUps =
                    int.tryParse(chinUpsController.text) ?? entry.chinUps ?? 0;
                final newSets = int.tryParse(setsCountController.text) ?? 1;

                final meta =
                    Map<String, dynamic>.from(entry.methodMetadata ?? {});
                meta['setsCount'] = newSets;
                meta['usedNegatives'] = usedNegatives;

                final updated = entry.copyWith(
                  title: titleController.text.trim(),
                  pushUps: newPushUps,
                  chinUps: newChinUps,
                  details:
                      'Total Push-ups: $newPushUps\nTotal Chin-ups: $newChinUps${usedNegatives ? ' (negatives used)' : ''}\nSets completed: $newSets\n\nNotes:\n${notesController.text.trim()}',
                  methodMetadata: meta,
                );

                trainingState.updateHistoryEntry(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Frequency session updated.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLadderEditDialog(BuildContext context, HistoryEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    String exercise = entry.methodMetadata?['exercise'] as String? ??
        ((entry.chinUps ?? 0) > 0 ? 'Chin-ups' : 'Push-ups');
    final totalRepsController = TextEditingController(
      text: (entry.methodMetadata?['totalReps'] as int? ??
              (exercise == 'Push-ups' ? entry.pushUps : entry.chinUps) ??
              0)
          .toString(),
    );
    final peakRungController = TextEditingController(
      text: (entry.methodMetadata?['peakRung'] as int? ?? 1).toString(),
    );
    final laddersCountController = TextEditingController(
      text: (entry.methodMetadata?['laddersCount'] as int? ?? 1).toString(),
    );
    bool usedNegatives = entry.details.contains('negatives used') ||
        (entry.methodMetadata?['usedNegatives'] as bool? ?? false);
    final notesController = TextEditingController(text: entry.details);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Ladder Method Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: exercise,
                  decoration: const InputDecoration(labelText: 'Movement'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Chin-ups', child: Text('Chin-ups')),
                    DropdownMenuItem(
                        value: 'Push-ups', child: Text('Push-ups')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => exercise = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalRepsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Total Reps'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: peakRungController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Peak Rung'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: laddersCountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Ladders Completed'),
                ),
                if (exercise == 'Chin-ups')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Used Chin-up Negatives'),
                    value: usedNegatives,
                    onChanged: (val) =>
                        setDialogState(() => usedNegatives = val),
                  ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Notes / Details'),
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
                final newReps = int.tryParse(totalRepsController.text) ?? 0;
                final newPeak = int.tryParse(peakRungController.text) ?? 1;
                final newLadders =
                    int.tryParse(laddersCountController.text) ?? 1;

                final meta =
                    Map<String, dynamic>.from(entry.methodMetadata ?? {});
                meta['exercise'] = exercise;
                meta['totalReps'] = newReps;
                meta['peakRung'] = newPeak;
                meta['laddersCount'] = newLadders;
                meta['usedNegatives'] = usedNegatives;

                final isPushUp = exercise == 'Push-ups';
                final updated = entry.copyWith(
                  title: titleController.text.trim(),
                  pushUps: isPushUp ? newReps : 0,
                  chinUps: isPushUp ? 0 : newReps,
                  details:
                      'Exercise: $exercise${usedNegatives ? ' (negatives used)' : ''}\nTotal Reps: $newReps\nLadders completed: $newLadders\nPeak Rung: $newPeak\n\nNotes:\n${notesController.text.trim()}',
                  methodMetadata: meta,
                );

                trainingState.updateHistoryEntry(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ladder session updated.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTotalWorkEditDialog(BuildContext context, HistoryEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    String exercise =
        entry.methodMetadata?['exercise'] as String? ?? 'Push-ups';
    String model = entry.methodMetadata?['model'] as String? ?? 'daily';
    final targetRepsController = TextEditingController(
      text: (entry.methodMetadata?['targetReps'] as int? ?? 70).toString(),
    );
    final totalRepsController = TextEditingController(
      text: (entry.methodMetadata?['totalReps'] as int? ??
              (exercise == 'Push-ups' ? entry.pushUps : entry.chinUps) ??
              0)
          .toString(),
    );
    final setsCountController = TextEditingController(
      text: (entry.methodMetadata?['setsCount'] as int? ?? 1).toString(),
    );
    bool usedNegatives = entry.details.contains('negatives used') ||
        (entry.methodMetadata?['usedNegatives'] as bool? ?? false);
    final notesController = TextEditingController(text: entry.details);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Total Work Method Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: [
                    'Push-ups',
                    'Dead-Hang Chins',
                    'Sit-ups',
                    'Burpees'
                  ].contains(exercise)
                      ? exercise
                      : 'Push-ups',
                  decoration: const InputDecoration(labelText: 'Movement'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Push-ups', child: Text('Push-ups')),
                    DropdownMenuItem(
                        value: 'Dead-Hang Chins',
                        child: Text('Dead-Hang Chins')),
                    DropdownMenuItem(value: 'Sit-ups', child: Text('Sit-ups')),
                    DropdownMenuItem(value: 'Burpees', child: Text('Burpees')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => exercise = val);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: model,
                  decoration: const InputDecoration(labelText: 'Target Model'),
                  items: const [
                    DropdownMenuItem(
                        value: 'daily', child: Text('Daily Work Target')),
                    DropdownMenuItem(
                        value: 'weekly', child: Text('Weekly Work Target')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => model = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetRepsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Target Reps'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: totalRepsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Completed Reps'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: setsCountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Sets Completed'),
                ),
                if (exercise == 'Dead-Hang Chins')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Used Negatives'),
                    value: usedNegatives,
                    onChanged: (val) =>
                        setDialogState(() => usedNegatives = val),
                  ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Notes / Details'),
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
                final newTarget = int.tryParse(targetRepsController.text) ?? 70;
                final newTotal = int.tryParse(totalRepsController.text) ?? 0;
                final newSets = int.tryParse(setsCountController.text) ?? 1;

                final meta =
                    Map<String, dynamic>.from(entry.methodMetadata ?? {});
                meta['exercise'] = exercise;
                meta['model'] = model;
                meta['targetReps'] = newTarget;
                meta['totalReps'] = newTotal;
                meta['setsCount'] = newSets;
                meta['usedNegatives'] = usedNegatives;

                final isPushUp = exercise == 'Push-ups';
                final isChin = exercise == 'Dead-Hang Chins';
                final updated = entry.copyWith(
                  title: titleController.text.trim(),
                  pushUps: isPushUp ? newTotal : 0,
                  chinUps: isChin ? newTotal : 0,
                  details:
                      'Exercise: $exercise${usedNegatives ? ' (negatives used)' : ''}\nModel: ${model == 'daily' ? 'Daily Work Target' : 'Weekly Work Target'}\nTarget: $newTarget reps\nCompleted: $newTotal reps in $newSets sets\n\nNotes:\n${notesController.text.trim()}',
                  methodMetadata: meta,
                );

                trainingState.updateHistoryEntry(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Total Work session updated.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenericEditDialog(BuildContext context, HistoryEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    final detailsController = TextEditingController(text: entry.details);
    final weightVolumeController = TextEditingController(
      text: entry.weightVolume != null ? entry.weightVolume.toString() : '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${entry.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              if (entry.category == HistoryCategory.weight) ...[
                TextField(
                  controller: weightVolumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Weight Volume (lbs/kg)'),
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
              final newVolume = double.tryParse(weightVolumeController.text);

              final updated = entry.copyWith(
                title: titleController.text.trim(),
                details: detailsController.text.trim(),
                weightVolume: newVolume ?? entry.weightVolume,
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
