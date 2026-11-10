import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class WorkoutPageWeight extends StatefulWidget {
  const WorkoutPageWeight({super.key});

  @override
  State<WorkoutPageWeight> createState() => _WorkoutPageWeightState();
}

class _WorkoutPageWeightState extends State<WorkoutPageWeight> {
  final Set<String> _completedCoreLifts = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _benchWeightController = TextEditingController();
  final TextEditingController _benchRepsController = TextEditingController();
  final TextEditingController _squatWeightController = TextEditingController();
  final TextEditingController _squatRepsController = TextEditingController();
  final TextEditingController _ohpWeightController = TextEditingController();
  final TextEditingController _ohpRepsController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _benchWeightController.dispose();
    _benchRepsController.dispose();
    _squatWeightController.dispose();
    _squatRepsController.dispose();
    _ohpWeightController.dispose();
    _ohpRepsController.dispose();
    super.dispose();
  }

  double _fieldDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  void _logSession() {
    final coreSummary = _completedCoreLifts.isEmpty
        ? 'No core lifts marked complete'
        : _completedCoreLifts.join(', ');
    final optionalSummary =
        trainingState.selectedWeightOptionalExercises.isEmpty
            ? 'None selected'
            : trainingState.selectedWeightOptionalExercises.join(', ');
    final benchVolume = _fieldDouble(_benchWeightController) *
        _fieldDouble(_benchRepsController);
    final squatVolume = _fieldDouble(_squatWeightController) *
        _fieldDouble(_squatRepsController);
    final ohpVolume =
        _fieldDouble(_ohpWeightController) * _fieldDouble(_ohpRepsController);
    final totalVolume = benchVolume + squatVolume + ohpVolume;

    trainingState.logWeightSession(
      coreLiftSummary: coreSummary,
      optionalExerciseSummary: optionalSummary,
      volume: totalVolume,
      notes: _notesController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weight workout logged to history')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Greyskull LP Weight Program',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Base lifts: Bench Press, Squat, Overhead Press',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Weekly Schedule',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Mon: Workout A (Squat, Bench Press, Chin-up work)'),
                    Text(
                        'Wed: Workout B (Squat, Overhead Press, Push-up work)'),
                    Text('Fri: Workout A, then alternate next week (B/A/B)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mark Core Lifts Completed Today',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bench Press'),
              value: _completedCoreLifts.contains('Bench Press'),
              onChanged: (_) => setState(() {
                if (_completedCoreLifts.contains('Bench Press')) {
                  _completedCoreLifts.remove('Bench Press');
                } else {
                  _completedCoreLifts.add('Bench Press');
                }
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Squat'),
              value: _completedCoreLifts.contains('Squat'),
              onChanged: (_) => setState(() {
                if (_completedCoreLifts.contains('Squat')) {
                  _completedCoreLifts.remove('Squat');
                } else {
                  _completedCoreLifts.add('Squat');
                }
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Overhead Press'),
              value: _completedCoreLifts.contains('Overhead Press'),
              onChanged: (_) => setState(() {
                if (_completedCoreLifts.contains('Overhead Press')) {
                  _completedCoreLifts.remove('Overhead Press');
                } else {
                  _completedCoreLifts.add('Overhead Press');
                }
              }),
            ),
            const SizedBox(height: 8),
            const Text(
              'Optional Exercises (set in Settings)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trainingState.selectedWeightOptionalExercises.isEmpty
                  ? [const Chip(label: Text('None selected yet'))]
                  : trainingState.selectedWeightOptionalExercises
                      .map((exercise) => Chip(label: Text(exercise)))
                      .toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Core Lift Tracking (weight x reps)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _LiftInputRow(
              label: 'Bench Press',
              weightController: _benchWeightController,
              repsController: _benchRepsController,
            ),
            _LiftInputRow(
              label: 'Squat',
              weightController: _squatWeightController,
              repsController: _squatRepsController,
            ),
            _LiftInputRow(
              label: 'Overhead Press',
              weightController: _ohpWeightController,
              repsController: _ohpRepsController,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Session Notes',
                hintText: 'How did today feel?',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _logSession,
              icon: const Icon(Icons.save),
              label: const Text('Log Today\'s Weight Session'),
            ),
          ],
        );
      },
    );
  }
}

class _LiftInputRow extends StatelessWidget {
  const _LiftInputRow({
    required this.label,
    required this.weightController,
    required this.repsController,
  });

  final String label;
  final TextEditingController weightController;
  final TextEditingController repsController;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
