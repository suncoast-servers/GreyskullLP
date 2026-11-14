import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/accessory_settings_page.dart';
import 'package:greyskull_lp/pages/settings/appearance_settings_page.dart';
import 'package:greyskull_lp/pages/settings/data_settings_page.dart';
import 'package:greyskull_lp/pages/settings/help_settings_page.dart';
import 'package:greyskull_lp/pages/settings/sharing_settings_page.dart';
import 'package:greyskull_lp/pages/settings/timing_settings_page.dart';
import 'package:greyskull_lp/pages/settings/training_settings_page.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';

/// Settings hub, modelled on the prototype's "More" page.
///
/// Each row opens a focused sub-page; every setting and button from the old
/// single-page settings screen is preserved.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              GsCard(
                gradient: LinearGradient(
                  colors: <Color>[
                    tokens.accent.withValues(alpha: 0.16),
                    tokens.surface,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderColor: tokens.accent.withValues(alpha: 0.28),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: <Widget>[
                    GsIconTile.svg('gear', size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Greyskull LP settings',
                            style: TextStyle(
                              fontFamily: GsFont.display,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: tokens.bone,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Local-first. Every change is saved on this device.',
                            style: TextStyle(
                              fontFamily: GsFont.body,
                              fontSize: 11,
                              height: 1.4,
                              color: tokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const GsSectionTitle('Appearance'),
              _row(
                context,
                svg: 'sun',
                title: 'Appearance & themes',
                subtitle: trainingState.activeSkin.displayName,
                page: const AppearanceSettingsPage(),
              ),
              const GsSectionTitle('Training'),
              _row(
                context,
                svg: 'target',
                title: 'Program & level',
                subtitle: trainingState.programLevel.shortLabel,
                page: const TrainingSettingsPage(),
              ),
              const SizedBox(height: 8),
              _row(
                context,
                svg: 'layers',
                title: 'Training preferences',
                subtitle:
                    '${TrainingState.methodLabel(trainingState.activeDailyMethod)} · ${TrainingState.nutritionModeLabel(trainingState.nutritionMode)}',
                page: const TrainingSettingsPage(),
              ),
              const SizedBox(height: 8),
              _row(
                context,
                svg: 'db',
                title: 'Barbell program',
                subtitle: trainingState.activeBarbellTemplateDetails.name,
                page: const TrainingSettingsPage(),
              ),
              const SizedBox(height: 8),
              _row(
                context,
                svg: 'repeat',
                title: 'Accessories',
                subtitle: _accessorySummary(),
                page: const AccessorySettingsPage(),
              ),
              const GsSectionTitle('Nation & sharing'),
              _row(
                context,
                svg: 'share',
                title: 'Sharing & accountability',
                subtitle: _accountabilitySummary(),
                page: const SharingSettingsPage(),
              ),
              const GsSectionTitle('Workout'),
              _row(
                context,
                svg: 'timer',
                title: 'Timing & alerts',
                subtitle: trainingState.restTimerEnabled
                    ? 'Rest ${trainingState.restTimerSeconds}s · notifications & reminders'
                    : 'Rest timer off · notifications & reminders',
                page: const TimingSettingsPage(),
              ),
              const GsSectionTitle('Data'),
              _row(
                context,
                svg: 'cloud',
                title: 'Backup & data',
                subtitle: 'Export, restore, privacy & demo data',
                page: const DataSettingsPage(),
              ),
              const GsSectionTitle('Help'),
              _row(
                context,
                svg: 'book',
                title: 'Help & tutorials',
                subtitle: 'Replay guides and the starter prompt',
                page: const HelpSettingsPage(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GsIcon('shield', size: 13, color: tokens.muted),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '100% local-first · no account required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: tokens.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String svg,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return GsListRow(
      svg: svg,
      title: title,
      subtitle: subtitle,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
  }

  String _accessorySummary() {
    final frequency =
        trainingState.getCalisthenicsAccessories(DailyMethod.frequency).length;
    final ladder =
        trainingState.getCalisthenicsAccessories(DailyMethod.ladder).length;
    final totalWork =
        trainingState.getCalisthenicsAccessories(DailyMethod.totalWork).length;
    return '$frequency + $ladder + $totalWork configured';
  }

  String _accountabilitySummary() {
    switch (trainingState.accountabilityMode) {
      case AccountabilityPostMode.off:
        return 'Accountability posts off';
      case AccountabilityPostMode.manual:
        return 'Manual forum drafts';
      case AccountabilityPostMode.onWorkoutComplete:
        return 'Draft after every workout';
      case AccountabilityPostMode.endOfDaySummary:
        return 'End-of-day summary';
    }
  }
}
