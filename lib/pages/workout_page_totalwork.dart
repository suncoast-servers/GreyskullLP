import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';

class WorkoutPageTotalWork extends StatefulWidget {
  const WorkoutPageTotalWork({super.key});

  @override
  State<WorkoutPageTotalWork> createState() => _WorkoutPageTotalWorkState();
}

class _WorkoutPageTotalWorkState extends State<WorkoutPageTotalWork> {
  int _pushUpsDone = 0;
  int _chinUpsDone = 0;
  bool _usedNegatives = false;

  void _logSession() {
    final optional = trainingState.selectedDailyOptionalExercises.isEmpty
        ? 'None selected'
        : trainingState.selectedDailyOptionalExercises.join(', ');

    trainingState.logDailyMethodSession(
      method: DailyMethod.totalWork,
      pushUps: _pushUpsDone,
      chinUps: _chinUpsDone,
      usedNegatives: _usedNegatives,
      optionalExerciseSummary: optional,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Total Work session logged to history')),
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
            const Text('Total Work Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Daily base: push-ups + chin-ups/negatives'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => trainingState.setActiveDailyMethod(DailyMethod.totalWork),
              child: Text(
                trainingState.activeDailyMethod == DailyMethod.totalWork
                    ? 'Currently Active Method'
                    : 'Use Total Work Method',
              ),
            ),
            const SizedBox(height: 12),
            _CounterCard(
              label: 'Push-ups done',
              target: trainingState.dailyPushUpTarget,
              value: _pushUpsDone,
              onDecrease: () => setState(() => _pushUpsDone = (_pushUpsDone - 5).clamp(0, 500)),
              onIncrease: () => setState(() => _pushUpsDone = (_pushUpsDone + 5).clamp(0, 500)),
            ),
            _CounterCard(
              label: 'Chin-ups / negatives done',
              target: trainingState.dailyChinUpTarget,
              value: _chinUpsDone,
              onDecrease: () => setState(() => _chinUpsDone = (_chinUpsDone - 1).clamp(0, 250)),
              onIncrease: () => setState(() => _chinUpsDone = (_chinUpsDone + 1).clamp(0, 250)),
            ),
            SwitchListTile(
              title: const Text('Used negatives instead of full chin-ups'),
              value: _usedNegatives,
              onChanged: (value) => setState(() => _usedNegatives = value),
            ),
            const SizedBox(height: 8),
            const Text('Optional add-ons (from Settings):'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trainingState.selectedDailyOptionalExercises.isEmpty
                  ? [const Chip(label: Text('None selected yet'))]
                  : trainingState.selectedDailyOptionalExercises
                      .map((exercise) => Chip(label: Text(exercise)))
                      .toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _logSession,
              icon: const Icon(Icons.save),
              label: const Text('Log Today\'s Total Work Session'),
            ),
          ],
        );
      },
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.target,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int target;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text('$label: $value / target $target')),
            IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove)),
            IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
          ],
        ),
      ),
    );
  }
}
