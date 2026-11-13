import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// One coach-mark step.
class TutorialStep {
  const TutorialStep({required this.title, required this.body, this.icon});

  final String title;
  final String body;
  final IconData? icon;
}

/// Section tutorials (issue #83). Each section shows its steps once; the
/// completion flag is persisted so it never nags again unless replayed from
/// Settings. Copy is text-first, never colour-only.
class Tutorials {
  const Tutorials._();

  static const Map<String, List<TutorialStep>> steps = {
    'weight_setup': [
      TutorialStep(
        title: 'Pick your program',
        body:
            'Choose OG Base, Villain, Gladiator, a split, or Custom. The cards stay in plain language — no book jargon.',
        icon: Icons.list_alt,
      ),
      TutorialStep(
        title: 'Tune the timing',
        body:
            'Set rest between sets, the bell, and whether the screen stays awake. Everything is optional.',
        icon: Icons.timer_outlined,
      ),
      TutorialStep(
        title: 'Start Workout',
        body:
            'One button opens the focused live session. Back or the X always asks before ending.',
        icon: Icons.play_arrow,
      ),
    ],
    'live_workout': [
      TutorialStep(
        title: '5 · 5 · 5+',
        body:
            'Tap a circle when the set is done. The third set is AMRAP — go past five if you can.',
        icon: Icons.radio_button_checked,
      ),
      TutorialStep(
        title: 'Missed a rep count?',
        body:
            'Press and hold a circle to enter the actual reps for that set. The log keeps the detail.',
        icon: Icons.touch_app,
      ),
      TutorialStep(
        title: 'Beat 10 on AMRAP',
        body:
            'Ten or more reps on the AMRAP set adds weight next time: +5 lb upper body, +10 lb lower body.',
        icon: Icons.trending_up,
      ),
    ],
    'frequency': [
      TutorialStep(
        title: 'Sub-maximal sets',
        body:
            'Log short sets through the day and stay well shy of failure. Targets live in the volume card.',
        icon: Icons.repeat,
      ),
      TutorialStep(
        title: 'Accessories',
        body:
            'Dips, planks and friends are configured in Settings and logged inline. Planks count seconds.',
        icon: Icons.checklist,
      ),
      TutorialStep(
        title: 'Save the day',
        body:
            'Log today to history when you are done; unfinished sets auto-save if the day rolls over.',
        icon: Icons.save,
      ),
    ],
    'ladder': [
      TutorialStep(
        title: 'Climb the rungs',
        body:
            'Hit rung 1, 2, 3… then finish the ladder. Rest as needed between rungs.',
        icon: Icons.trending_up,
      ),
      TutorialStep(
        title: 'Volume, not grind',
        body:
            'Total reps and peak rung matter more than single-set failure. The app keeps both.',
        icon: Icons.insights,
      ),
    ],
    'total_work': [
      TutorialStep(
        title: 'Density work',
        body:
            'Pick a daily or weekly rep target and chip away in manageable sets.',
        icon: Icons.balance,
      ),
      TutorialStep(
        title: 'Track the target',
        body:
            'The progress bar and remaining-reps line show exactly how much is left.',
        icon: Icons.stacked_line_chart,
      ),
    ],
  };

  static List<TutorialStep> forSection(String section) =>
      steps[section] ?? const [];

  /// Tests and headless runs must not pop dialogs; a test can force it on.
  @visibleForTesting
  static bool? debugForcedEnabled;

  static bool get enabled {
    if (debugForcedEnabled != null) return debugForcedEnabled!;
    if (kIsWeb) return true;
    try {
      return Platform.environment['FLUTTER_TEST'] != 'true';
    } catch (_) {
      return true;
    }
  }

  /// Shows the tutorial for [section] the first time it is opened.
  static Future<void> showIfNeeded(BuildContext context, String section) async {
    if (!enabled) return;
    if (trainingState.hasSeenTutorial(section)) return;
    final content = forSection(section);
    if (content.isEmpty) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TutorialDialog(section: section, steps: content),
    );
  }
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog({required this.section, required this.steps});

  final String section;
  final List<TutorialStep> steps;

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _index = 0;

  void _finish() {
    trainingState.markTutorialSeen(widget.section);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    return AlertDialog(
      title: Row(
        children: [
          Icon(step.icon ?? Icons.info_outline,
              size: 20, color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(step.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.body, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 14),
          Text(
            '${_index + 1} of ${widget.steps.length}',
            style: TextStyle(fontSize: 11, color: AppTheme.mutedText(context)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _finish,
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isLast) {
              _finish();
            } else {
              setState(() => _index += 1);
            }
          },
          child: Text(isLast ? 'Done' : 'Next'),
        ),
      ],
    );
  }
}
