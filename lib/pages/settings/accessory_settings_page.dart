import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/settings_common.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:greyskull_lp/widgets/calisthenics_accessories_section.dart';

/// Daily-method accessories and per-method calisthenics configuration.
class AccessorySettingsPage extends StatelessWidget {
  const AccessorySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Accessories')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const SettingsSectionTitle(
                'Daily Method Optional Exercises',
                description:
                    'Shown on the Frequency, Ladder and Total Work logging screens.',
              ),
              GsCard(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: TrainingState.dailyOptionalExerciseOptions
                      .map(
                        (exercise) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(exercise),
                          value: trainingState.selectedDailyOptionalExercises
                              .contains(exercise),
                          onChanged: (_) => trainingState
                              .toggleDailyOptionalExercise(exercise),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SettingsSectionTitle(
                'Calisthenics Accessories',
                description:
                    'Accessories shown on the Frequency, Ladder and Total Work screens.',
              ),
              GsCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    CalisthenicsAccessoriesSection(
                      method: DailyMethod.frequency,
                      completedAccessories: const <String>{},
                      onCompletedChanged: (_) {},
                      showCompletion: false,
                      title: 'Frequency Method',
                    ),
                    const Divider(height: 24),
                    CalisthenicsAccessoriesSection(
                      method: DailyMethod.ladder,
                      completedAccessories: const <String>{},
                      onCompletedChanged: (_) {},
                      showCompletion: false,
                      title: 'Ladder Method',
                    ),
                    const Divider(height: 24),
                    CalisthenicsAccessoriesSection(
                      method: DailyMethod.totalWork,
                      completedAccessories: const <String>{},
                      onCompletedChanged: (_) {},
                      showCompletion: false,
                      title: 'Total Work Method',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GsCard(
                color: tokens.surface2,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Tip: keeping 1–3 accessories per method matches the book’s plug-in guidance and keeps sessions focused.',
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
