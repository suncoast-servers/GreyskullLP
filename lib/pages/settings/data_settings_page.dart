import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/settings_common.dart';
import 'package:greyskull_lp/services/demo_seed_service.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Backups, privacy disclosures, local-storage transparency and QA demo data.
class DataSettingsPage extends StatefulWidget {
  const DataSettingsPage({super.key});

  @override
  State<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends State<DataSettingsPage> {
  final TextEditingController _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _shareBackup() async {
    final payload = trainingState.exportBackupJson();
    final bytes = Uint8List.fromList(utf8.encode(payload));
    final now = DateTime.now();
    final fileName =
        'greyskull-backup-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
    await SharePlus.instance.share(
      ShareParams(
        text: 'Greyskull LP backup export',
        files: <XFile>[
          XFile.fromData(bytes, mimeType: 'application/json', name: fileName)
        ],
      ),
    );
  }

  Future<void> _copyBackup() async {
    final payload = trainingState.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup JSON copied to clipboard!')),
    );
  }

  Future<void> _restoreBackup() async {
    final ok = await trainingState.importBackupJson(_importController.text);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(ok ? 'Backup restored successfully' : 'Backup restore failed'),
      ),
    );
  }

  Future<void> _importDemoScenario(DemoScenario scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Load ${scenario.title}?'),
        content: Text(
          '${scenario.description}\n\n'
          'This REPLACES the app\'s current workouts, history, and settings with '
          '90 days of demo data. Export a backup first if you have real data '
          'you want to keep.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import demo data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final ok = await trainingState
        .importBackupJson(DemoSeedService.buildScenarioJson(scenario.id));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Demo data loaded — check the Stats and History tabs'
              : 'Demo data import failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const SettingsSectionTitle(
                'Backups',
                description:
                    'Everything is stored on this device. Export a backup before switching phones or uninstalling.',
              ),
              GsCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    SegmentedButton<BackupPreference>(
                      segments: BackupPreference.values
                          .map(
                            (mode) => ButtonSegment<BackupPreference>(
                              value: mode,
                              label: Text(
                                TrainingState.backupPreferenceLabel(mode),
                              ),
                            ),
                          )
                          .toList(),
                      selected: <BackupPreference>{
                        trainingState.backupPreference
                      },
                      onSelectionChanged: (selection) {
                        trainingState.setBackupPreference(selection.first);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareBackup,
                            icon: const GsIcon('share', size: 15),
                            label: const Text('Share File'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyBackup,
                            icon: const GsIcon('copy', size: 15),
                            label: const Text('Copy JSON'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _importController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Paste backup JSON to restore',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _restoreBackup,
                        icon: const GsIcon('up', size: 15),
                        label: const Text('Restore from Pasted Backup'),
                      ),
                    ),
                  ],
                ),
              ),
              const SettingsSectionTitle('Privacy & Data Ownership'),
              GsCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        GsIcon('shield', size: 18, color: tokens.accent),
                        const SizedBox(width: 8),
                        Text(
                          'Private by default',
                          style: TextStyle(
                            fontFamily: GsFont.body,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: tokens.bone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The official Greyskull LP app is 100% local-first and open-source. '
                      'Your workouts, lifts, body statistics, and nutrition logs belong to you, not our servers. '
                      'We do not track, profile, monetize, or harvest your personal health data.',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 11.5,
                        height: 1.5,
                        color: tokens.bone,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data Loss Protection: Because records are stored on-device, deleting the app will remove local history unless you export a backup. '
                      'Use "Share File" or "Copy JSON" above before switching phones or uninstalling.',
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
              const SettingsSectionTitle('Data Storage Transparency'),
              GsCard(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'This app currently stores workouts, history, and settings locally on-device using SharedPreferences JSON. '
                  'Cloud sync is not enabled yet; export/share backup is available.',
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11.5,
                    height: 1.5,
                    color: tokens.bone,
                  ),
                ),
              ),
              if (DemoSeedService.isAvailable) ...<Widget>[
                const SettingsSectionTitle(
                  'QA / Demo Data',
                  description:
                      'Debug builds only. Loads a realistic dataset so Stats and History can be reviewed at 90-day scale. Replaceable anytime with a backup restore.',
                ),
                ...DemoSeedService.scenarios.map(
                  (scenario) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: GsListRow(
                      svg: 'bolt',
                      title: scenario.title,
                      subtitle: scenario.description,
                      onTap: () => _importDemoScenario(scenario),
                      trailing: GsIcon(
                        'down',
                        size: 16,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
