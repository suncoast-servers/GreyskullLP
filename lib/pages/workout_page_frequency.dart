import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/calisthenics_reminder_service.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';
import 'package:greyskull_lp/widgets/method_lift_row.dart';
import 'package:greyskull_lp/widgets/tutorial_overlay.dart';

class WorkoutPageFrequency extends StatefulWidget {
  const WorkoutPageFrequency({super.key});

  @override
  State<WorkoutPageFrequency> createState() => _WorkoutPageFrequencyState();
}

class _WorkoutPageFrequencyState extends State<WorkoutPageFrequency>
    with WidgetsBindingObserver {
  int _pushUpsThisSet = 10;
  int _chinUpsThisSet = 3;
  bool _usedNegatives = false;
  final Map<String, int> _accessoryThisSet = {};
  final Set<String> _touchedAccessories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-save rollover: if the app was left open (or resumed) after
    // midnight, close out yesterday before showing today's tally.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trainingState.ensureCurrentDay();
      if (mounted) {
        Tutorials.showIfNeeded(context, 'frequency');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      trainingState.ensureCurrentDay();
    }
  }

  int _accessoryValue(String name) =>
      _accessoryThisSet[name] ?? TrainingState.defaultAccessoryValue(name);

  String _accessoryUnit(String name) =>
      TrainingState.measurementForAccessory(name) ==
              AccessoryMeasurement.seconds
          ? 's'
          : 'reps';

  int _accessoryStep(String name) =>
      TrainingState.measurementForAccessory(name) ==
              AccessoryMeasurement.seconds
          ? 5
          : 1;

  void _addSet() {
    if (_pushUpsThisSet == 0 && _chinUpsThisSet == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log at least 1 push-up or chin-up.')),
      );
      return;
    }

    trainingState.addFrequencySet(
      pushUps: _pushUpsThisSet,
      chinUps: _chinUpsThisSet,
      usedNegatives: _usedNegatives,
    );
    for (final name in _touchedAccessories) {
      final value = _accessoryValue(name);
      if (value <= 0) continue;
      trainingState.logFrequencyAccessory(
        name,
        value: value,
        unit: TrainingState.measurementForAccessory(name),
      );
    }
    _touchedAccessories.clear();
    unawaited(CalisthenicsReminderService.noteSetLogged());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged set: $_pushUpsThisSet push-ups, $_chinUpsThisSet chin-ups${_usedNegatives ? ' (negatives)' : ''}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveSessionToHistory() {
    final sets = trainingState.todayFrequencySets;
    if (sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Log at least one set before saving session to history.')),
      );
      return;
    }

    final totalPushUps = trainingState.todayFrequencyPushUps;
    final totalChinUps = trainingState.todayFrequencyChinUps;
    final anyNegatives = sets.any((s) => s.usedNegatives);

    final accessoryLogs = trainingState.todayFrequencyAccessories;
    final accessorySummaries = accessoryLogs
        .map((log) => '${log.name} (${log.formattedValue})')
        .toList();
    final optional = trainingState.todayFrequencyAccessorySummary;

    final setBreakdown = sets
        .asMap()
        .entries
        .map((e) =>
            'Set ${e.key + 1}: ${e.value.pushUps} push-ups, ${e.value.chinUps} chin-ups${e.value.usedNegatives ? ' (negatives)' : ''}')
        .join('\n');

    final details =
        'Total Push-ups: $totalPushUps / ${trainingState.dailyPushUpTarget}\n'
        'Total Chin-ups: $totalChinUps / ${trainingState.dailyChinUpTarget}${anyNegatives ? ' (negatives used)' : ''}\n'
        'Sets completed: ${sets.length}\n'
        'Optional Accessories: $optional\n\n'
        'Breakdown:\n$setBreakdown';

    unawaited(CalisthenicsReminderService.cancel());

    final draft = trainingState.logDailyMethodSession(
      method: DailyMethod.frequency,
      pushUps: totalPushUps,
      chinUps: totalChinUps,
      usedNegatives: anyNegatives,
      optionalExerciseSummary: optional,
      title: 'Frequency Method Day Summary',
      customDetails: details,
      metadata: {
        'setsCount': sets.length,
        'pushUpTarget': trainingState.dailyPushUpTarget,
        'chinUpTarget': trainingState.dailyChinUpTarget,
        'sets': sets.map((s) => s.toJsonMap()).toList(),
        'accessories': accessorySummaries,
      },
    );

    // Remember what was captured so the midnight auto-save does not duplicate.
    trainingState.markFrequencyDaySavedToHistory();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Saved'),
        content: Text(
          'Frequency session logged to history with $totalPushUps push-ups and $totalChinUps chin-ups across ${sets.length} sets.\n\n'
          'Would you like to reset today\'s active tally?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Tally'),
          ),
          ElevatedButton(
            onPressed: () {
              trainingState.clearTodayFrequencySets();
              trainingState.clearTodayFrequencyAccessories();
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset Today\'s Tally'),
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
            content: const Text('Frequency session logged to history'),
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
        final totalPushUps = trainingState.todayFrequencyPushUps;
        final totalChinUps = trainingState.todayFrequencyChinUps;
        final pushUpTarget = trainingState.dailyPushUpTarget;
        final chinUpTarget = trainingState.dailyChinUpTarget;
        final sets = trainingState.todayFrequencySets;
        final accessories =
            trainingState.getCalisthenicsAccessories(DailyMethod.frequency);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequency Method',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Sub-maximal sets spaced throughout the day. Stay shy of failure.',
                  style: TextStyle(color: AppTheme.mutedText(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily Progress Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Accumulated Volume',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _ProgressBar(
                      label: 'Push-ups',
                      current: totalPushUps,
                      target: pushUpTarget,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    _ProgressBar(
                      label: 'Chin-ups / Negatives',
                      current: totalChinUps,
                      target: chinUpTarget,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Accessories',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (accessories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No accessories configured. Add them in Settings → Calisthenics Accessories.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.mutedText(context)),
                        ),
                      )
                    else
                      ...accessories.map((name) {
                        final log =
                            trainingState.frequencyAccessoryLogFor(name);
                        return MethodLiftProgressRow(
                          label: name,
                          current: log?.value ?? 0,
                          target: TrainingState.defaultAccessoryValue(name),
                          unit: _accessoryUnit(name),
                        );
                      }),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${sets.length} set${sets.length == 1 ? '' : 's'} logged today',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
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
                    const Text(
                      'Log a Frequency Set',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Perform when fresh. Stop well before exhaustion.',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.mutedText(context)),
                    ),
                    const SizedBox(height: 12),
                    _RepStepper(
                      label: 'Push-ups',
                      value: _pushUpsThisSet,
                      step: 1,
                      onChanged: (val) =>
                          setState(() => _pushUpsThisSet = val.clamp(0, 100)),
                    ),
                    const SizedBox(height: 8),
                    _RepStepper(
                      label: 'Chin-ups',
                      value: _chinUpsThisSet,
                      step: 1,
                      onChanged: (val) =>
                          setState(() => _chinUpsThisSet = val.clamp(0, 50)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title:
                          const Text('Used negatives instead of full chin-ups'),
                      subtitle: const Text(
                          'Jump or step to top, lower under control (5-6s)'),
                      value: _usedNegatives,
                      onChanged: (val) => setState(() => _usedNegatives = val),
                    ),
                    if (accessories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Accessories',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ...accessories.map(
                        (name) => MethodLiftCounterRow(
                          label: name,
                          value: _accessoryValue(name),
                          unit: _accessoryUnit(name),
                          step: _accessoryStep(name),
                          onChanged: (next) => setState(() {
                            _accessoryThisSet[name] = next;
                            _touchedAccessories.add(name);
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addSet,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Record This Set'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Today's Sets List
            if (sets.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Sets (${sets.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => trainingState.clearTodayFrequencySets(),
                    child: Text('Clear All',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                final time =
                    '${set.timestamp.hour.toString().padLeft(2, '0')}:${set.timestamp.minute.toString().padLeft(2, '0')}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.subtleFill(context),
                      child: Text('#${index + 1}'),
                    ),
                    title: Text(
                      '${set.pushUps} push-ups, ${set.chinUps} chin-ups${set.usedNegatives ? ' (negatives)' : ''}',
                    ),
                    subtitle: Text('Logged at $time'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: AppTheme.mutedText(context)),
                      onPressed: () => trainingState.removeFrequencySet(index),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            // Save to History Action
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: sets.isEmpty ? null : _saveSessionToHistory,
              icon: const Icon(Icons.save),
              label: const Text(
                'Log Today\'s Frequency Day to History',
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final int current;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$current / $target reps ($percent%)'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.subtleFill(context),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _RepStepper extends StatelessWidget {
  const _RepStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text('$label: $value reps',
                style: const TextStyle(fontSize: 15))),
        IconButton(
          onPressed: () => onChanged(value - step),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: () => onChanged(value + step),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
