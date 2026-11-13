import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/program/template_labels.dart';
import 'package:greyskull_lp/pages/live_workout_page.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/widgets/custom_program_editor_sheet.dart';
import 'package:greyskull_lp/widgets/tutorial_overlay.dart';

/// Workout **setup** surface (issue #79).
///
/// Keep this screen about choosing how to train: pick a program, customise it,
/// tune timing. The live session lives in [WorkoutPageWeight] behind
/// "Start Workout".
class WorkoutSetupPage extends StatefulWidget {
  const WorkoutSetupPage({super.key});

  @override
  State<WorkoutSetupPage> createState() => _WorkoutSetupPageState();
}

class _WorkoutSetupPageState extends State<WorkoutSetupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Tutorials.showIfNeeded(context, 'weight_setup');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Setup')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          final active = trainingState.activeBarbellTemplate;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose your program',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick one, tune the timing, then start the session.',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
              ),
              const SizedBox(height: 12),
              ...BarbellTemplate.values.map((template) {
                final selected = template == active;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => trainingState.setBarbellTemplate(template),
                    title: Text(
                      TemplateLabels.nameFor(template),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(TemplateLabels.lineFor(template)),
                    trailing: selected
                        ? Icon(Icons.check_circle,
                            color: AppTheme.positiveAccent(context))
                        : const Icon(Icons.radio_button_unchecked, size: 20),
                  ),
                );
              }),
              if (trainingState.isCustomTemplateActive) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('setup_customize_btn'),
                      onPressed: () => CustomProgramEditorSheet.show(context),
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Edit custom program'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('setup_duplicate_btn'),
                      onPressed: () => _duplicateFromPreset(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Start from a preset'),
                    ),
                    if (trainingState.isCustomTemplateModified)
                      OutlinedButton.icon(
                        key: const Key('setup_revert_btn'),
                        onPressed: () {
                          trainingState.resetCustomTemplateToDefault();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Custom program reset')),
                          );
                        },
                        icon: Icon(Icons.restore,
                            size: 16,
                            color: Theme.of(context).colorScheme.error),
                        label: Text('Reset custom',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Timing',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Expanded(child: Text('Rest between sets')),
                          DropdownButton<int>(
                            value: trainingState.restTimerSeconds,
                            items: TrainingState.restTimerPresets
                                .map((s) => DropdownMenuItem<int>(
                                    value: s, child: Text('$s s')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                trainingState.setRestTimerSeconds(v);
                              }
                            },
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Rest timer'),
                        value: trainingState.restTimerEnabled,
                        onChanged: (v) => trainingState.setRestTimerEnabled(v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bell and vibration'),
                        value: trainingState.restTimerSoundEnabled,
                        onChanged: (v) =>
                            trainingState.setRestTimerSoundEnabled(v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('start_workout_btn'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveWorkoutPage()),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Start Workout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  void _duplicateFromPreset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Start custom from a preset'),
        children: TrainingState.officialBookTemplates.map((template) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(ctx).pop();
              trainingState.duplicateTemplateFromPreset(template);
            },
            child: Text(TemplateLabels.nameFor(template)),
          );
        }).toList(),
      ),
    );
  }
}
