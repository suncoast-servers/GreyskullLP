import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class WorkoutPageLadder extends StatefulWidget {
  const WorkoutPageLadder({super.key});

  @override
  State<WorkoutPageLadder> createState() => _WorkoutPageLadderState();
}

class _WorkoutPageLadderState extends State<WorkoutPageLadder> {
  String _selectedExercise = 'Push-ups';
  bool _usedNegatives = false;

  final List<List<int>> _completedLadders = [];
  final List<int> _currentLadderRungs = [];

  int get _nextRung =>
      _currentLadderRungs.isEmpty ? 1 : _currentLadderRungs.last + 1;

  int get _totalReps {
    final fromCompleted = _completedLadders.fold<int>(
        0, (sum, ladder) => sum + ladder.fold<int>(0, (s, r) => s + r));
    final fromCurrent = _currentLadderRungs.fold<int>(0, (s, r) => s + r);
    return fromCompleted + fromCurrent;
  }

  int get _peakRung {
    var peak = 0;
    for (final ladder in _completedLadders) {
      for (final r in ladder) {
        if (r > peak) peak = r;
      }
    }
    for (final r in _currentLadderRungs) {
      if (r > peak) peak = r;
    }
    return peak;
  }

  void _completeRung() {
    setState(() {
      _currentLadderRungs.add(_nextRung);
    });
  }

  void _undoRung() {
    if (_currentLadderRungs.isNotEmpty) {
      setState(() {
        _currentLadderRungs.removeLast();
      });
    }
  }

  void _finishCurrentLadder() {
    if (_currentLadderRungs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Complete at least one rung before finishing the ladder.')),
      );
      return;
    }

    setState(() {
      _completedLadders.add(List<int>.from(_currentLadderRungs));
      _currentLadderRungs.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Completed Ladder #${_completedLadders.length} (${_completedLadders.last.join("-")}). Take a short rest and start the next ladder!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetSession() {
    setState(() {
      _completedLadders.clear();
      _currentLadderRungs.clear();
    });
  }

  void _logSession() {
    final allLadders = List<List<int>>.from(_completedLadders);
    if (_currentLadderRungs.isNotEmpty) {
      allLadders.add(List<int>.from(_currentLadderRungs));
    }

    if (allLadders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Complete at least one ladder before logging to history.')),
      );
      return;
    }

    final totalReps = _totalReps;
    final peak = _peakRung;
    final optional = trainingState.selectedDailyOptionalExercises.isEmpty
        ? 'None selected'
        : trainingState.selectedDailyOptionalExercises.join(', ');

    final ladderBreakdown = allLadders
        .asMap()
        .entries
        .map((e) =>
            'Ladder ${e.key + 1}: ${e.value.join("-")} (${e.value.fold<int>(0, (s, r) => s + r)} reps)')
        .join('\n');

    final isPushUp = _selectedExercise == 'Push-ups';
    final pushUps = isPushUp ? totalReps : 0;
    final chinUps = isPushUp ? 0 : totalReps;

    final details =
        'Exercise: $_selectedExercise${_usedNegatives ? ' (negatives used)' : ''}\n'
        'Total Reps: $totalReps\n'
        'Ladders completed: ${allLadders.length}\n'
        'Peak Rung: $peak\n'
        'Optional: $optional\n\n'
        'Ladders Breakdown:\n$ladderBreakdown';

    trainingState.logDailyMethodSession(
      method: DailyMethod.ladder,
      pushUps: pushUps,
      chinUps: chinUps,
      usedNegatives: _usedNegatives,
      optionalExerciseSummary: optional,
      title: 'Ladder Method Session ($_selectedExercise)',
      customDetails: details,
      metadata: {
        'exercise': _selectedExercise,
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
          'Saved $totalReps reps of $_selectedExercise across ${allLadders.length} ladder(s) (Peak rung: $peak).\n\n'
          'Would you like to clear this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Numbers'),
          ),
          ElevatedButton(
            onPressed: () {
              _resetSession();
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
        final currentLadderNum = _completedLadders.length + 1;

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
                        'Perform ascending rep rungs (1, 2, 3...) per wave with brief rests to accumulate volume.',
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

            // Exercise Selection
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
                            value: 'Push-ups', label: Text('Push-ups')),
                        ButtonSegment(
                            value: 'Chin-ups', label: Text('Chin-ups')),
                      ],
                      selected: {_selectedExercise},
                      onSelectionChanged: (set) {
                        setState(() {
                          _selectedExercise = set.first;
                        });
                      },
                    ),
                    if (_selectedExercise == 'Chin-ups') ...[
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Used negatives instead of full chin-ups'),
                        value: _usedNegatives,
                        onChanged: (val) =>
                            setState(() => _usedNegatives = val),
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
                    _StatColumn(label: 'Total Reps', value: '$_totalReps'),
                    _StatColumn(
                      label: 'Ladders',
                      value:
                          '${_completedLadders.length + (_currentLadderRungs.isNotEmpty ? 1 : 0)}',
                    ),
                    _StatColumn(label: 'Peak Rung', value: '$_peakRung'),
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
                        if (_currentLadderRungs.isNotEmpty)
                          TextButton.icon(
                            onPressed: _undoRung,
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('Undo Rung'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentLadderRungs.isEmpty
                          ? 'Starting fresh ladder. First rung is 1 rep.'
                          : 'Rungs completed: ${_currentLadderRungs.join(" → ")} (${_currentLadderRungs.fold<int>(0, (s, r) => s + r)} reps)',
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
                                'Hit Rung $_nextRung ($_nextRung rep${_nextRung == 1 ? '' : 's'})'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _currentLadderRungs.isEmpty
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
            if (_completedLadders.isNotEmpty) ...[
              const Text('Completed Ladders:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ..._completedLadders.asMap().entries.map((entry) {
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
                    subtitle:
                        Text('Ladder volume: $reps reps (Peak: ${rungs.last})'),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _completedLadders.removeAt(idx);
                        });
                      },
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
              onPressed:
                  (_completedLadders.isEmpty && _currentLadderRungs.isEmpty)
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
