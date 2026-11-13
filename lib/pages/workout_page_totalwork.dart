import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';
import 'package:greyskull_lp/widgets/accessory_checklist.dart';
import 'package:greyskull_lp/widgets/tutorial_overlay.dart';

class WorkoutPageTotalWork extends StatefulWidget {
  const WorkoutPageTotalWork({super.key});

  @override
  State<WorkoutPageTotalWork> createState() => _WorkoutPageTotalWorkState();
}

class _WorkoutPageTotalWorkState extends State<WorkoutPageTotalWork> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Tutorials.showIfNeeded(context, 'total_work');
      }
    });
  }

  int _repsThisSet = 15;
  final Set<String> _completedAccessories = {};

  void _addSet() {
    if (_repsThisSet <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least 1 rep for this set.')),
      );
      return;
    }

    trainingState.addTotalWorkSet(_repsThisSet);

    if (trainingState.activeTotalWorkCompletedReps >=
        trainingState.activeTotalWorkTargetReps) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target reached! ${trainingState.activeTotalWorkCompletedReps} / ${trainingState.activeTotalWorkTargetReps} reps completed in ${trainingState.activeTotalWorkSets.length} sets.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _logSession() {
    final sets = trainingState.activeTotalWorkSets;
    if (sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Log at least one set before saving to history.')),
      );
      return;
    }

    final exercise = trainingState.activeTotalWorkExercise;
    final usedNegatives = trainingState.activeTotalWorkUsedNegatives;
    final target = trainingState.activeTotalWorkTargetReps;
    final model = trainingState.activeTotalWorkModel;
    final totalReps = trainingState.activeTotalWorkCompletedReps;

    final configuredAccessories =
        trainingState.getCalisthenicsAccessories(DailyMethod.totalWork);
    final accessorySummaries = <String>[];
    for (final acc in configuredAccessories) {
      final done = _completedAccessories.contains(acc);
      accessorySummaries.add('$acc [${done ? "Completed" : "Skipped"}]');
    }
    final optional = accessorySummaries.isEmpty
        ? 'None configured'
        : accessorySummaries.join(', ');

    final setBreakdown = sets
        .asMap()
        .entries
        .map((e) => 'Set ${e.key + 1}: ${e.value} reps')
        .join('\n');

    final isPushUp = exercise == 'Push-ups';
    final pushUps = isPushUp ? totalReps : 0;
    final chinUps = (exercise == 'Dead-Hang Chins' || exercise == 'Chin-ups')
        ? totalReps
        : 0;

    final details =
        'Exercise: $exercise${usedNegatives ? ' (negatives used)' : ''}\n'
        'Model: ${model == 'daily' ? 'Daily Work Target' : 'Weekly Work Target'}\n'
        'Target: $target reps\n'
        'Completed: $totalReps reps in ${sets.length} set${sets.length == 1 ? '' : 's'}\n'
        'Optional Accessories: $optional\n\n'
        'Sets Breakdown:\n$setBreakdown';

    final draft = trainingState.logDailyMethodSession(
      method: DailyMethod.totalWork,
      pushUps: pushUps,
      chinUps: chinUps,
      usedNegatives: usedNegatives,
      optionalExerciseSummary: optional,
      title:
          'Total Work Method ($exercise - ${model == 'daily' ? 'Daily' : 'Weekly'})',
      customDetails: details,
      metadata: {
        'exercise': exercise,
        'model': model,
        'targetReps': target,
        'totalReps': totalReps,
        'setsCount': sets.length,
        'sets': List<int>.from(sets),
        'accessories': accessorySummaries,
      },
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Total Work Session Saved'),
        content: Text(
          'Saved $totalReps reps of $exercise in ${sets.length} sets toward $target rep target.\n\n'
          'Would you like to clear this active session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Numbers'),
          ),
          ElevatedButton(
            onPressed: () {
              trainingState.resetActiveTotalWorkSession();
              setState(() {
                _completedAccessories.clear();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear Session'),
          ),
        ],
      ),
    ).then((_) {
      if (!mounted) return;
      if (trainingState.accountabilityMode ==
              AccountabilityPostMode.onWorkoutComplete &&
          draft != null) {
        AccountabilityPostSheet.show(context, draft: draft);
      } else if (trainingState.accountabilityMode ==
              AccountabilityPostMode.manual &&
          draft != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Total Work session logged to history'),
            action: SnackBarAction(
              label: 'Post to Forum',
              onPressed: () =>
                  AccountabilityPostSheet.show(context, draft: draft),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final selectedExercise = trainingState.activeTotalWorkExercise;
        final usedNegatives = trainingState.activeTotalWorkUsedNegatives;
        final model = trainingState.activeTotalWorkModel;
        final targetReps = trainingState.activeTotalWorkTargetReps;
        final sets = trainingState.activeTotalWorkSets;
        final completed = trainingState.activeTotalWorkCompletedReps;
        final remaining = trainingState.activeTotalWorkRemainingReps;
        final progress =
            targetReps > 0 ? (completed / targetReps).clamp(0.0, 1.0) : 0.0;
        final percent = (progress * 100).toInt();

        final targetPresets = model == 'daily'
            ? [
                selectedExercise == 'Dead-Hang Chins' ? 10 : 70,
                selectedExercise == 'Dead-Hang Chins' ? 20 : 100,
                selectedExercise == 'Dead-Hang Chins' ? 30 : 150,
              ]
            : [
                selectedExercise == 'Dead-Hang Chins' ? 60 : 420,
                selectedExercise == 'Dead-Hang Chins' ? 120 : 600,
              ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Work Method',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Hit daily or weekly volume targets per movement. Chip away in manageable sets.',
                  style: TextStyle(color: AppTheme.mutedText(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Exercise & Model Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Movement:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedExercise,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'Push-ups', child: Text('Push-ups')),
                        DropdownMenuItem(
                            value: 'Dead-Hang Chins',
                            child: Text('Dead-Hang Chins')),
                        DropdownMenuItem(
                            value: 'Sit-ups', child: Text('Sit-ups')),
                        DropdownMenuItem(
                            value: 'Burpees', child: Text('Burpees')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          trainingState.setTotalWorkExercise(val);
                          if (val == 'Dead-Hang Chins' && targetReps > 50) {
                            trainingState.setTotalWorkTargetReps(10);
                          } else if (val != 'Dead-Hang Chins' &&
                              targetReps < 50) {
                            trainingState.setTotalWorkTargetReps(70);
                          }
                        }
                      },
                    ),
                    if (selectedExercise == 'Dead-Hang Chins') ...[
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Used negatives instead of full dead-hang chins'),
                        subtitle: const Text(
                            'Jump/step to top, lower under control for 5–6s'),
                        value: usedNegatives,
                        onChanged: (val) =>
                            trainingState.setTotalWorkUsedNegatives(val),
                      ),
                    ],
                    const Divider(height: 24),
                    const Text('Target Model:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'daily', label: Text('Daily Target')),
                        ButtonSegment(
                            value: 'weekly',
                            label: Text('Weekly Target (Daily × 6)')),
                      ],
                      selected: {model},
                      onSelectionChanged: (set) {
                        final newModel = set.first;
                        trainingState.setTotalWorkModel(newModel);
                        if (newModel == 'weekly' && targetReps <= 150) {
                          trainingState.setTotalWorkTargetReps(targetReps * 6);
                        } else if (newModel == 'daily' && targetReps > 200) {
                          trainingState
                              .setTotalWorkTargetReps((targetReps / 6).round());
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Target Reps ($model): $targetReps reps',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ...targetPresets.map((reps) => ChoiceChip(
                              label: Text('$reps reps (preset)'),
                              selected: targetReps == reps,
                              onSelected: (_) =>
                                  trainingState.setTotalWorkTargetReps(reps),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Volume Progress',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('$completed / $targetReps reps ($percent%)'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sets completed: ${sets.length}',
                            style: const TextStyle(fontSize: 13)),
                        Text(
                          remaining == 0
                              ? 'Target achieved!'
                              : '$remaining reps remaining',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: remaining == 0
                                ? AppTheme.positiveAccent(context)
                                : AppTheme.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Log Set Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Set #${sets.length + 1}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet - 5).clamp(1, 200)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet - 1).clamp(1, 200)),
                          icon: const Icon(Icons.remove),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_repsThisSet reps',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet + 1).clamp(1, 200)),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet + 5).clamp(1, 200)),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: _addSet,
                        icon: const Icon(Icons.check),
                        label: Text('Record Set ($_repsThisSet reps)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Completed Sets List
            if (sets.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sets Completed (${sets.length}):',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () =>
                        trainingState.resetActiveTotalWorkSession(),
                    child: Text('Reset',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...sets.asMap().entries.map((entry) {
                final idx = entry.key;
                final reps = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.subtleFill(context),
                      child: Text('#${idx + 1}'),
                    ),
                    title: Text('Set ${idx + 1}: $reps reps'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: AppTheme.mutedText(context)),
                      onPressed: () => trainingState.removeTotalWorkSet(idx),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Accessories (configured in Settings)
            const Text(
              'Accessories',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            AccessoryChecklist(
              method: DailyMethod.totalWork,
              completed: _completedAccessories,
              onChanged: (updated) {
                setState(() {
                  _completedAccessories
                    ..clear()
                    ..addAll(updated);
                });
              },
            ),
            const SizedBox(height: 20),

            // Save Session to History
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: sets.isEmpty ? null : _logSession,
              icon: const Icon(Icons.save),
              label: const Text(
                'Log Total Work Session to History',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
