import 'package:flutter/material.dart';
import 'package:greyskull_lp/ui/gs_dialog.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/program/template_labels.dart';
import 'package:greyskull_lp/pages/live_workout_page.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
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
    final tokens = context.gs;
    return Scaffold(
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          final active = trainingState.activeBarbellTemplate;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Text(
                'Choose your program',
                style: TextStyle(
                  fontFamily: GsFont.display,
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: tokens.bone,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick one, tune the timing, then start the session.',
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 11.5,
                  height: 1.4,
                  color: tokens.muted,
                ),
              ),
              const SizedBox(height: 12),
              ...BarbellTemplate.values.map(
                (template) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _buildTemplateCard(template, active),
                ),
              ),
              if (trainingState.isCustomTemplateActive) ...<Widget>[
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ElevatedButton.icon(
                      key: const Key('setup_customize_btn'),
                      onPressed: () => CustomProgramEditorSheet.show(context),
                      icon: const GsIcon('edit', size: 15),
                      label: const Text('Edit custom program'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('setup_duplicate_btn'),
                      onPressed: () => _duplicateFromPreset(context),
                      icon: const GsIcon('copy', size: 15),
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
                        icon: GsIcon(
                          'back',
                          size: 15,
                          color: tokens.danger,
                        ),
                        label: Text(
                          'Reset custom',
                          style: TextStyle(color: tokens.danger),
                        ),
                      ),
                  ],
                ),
              ],
              const GsSectionTitle('Timing'),
              GsCard(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Column(
                  children: <Widget>[
                    _timingRow(
                      label: 'Rest between sets',
                      child: DropdownButton<int>(
                        value: trainingState.restTimerSeconds,
                        dropdownColor: tokens.surface2,
                        underline: const SizedBox.shrink(),
                        items: TrainingState.restTimerPresets
                            .map((seconds) => DropdownMenuItem<int>(
                                  value: seconds,
                                  child: Text('$seconds s'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            trainingState.setRestTimerSeconds(value);
                          }
                        },
                      ),
                    ),
                    _timingRow(
                      label: 'Rest after last set',
                      child: DropdownButton<int>(
                        value: trainingState.restAfterExerciseSeconds,
                        dropdownColor: tokens.surface2,
                        underline: const SizedBox.shrink(),
                        items: const <int>[0, 60, 90, 120, 180]
                            .map((seconds) => DropdownMenuItem<int>(
                                  value: seconds,
                                  child: Text(
                                    seconds == 0
                                        ? 'Same as sets'
                                        : '$seconds s',
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            trainingState.setRestAfterExerciseSeconds(value);
                          }
                        },
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rest timer'),
                      value: trainingState.restTimerEnabled,
                      onChanged: (value) =>
                          trainingState.setRestTimerEnabled(value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bell and vibration'),
                      value: trainingState.restTimerSoundEnabled,
                      onChanged: (value) =>
                          trainingState.setRestTimerSoundEnabled(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GsPrimaryButton(
                key: const Key('start_workout_btn'),
                label: 'Start Workout',
                svgIcon: 'play',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LiveWorkoutPage(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(BarbellTemplate template, BarbellTemplate active) {
    final tokens = context.gs;
    final selected = template == active;
    final details = trainingState.getTemplateDetails(template);
    final allLifts = details.workouts
        .expand((workout) => workout.coreLifts)
        .map((lift) => lift.name)
        .toSet()
        .toList();
    final liftNames =
        allLifts.length <= 3 ? allLifts : allLifts.sublist(allLifts.length - 3);

    return GsCard(
      onTap: () => trainingState.setBarbellTemplate(template),
      borderColor:
          selected ? tokens.accent : tokens.line.withValues(alpha: 0.8),
      color: selected ? tokens.accent.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GsIconTile.svg(
            _iconForTemplate(template),
            size: 38,
            color: selected ? tokens.accent : tokens.muted,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        TemplateLabels.nameFor(template),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: GsFont.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.bone,
                        ),
                      ),
                    ),
                    if (selected)
                      GsIcon('check', size: 16, color: tokens.accent)
                    else
                      GsIcon('chevron', size: 15, color: tokens.muted),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  TemplateLabels.lineFor(template),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11,
                    height: 1.4,
                    color: tokens.muted,
                  ),
                ),
                if (liftNames.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: liftNames.map((name) => GsTag(name)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GsFont.body,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.gs.bone,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  String _iconForTemplate(BarbellTemplate template) {
    switch (template) {
      case BarbellTemplate.ogBase:
        return 'train';
      case BarbellTemplate.villain:
        return 'db';
      case BarbellTemplate.gladiator:
        return 'crown';
      case BarbellTemplate.twoDaySplit:
        return 'layers';
      case BarbellTemplate.fourDaySplit:
        return 'layers';
      case BarbellTemplate.custom:
        return 'edit';
    }
  }

  void _duplicateFromPreset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => GsSimpleDialog(
        title: const Text('Start custom from a preset'),
        children: TrainingState.officialBookTemplates.map((template) {
          return GsDialogOption(
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
