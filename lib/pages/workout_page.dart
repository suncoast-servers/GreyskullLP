import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'workout_page_weight.dart';
import 'workout_page_frequency.dart';
import 'workout_page_ladder.dart';
import 'workout_page_totalwork.dart';

class WorkoutPage extends StatefulWidget {
  final ValueNotifier<String> titleNotifier; // Notifier for app bar title

  const WorkoutPage({super.key, required this.titleNotifier});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  Widget? _currentPage;

  void _openSubPage(Widget page, String title) {
    setState(() {
      _currentPage = page;
    });
    widget.titleNotifier.value = title;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentPage = null;
                });
                widget.titleNotifier.value = 'Workout';
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to workout menu'),
            ),
          ),
          Expanded(child: _currentPage!),
        ],
      );
    }
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) => _buildWorkoutMainPage(),
    );
  }

  Widget _buildWorkoutMainPage() {
    widget.titleNotifier.value = "Workout";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWorkoutButton(
                  IconData(0xf6e6, fontFamily: 'MaterialSymbols'),
                  'Weight Program',
                  const WorkoutPageWeight()),
              _buildWorkoutButton(
                Icons.repeat,
                'Frequency Method',
                const WorkoutPageFrequency(),
                isActive:
                    trainingState.activeDailyMethod == DailyMethod.frequency,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWorkoutButton(
                Icons.trending_up,
                'Ladder Method',
                const WorkoutPageLadder(),
                isActive: trainingState.activeDailyMethod == DailyMethod.ladder,
              ),
              _buildWorkoutButton(
                Icons.balance,
                'Total Work Method',
                const WorkoutPageTotalWork(),
                isActive:
                    trainingState.activeDailyMethod == DailyMethod.totalWork,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutButton(
    IconData icon,
    String label,
    Widget page, {
    bool isActive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openSubPage(page, label),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 50),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 16)),
            if (isActive)
              const Text(
                'Active',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
