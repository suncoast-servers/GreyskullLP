import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class WorkoutPageLadder extends StatefulWidget {
  const WorkoutPageLadder({super.key});

  @override
  State<WorkoutPageLadder> createState() => _WorkoutPageLadderState();
}

class _WorkoutPageLadderState extends State<WorkoutPageLadder> {
  void _completeRung() {
    trainingState.recordLadderRung();
  }

  void _undoRung() {
    trainingState.undoLadderRung();
  }

  void _finishCurrentLadder() {
    if (trainingState.activeCurrentLadderRungs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Complete at least one rung before finishing the ladder.')),
      );
      return;
    }

    final finishedRungs =
        List<int>.from(trainingState.activeCurrentLadderRungs);
    final ladderNum = trainingState.activeCompletedLadders.length + 1;
    trainingState.finishCurrentLadder();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Completed Ladder #$ladderNum (${finishedRungs.join("-")}). Take a partner-paced rest and begin next ladder!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logSession() {
    final allLadders =
        List<List<int>>.from(trainingState.activeCompletedLadders);
    if (trainingState.activeCurrentLadderRungs.isNotEmpty) {
      allLadders.add(List<int>.from(trainingState.activeCurrentLadderRungs));
    }

    if (allLadders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Complete at least one ladder before logging to history.')),
      );
      return;
    }

    final exercise = trainingState.activeLadderExercise;
    final usedNegatives = trainingState.activeLadderUsedNegatives;
    final totalReps = trainingState.activeLadderTotalReps;
    final peak = trainingState.activeLadderPeakRung;
    final optional = trainingState.selectedDailyOptionalExercises.isEmpty
        ? 'None selected'
        : trainingState.selectedDailyOptionalExercises.join(', ');

    final ladderBreakdown = allLadders
        .asMap()
        .entries
        .map((e) =>
            'Ladder ${e.key + 1}: ${e.value.join("-")} (${e.value.fold<int>(0, (s, r) => s + r)} reps)')
        .join('\n');

    final isPushUp = exercise == 'Push-ups';
    final pushUps = isPushUp ? totalReps : 0;
    final chinUps = isPushUp ? 0 : totalReps;

    final details =
        'Exercise: $exercise${usedNegatives ? ' (negatives used)' : ''}\n'
        'Total Reps: $totalReps\n'
        'Ladders completed: ${allLadders.length}\n'
        'Peak Rung: $peak\n'
        'Optional: $optional\n\n'
        'Ladders Breakdown:\n$ladderBreakdown';

    trainingState.logDailyMethodSession(
      method: DailyMethod.ladder,
      pushUps: pushUps,
      chinUps: chinUps,
      usedNegatives: usedNegatives,
      optionalExerciseSummary: optional,
      title: 'Ladder Method Session ($exercise)',
      customDetails: details,
      metadata: {
        'exercise': exercise,
        'totalReps': totalReps,
        'peakRung': peak,
        'laddersCount': allLadders.length,
        'ladders': allLadders,
      },
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ladder Session Saved'),
        content: Text(
          'Saved $totalReps reps of $exercise across ${allLadders.length} ladder(s) (Peak rung: $peak).\n\n'
          'Would you like to clear this active session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Numbers'),
          ),
          ElevatedButton(
            onPressed: () {
              trainingState.resetActiveLadderSession();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear Session'),
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
        final isActive = trainingState.activeDailyMethod == DailyMethod.ladder;
        final currentLadderNum =
            trainingState.activeCompletedLadders.length + 1;
        final nextRung = trainingState.activeLadderNextRung;
        final totalReps = trainingState.activeLadderTotalReps;
        final peakRung = trainingState.activeLadderPeakRung;
        final completedLadders = trainingState.activeCompletedLadders;
        final currentRungs = trainingState.activeCurrentLadderRungs;
        final selectedExercise = trainingState.activeLadderExercise;
        final usedNegatives = trainingState.activeLadderUsedNegatives;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ladder Method',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Ascending waves (1, 2, 3...) per ladder. Weapon of choice when frequency through the day is impossible.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Chip(
                    label: Text('Active',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.black12,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isActive)
              OutlinedButton.icon(
                onPressed: () =>
                    trainingState.setActiveDailyMethod(DailyMethod.ladder),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Set as Active Method'),
              ),
            const SizedBox(height: 12),

            // Book Guidelines Alert
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Guidance (3rd Edition pp. 65–70):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Ladders vs Pyramids: Hardest sets are followed immediately by the easiest set (1 rep) for superior recovery.\n'
                    '• Pacing: Rest partner-style — the time it would take an imaginary partner to complete your set.\n'
                    '• Gold Standard: Build up toward 5 ladders of 5 reps (75 total reps).',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Movement Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Movement:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'Chin-ups',
                            label: Text('Chin-ups (Primary)'),
                            icon: Icon(Icons.fitness_center)),
                        ButtonSegment(
                            value: 'Push-ups', label: Text('Push-ups')),
                      ],
                      selected: {selectedExercise},
                      onSelectionChanged: (set) =>
                          trainingState.setLadderExercise(set.first),
                    ),
                    if (selectedExercise == 'Chin-ups') ...[
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Used negatives instead of full chin-ups'),
                        subtitle: const Text(
                            'Jump/step to top, lower under control for 5–6s'),
                        value: usedNegatives,
                        onChanged: (val) =>
                            trainingState.setLadderUsedNegatives(val),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Session Stats Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(label: 'Total Reps', value: '$totalReps'),
                    _StatColumn(
                      label: 'Ladders Done',
                      value:
                          '${completedLadders.length + (currentRungs.isNotEmpty ? 1 : 0)}',
                    ),
                    _StatColumn(label: 'Peak Rung', value: '$peakRung'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Ladder Card
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
                        Text(
                          'Active: Ladder #$currentLadderNum',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        if (currentRungs.isNotEmpty)
                          TextButton.icon(
                            onPressed: _undoRung,
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('Undo Rung'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentRungs.isEmpty
                          ? 'Starting fresh ladder. First rung is 1 rep.'
                          : 'Rungs completed: ${currentRungs.join(" → ")} (${currentRungs.fold<int>(0, (s, r) => s + r)} reps)',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _completeRung,
                            icon: const Icon(Icons.check),
                            label: Text(
                                'Hit Rung $nextRung ($nextRung rep${nextRung == 1 ? '' : 's'})'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: currentRungs.isEmpty
                              ? null
                              : _finishCurrentLadder,
                          child: const Text('Finish Ladder'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Completed Ladders
            if (completedLadders.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completed Ladders (${completedLadders.length}):',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => trainingState.resetActiveLadderSession(),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...completedLadders.asMap().entries.map((entry) {
                final idx = entry.key;
                final rungs = entry.value;
                final reps = rungs.fold<int>(0, (s, r) => s + r);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Text('#${idx + 1}'),
                    ),
                    title: Text('Rungs: ${rungs.join(" - ")}'),
                    subtitle: Text('Volume: $reps reps (Peak: ${rungs.last})'),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => trainingState.removeCompletedLadder(idx),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Optional Add-ons Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Optional Accessories (from Settings):',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          trainingState.selectedDailyOptionalExercises.isEmpty
                              ? [const Chip(label: Text('None selected yet'))]
                              : trainingState.selectedDailyOptionalExercises
                                  .map((e) => Chip(label: Text(e)))
                                  .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Session to History
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (completedLadders.isEmpty && currentRungs.isEmpty)
                  ? null
                  : _logSession,
              icon: const Icon(Icons.save),
              label: const Text(
                'Log Ladder Session to History',
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

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
