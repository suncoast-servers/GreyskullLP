import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/services/screen_awake_service.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';
import 'package:greyskull_lp/widgets/tutorial_overlay.dart';

/// Fullscreen live workout shell (issue #80).
class LiveWorkoutPage extends StatefulWidget {
  const LiveWorkoutPage({super.key});

  @override
  State<LiveWorkoutPage> createState() => _LiveWorkoutPageState();
}

class _LiveWorkoutPageState extends State<LiveWorkoutPage> {
  Timer? _notificationTimer;
  int _elapsedSeconds = 0;

  void _publishNotification() {
    if (!trainingState.workoutNotifications) return;
    WorkoutNotificationService.instance.showLive(
      title: 'Workout in progress',
      body: 'Session ${_elapsedSeconds ~/ 60}:'
          '${(_elapsedSeconds % 60).toString().padLeft(2, '0')} — '
          'keep the app open to log sets.',
    );
  }

  @override
  void initState() {
    super.initState();
    // Keep the display on for the duration of the live session (#82).
    if (trainingState.keepScreenAwake) {
      ScreenAwakeService.setAwake(true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Tutorials.showIfNeeded(context, 'live_workout');
      }
    });
    if (trainingState.workoutNotifications) {
      WorkoutNotificationService.instance.requestPermission();
      _publishNotification();
      _notificationTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) {
          _elapsedSeconds += 15;
          _publishNotification();
        },
      );
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    WorkoutNotificationService.instance.cancelAll();
    ScreenAwakeService.setAwake(false);
    super.dispose();
  }

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
