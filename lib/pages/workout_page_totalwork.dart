import 'dart:async';
import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class WorkoutPageTotalWork extends StatefulWidget {
  const WorkoutPageTotalWork({super.key});

  @override
  State<WorkoutPageTotalWork> createState() => _WorkoutPageTotalWorkState();
}

class _WorkoutPageTotalWorkState extends State<WorkoutPageTotalWork> {
  String _selectedExercise = 'Push-ups';
  bool _usedNegatives = false;
  int _targetReps = 50;

  final List<int> _sets = [];
  int _repsThisSet = 15;

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _elapsedSeconds = 0;
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _totalRepsCompleted => _sets.fold<int>(0, (sum, r) => sum + r);

  int get _remainingReps =>
      (_targetReps - _totalRepsCompleted).clamp(0, _targetReps);

  void _addSet() {
    if (_repsThisSet <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least 1 rep for this set.')),
      );
      return;
    }

    setState(() {
      _sets.add(_repsThisSet);
      if (_remainingReps > 0 && _repsThisSet > _remainingReps) {
        _repsThisSet = _remainingReps;
      }
    });

    if (_totalRepsCompleted >= _targetReps && _isTimerRunning) {
      _pauseTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target reached! $_totalRepsCompleted / $_targetReps reps completed in ${_sets.length} sets (${_formatDuration(_elapsedSeconds)}).',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeSet(int index) {
    if (index >= 0 && index < _sets.length) {
      setState(() {
        _sets.removeAt(index);
      });
    }
  }

  void _resetSession() {
    setState(() {
      _sets.clear();
      _resetTimer();
    });
  }

  void _logSession() {
    if (_sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Log at least one set before saving to history.')),
      );
      return;
    }

    final totalReps = _totalRepsCompleted;
    final optional = trainingState.selectedDailyOptionalExercises.isEmpty
        ? 'None selected'
        : trainingState.selectedDailyOptionalExercises.join(', ');

    final setBreakdown = _sets
        .asMap()
        .entries
        .map((e) => 'Set ${e.key + 1}: ${e.value} reps')
        .join('\n');

    final isPushUp = _selectedExercise == 'Push-ups';
    final pushUps = isPushUp ? totalReps : 0;
    final chinUps = isPushUp ? 0 : totalReps;
    final durationStr = _formatDuration(_elapsedSeconds);

    final details =
        'Exercise: $_selectedExercise${_usedNegatives ? ' (negatives used)' : ''}\n'
        'Target: $_targetReps reps\n'
        'Completed: $totalReps reps in ${_sets.length} set${_sets.length == 1 ? '' : 's'}\n'
        'Time: $durationStr\n'
        'Optional: $optional\n\n'
        'Sets Breakdown:\n$setBreakdown';

    trainingState.logDailyMethodSession(
      method: DailyMethod.totalWork,
      pushUps: pushUps,
      chinUps: chinUps,
      usedNegatives: _usedNegatives,
      optionalExerciseSummary: optional,
      title: 'Total Work Method Session ($_selectedExercise)',
      customDetails: details,
      metadata: {
        'exercise': _selectedExercise,
        'targetReps': _targetReps,
        'totalReps': totalReps,
        'setsCount': _sets.length,
        'durationSeconds': _elapsedSeconds,
        'durationFormatted': durationStr,
        'sets': _sets,
      },
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Total Work Session Saved'),
        content: Text(
          'Saved $totalReps reps of $_selectedExercise in ${_sets.length} sets ($durationStr).\n\n'
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
        final isActive =
            trainingState.activeDailyMethod == DailyMethod.totalWork;
        final completed = _totalRepsCompleted;
        final progress =
            _targetReps > 0 ? (completed / _targetReps).clamp(0.0, 1.0) : 0.0;
        final percent = (progress * 100).toInt();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Work Method',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Complete a designated total volume in as few sets as possible (or against the clock).',
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
                    trainingState.setActiveDailyMethod(DailyMethod.totalWork),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Set as Active Method'),
              ),
            const SizedBox(height: 12),

            // Exercise & Target Configuration
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
                      onSelectionChanged: (set) =>
                          setState(() => _selectedExercise = set.first),
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
                    const Divider(height: 24),
                    const Text('Target Volume (reps):',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [25, 50, 75, 100].map((reps) {
                        final isSelected = _targetReps == reps;
                        return ChoiceChip(
                          label: Text('$reps reps'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _targetReps = reps),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stopwatch / Session Timer
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Session Time',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _formatDuration(_elapsedSeconds),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isTimerRunning
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill),
                      iconSize: 36,
                      onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetTimer,
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
                        Text('$completed / $_targetReps reps ($percent%)'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sets completed: ${_sets.length}',
                            style: const TextStyle(fontSize: 13)),
                        Text(
                          _remainingReps == 0
                              ? 'Target achieved!'
                              : '$_remainingReps reps remaining',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _remainingReps == 0
                                ? Colors.green
                                : Colors.grey[700],
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
                      'Log Set #${_sets.length + 1}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet - 5).clamp(1, 100)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet - 1).clamp(1, 100)),
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
                              _repsThisSet = (_repsThisSet + 1).clamp(1, 100)),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          onPressed: () => setState(() =>
                              _repsThisSet = (_repsThisSet + 5).clamp(1, 100)),
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
            if (_sets.isNotEmpty) ...[
              const Text('Sets Completed:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ..._sets.asMap().entries.map((entry) {
                final idx = entry.key;
                final reps = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Text('#${idx + 1}'),
                    ),
                    title: Text('Set ${idx + 1}: $reps reps'),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _removeSet(idx),
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
              onPressed: _sets.isEmpty ? null : _logSession,
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
