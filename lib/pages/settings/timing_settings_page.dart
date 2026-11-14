import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/settings_common.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';

/// Rest timer, live notifications, screen-awake and calisthenics reminders.
class TimingSettingsPage extends StatelessWidget {
  const TimingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Timing & Alerts')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const SettingsSectionTitle(
                'Workout Timing',
                description: 'Countdown between sets during barbell sessions.',
              ),
              GsCard(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rest timer between sets'),
                      subtitle: const Text(
                        'Starts automatically when a set is marked complete.',
                      ),
                      value: trainingState.restTimerEnabled,
                      onChanged: (value) =>
                          trainingState.setRestTimerEnabled(value),
                    ),
                    if (trainingState.restTimerEnabled) ...<Widget>[
                      DropdownButtonFormField<int>(
                        key: ValueKey(trainingState.restTimerSeconds),
                        initialValue: trainingState.restTimerSeconds,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Default rest',
                        ),
                        items: TrainingState.restTimerPresets
                            .map(
                              (seconds) => DropdownMenuItem<int>(
                                value: seconds,
                                child: Text('$seconds seconds'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            trainingState.setRestTimerSeconds(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bell and vibration when rest ends'),
                        value: trainingState.restTimerSoundEnabled,
                        onChanged: (value) =>
                            trainingState.setRestTimerSoundEnabled(value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Count up instead of down'),
                        subtitle: const Text(
                          'Matches the classic arc timer: elapsed rest time.',
                        ),
                        value: trainingState.restTimerCountUp,
                        onChanged: (value) =>
                            trainingState.setRestTimerCountUp(value),
                      ),
                      DropdownButtonFormField<int>(
                        key: ValueKey('size-${trainingState.restTimerSize}'),
                        initialValue: trainingState.restTimerSize,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Timer size',
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(value: 1, child: Text('Small')),
                          DropdownMenuItem(value: 2, child: Text('Medium')),
                          DropdownMenuItem(value: 3, child: Text('Large')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            trainingState.setRestTimerSize(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                            'after-${trainingState.restAfterExerciseSeconds}'),
                        initialValue: trainingState.restAfterExerciseSeconds,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Rest after finishing a lift',
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Same as the lift rest'),
                          ),
                          DropdownMenuItem(
                              value: 30, child: Text('30 seconds')),
                          DropdownMenuItem(
                              value: 60, child: Text('60 seconds')),
                          DropdownMenuItem(
                              value: 90, child: Text('90 seconds')),
                          DropdownMenuItem(
                              value: 120, child: Text('120 seconds')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            trainingState.setRestAfterExerciseSeconds(value);
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Live workout notifications'),
                      subtitle: const Text(
                        'Ongoing session notification and rest-complete alerts.',
                      ),
                      value: trainingState.workoutNotifications,
                      onChanged: (value) =>
                          trainingState.setWorkoutNotifications(value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Keep screen awake in a live workout'),
                      subtitle: const Text(
                        'Prevents the display sleeping while a session is open.',
                      ),
                      value: trainingState.keepScreenAwake,
                      onChanged: (value) =>
                          trainingState.setKeepScreenAwake(value),
                    ),
                  ],
                ),
              ),
              const SettingsSectionTitle('Calisthenics Reminders'),
              GsCard(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Calisthenics set reminders'),
                      subtitle: const Text(
                        'Notify me when no next set is logged within the window below.',
                      ),
                      value: trainingState.calisthenicsReminders,
                      onChanged: (value) {
                        trainingState.setCalisthenicsReminders(value);
                        if (value) {
                          WorkoutNotificationService.instance
                              .requestPermission();
                        }
                      },
                    ),
                    if (trainingState.calisthenicsReminders)
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                            'reminder-${trainingState.calisthenicsReminderMinutes}'),
                        initialValue: trainingState.calisthenicsReminderMinutes,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Remind me after',
                        ),
                        items: TrainingState.calisthenicsReminderPresets
                            .map(
                              (minutes) => DropdownMenuItem<int>(
                                value: minutes,
                                child: Text('$minutes minutes'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            trainingState.setCalisthenicsReminderMinutes(value);
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GsCard(
                color: tokens.surface2,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Reminders and the ongoing notification are local to this device. '
                  'They can be disabled at any time without affecting your logs.',
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11,
                    height: 1.45,
                    color: tokens.muted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
