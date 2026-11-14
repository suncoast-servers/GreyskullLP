import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/settings_common.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';

/// Tutorial replay and quick guidance.
class HelpSettingsPage extends StatelessWidget {
  const HelpSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Tutorials')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          const SettingsSectionTitle(
            'Guided Tours',
            description:
                'Each section explains itself the first time you open it.',
          ),
          GsCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    GsIcon('book', size: 18, color: tokens.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Section tutorials',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.bone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Weight setup, live workouts, Frequency, Ladder and Total Work each have a short first-run walkthrough.',
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11.5,
                    height: 1.5,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    trainingState.replayTutorials();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Tutorials reset — they show again on each screen.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_outlined, size: 16),
                  label: const Text('Replay section tutorials'),
                ),
              ],
            ),
          ),
          const SettingsSectionTitle('Onboarding'),
          GsCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    GsIcon('skull', size: 18, color: tokens.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Starter prompt',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.bone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'The first-run prompt asks which program level to start on. Resetting it does not touch any history or PRs.',
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11.5,
                    height: 1.5,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
