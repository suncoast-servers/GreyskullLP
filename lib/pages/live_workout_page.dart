import 'package:flutter/material.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';

/// Fullscreen live workout shell (issue #80).
class LiveWorkoutPage extends StatelessWidget {
  const LiveWorkoutPage({super.key});

  Future<bool> _confirmEnd(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End workout?'),
        content: const Text(
            'Leaving now stops the session. Logged sets are kept in the workout page until you finish.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep training'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End workout'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmEnd(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Live Workout'),
          leading: IconButton(
            tooltip: 'End workout',
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmEnd(context) && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: const WorkoutPageWeight(liveMode: true),
      ),
    );
  }
}
