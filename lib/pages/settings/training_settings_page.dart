import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/settings_common.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';

/// Program level, daily method, targets, nutrition and barbell template.
class TrainingSettingsPage extends StatelessWidget {
  const TrainingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const SettingsSectionTitle(
                'Program Level & Progression',
                description:
                    'Johnny Pain progressive UX: start simple with the base barbell program and frequency method, then graduate to accessories and higher density methods.',
              ),
              ...ProgramLevel.values.map((level) {
                final selected = trainingState.programLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GsCard(
                    onTap: () => trainingState.setProgramLevel(level),
                    borderColor: selected ? tokens.accent : tokens.line,
                    color:
                        selected ? tokens.accent.withValues(alpha: 0.05) : null,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: selected ? tokens.accent : tokens.muted,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      level.shortLabel,
                                      style: TextStyle(
                                        fontFamily: GsFont.body,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.bone,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  GsTag(
                                    level.badge,
                                    tone: selected
                                        ? GsTagTone.accent
                                        : GsTagTone.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                level.subtitle,
                                style: TextStyle(
                                  fontFamily: GsFont.body,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.bone,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                level.description,
                                style: TextStyle(
                                  fontFamily: GsFont.body,
                                  fontSize: 11,
                                  height: 1.45,
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Row(
                children: <Widget>[
                  Icon(Icons.shield_outlined, size: 15, color: tokens.ok),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Zero data loss: changing your level changes UI complexity without deleting or modifying any prior workout history or PRs.',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 10.5,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: tokens.ok,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  trainingState.resetOnboarding();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Starter onboarding reset. Switch to Workout tab to view starter onboarding.'),
                    ),
                  );
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset Starter Onboarding Prompt'),
              ),
              const SettingsSectionTitle('Preferred Daily Method'),
              SegmentedButton<DailyMethod>(
                segments: DailyMethod.values
                    .map(
                      (method) => ButtonSegment<DailyMethod>(
                        value: method,
                        label: Text(TrainingState.methodLabel(method)),
                      ),
                    )
                    .toList(),
                selected: <DailyMethod>{trainingState.activeDailyMethod},
                onSelectionChanged: (selection) {
                  trainingState.setActiveDailyMethod(selection.first);
                },
              ),
              const SettingsSectionTitle('Daily Repetition Targets'),
              GsCard(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  children: <Widget>[
                    SettingsTargetAdjuster(
                      label: 'Push-ups',
                      value: trainingState.dailyPushUpTarget,
                      onDecrease: () => trainingState.setDailyPushUpTarget(
                          trainingState.dailyPushUpTarget - 5),
                      onIncrease: () => trainingState.setDailyPushUpTarget(
                          trainingState.dailyPushUpTarget + 5),
                      unit: 'reps',
                    ),
                    SettingsTargetAdjuster(
                      label: 'Chin-ups / negatives',
                      value: trainingState.dailyChinUpTarget,
                      onDecrease: () => trainingState.setDailyChinUpTarget(
                          trainingState.dailyChinUpTarget - 1),
                      onIncrease: () => trainingState.setDailyChinUpTarget(
                          trainingState.dailyChinUpTarget + 1),
                      unit: 'reps',
                    ),
                    SettingsTargetAdjuster(
                      label: 'Daily protein target',
                      value: trainingState.dailyProteinTarget,
                      onDecrease: () => trainingState.setDailyProteinTarget(
                          trainingState.dailyProteinTarget - 5),
                      onIncrease: () => trainingState.setDailyProteinTarget(
                          trainingState.dailyProteinTarget + 5),
                      unit: 'g',
                    ),
                    SettingsTargetAdjuster(
                      label: 'Daily calorie target',
                      value: trainingState.dailyCalorieTarget,
                      onDecrease: () => trainingState.setDailyCalorieTarget(
                          trainingState.dailyCalorieTarget - 50),
                      onIncrease: () => trainingState.setDailyCalorieTarget(
                          trainingState.dailyCalorieTarget + 50),
                      unit: 'kcal',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<NutritionMode>(
                segments: NutritionMode.values
                    .map(
                      (mode) => ButtonSegment<NutritionMode>(
                        value: mode,
                        label: Text(TrainingState.nutritionModeLabel(mode)),
                      ),
                    )
                    .toList(),
                selected: <NutritionMode>{trainingState.nutritionMode},
                onSelectionChanged: (selection) {
                  trainingState.setNutritionMode(selection.first);
                },
              ),
              const SettingsSectionTitle(
                'Barbell Program Template',
                description:
                    'Official Greyskull LP progression structures (Johnny Pain 3rd Edition):',
              ),
              DropdownButtonFormField<BarbellTemplate>(
                key: ValueKey(trainingState.activeBarbellTemplate),
                initialValue: trainingState.activeBarbellTemplate,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: BarbellTemplate.values.map((template) {
                  final details = trainingState.getTemplateDetails(template);
                  return DropdownMenuItem<BarbellTemplate>(
                    value: template,
                    child: Text(
                      details.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (template) {
                  if (template != null) {
                    trainingState.setBarbellTemplate(template);
                  }
                },
              ),
              const SettingsSectionTitle(
                'Weight Program Optional Exercises',
                description:
                    'Check any plug-ins you want available on weight sessions.',
              ),
              GsCard(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: TrainingState.weightOptionalExerciseOptions
                      .map(
                        (exercise) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(exercise),
                          value: trainingState.selectedWeightOptionalExercises
                              .contains(exercise),
                          onChanged: (_) => trainingState
                              .toggleWeightOptionalExercise(exercise),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
