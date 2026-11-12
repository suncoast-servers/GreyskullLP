import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/demo_seed_service.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _socialHashtagController;
  final TextEditingController _backupImportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socialHashtagController =
        TextEditingController(text: trainingState.socialShareHashtag);
  }

  @override
  void dispose() {
    _socialHashtagController.dispose();
    _backupImportController.dispose();
    super.dispose();
  }

  void _saveSocialSettings() {
    trainingState.setSocialShareHashtag(_socialHashtagController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing settings saved')),
    );
  }

  String _accountabilityModeDescription(AccountabilityPostMode mode) {
    switch (mode) {
      case AccountabilityPostMode.off:
        return 'Accountability posts are disabled.';
      case AccountabilityPostMode.manual:
        return 'Manually draft and share posts via "Post to Forum" actions.';
      case AccountabilityPostMode.onWorkoutComplete:
        return 'Automatically pop up the formatted draft whenever a workout is completed.';
      case AccountabilityPostMode.endOfDaySummary:
        return 'Compile all completed lifts, daily calisthenics, and nutrition into one daily summary.';
    }
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

  Future<void> _copyBackupToClipboard() async {
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
    final ok =
        await trainingState.importBackupJson(_backupImportController.text);
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
        actions: [
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
    if (confirmed != true || !mounted) return;

    final ok = await trainingState
        .importBackupJson(DemoSeedService.buildScenarioJson(scenario.id));
    if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Theme & Skins (Greyskull Motif)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your gym aesthetic: rugged dark charcoal, pitch black OLED, or daylight chalk.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 10),
              ...GreyskullSkin.values.map((skin) {
                final isSelected = trainingState.activeSkin == skin;
                final onSurface = Theme.of(context).colorScheme.onSurface;
                final primaryColor = Theme.of(context).primaryColor;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.35),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onTap: () => trainingState.setActiveSkin(skin),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(skin.bgHex),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: onSurface.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Color(skin.accentHex),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          skin.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.15)
                                : onSurface.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            skin.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? primaryColor
                                  : onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          skin.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          skin.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: AppTheme.positiveAccent(context))
                        : null,
                  ),
                );
              }),
              const Divider(height: 32),
              const Text(
                'Program Level & Progression',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Johnny Pain progressive UX: start simple with the base barbell program and frequency method, then graduate to accessories and higher density methods.',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
              ),
              const SizedBox(height: 8),
              ...ProgramLevel.values.map((lvl) {
                final isSelected = trainingState.programLevel == lvl;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<ProgramLevel>(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    value: lvl,
                    // ignore: deprecated_member_use
                    groupValue: trainingState.programLevel,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        trainingState.setProgramLevel(val);
                      }
                    },
                    title: Row(
                      children: [
                        Text(
                          lvl.shortLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.15)
                                : AppTheme.mutedText(context)
                                    .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lvl.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : AppTheme.mutedText(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          lvl.subtitle,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          lvl.description,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 16, color: AppTheme.positiveAccent(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Zero data loss: changing your level changes UI complexity without deleting or modifying any prior workout history or PRs.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.positiveAccent(context),
                          fontStyle: FontStyle.italic),
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
              const Divider(height: 32),
              const Text(
                'Preferred Daily Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
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
                  final method = selection.first;
                  trainingState.setActiveDailyMethod(method);
                },
              ),
              const Divider(height: 32),
              const Text(
                'Daily Repetition Targets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _TargetAdjuster(
                label: 'Push-ups',
                value: trainingState.dailyPushUpTarget,
                onDecrease: () => trainingState
                    .setDailyPushUpTarget(trainingState.dailyPushUpTarget - 5),
                onIncrease: () => trainingState
                    .setDailyPushUpTarget(trainingState.dailyPushUpTarget + 5),
              ),
              _TargetAdjuster(
                label: 'Chin-ups / negatives',
                value: trainingState.dailyChinUpTarget,
                onDecrease: () => trainingState
                    .setDailyChinUpTarget(trainingState.dailyChinUpTarget - 1),
                onIncrease: () => trainingState
                    .setDailyChinUpTarget(trainingState.dailyChinUpTarget + 1),
              ),
              _TargetAdjuster(
                label: 'Daily protein target (g)',
                value: trainingState.dailyProteinTarget,
                onDecrease: () => trainingState.setDailyProteinTarget(
                    trainingState.dailyProteinTarget - 5),
                onIncrease: () => trainingState.setDailyProteinTarget(
                    trainingState.dailyProteinTarget + 5),
              ),
              _TargetAdjuster(
                label: 'Daily calorie target',
                value: trainingState.dailyCalorieTarget,
                onDecrease: () => trainingState.setDailyCalorieTarget(
                    trainingState.dailyCalorieTarget - 50),
                onIncrease: () => trainingState.setDailyCalorieTarget(
                    trainingState.dailyCalorieTarget + 50),
              ),
              const SizedBox(height: 8),
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
              const Divider(height: 32),
              const Text(
                'Barbell Program Template',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Official Greyskull LP progression structures (Johnny Pain 3rd Edition):',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.mutedText(context)),
              ),
              const SizedBox(height: 8),
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
                  return DropdownMenuItem(
                    value: template,
                    child: Text(
                      details.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (newTemplate) {
                  if (newTemplate != null) {
                    trainingState.setBarbellTemplate(newTemplate);
                  }
                },
              ),
              const Divider(height: 32),
              const Text(
                'Weight Program Optional Exercises',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...TrainingState.weightOptionalExerciseOptions.map(
                (exercise) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise),
                  value: trainingState.selectedWeightOptionalExercises
                      .contains(exercise),
                  onChanged: (_) =>
                      trainingState.toggleWeightOptionalExercise(exercise),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Daily Method Optional Exercises',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...TrainingState.dailyOptionalExerciseOptions.map(
                (exercise) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise),
                  value: trainingState.selectedDailyOptionalExercises
                      .contains(exercise),
                  onChanged: (_) =>
                      trainingState.toggleDailyOptionalExercise(exercise),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Forum Accountability Posts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share progress with the Greyskull Nation community for mutual accountability.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text(
                'Posting Mode',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Off'),
                    selected: trainingState.accountabilityMode ==
                        AccountabilityPostMode.off,
                    onSelected: (selected) {
                      if (selected) {
                        trainingState
                            .setAccountabilityMode(AccountabilityPostMode.off);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Manual'),
                    selected: trainingState.accountabilityMode ==
                        AccountabilityPostMode.manual,
                    onSelected: (selected) {
                      if (selected) {
                        trainingState.setAccountabilityMode(
                            AccountabilityPostMode.manual);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('On Workout Complete'),
                    selected: trainingState.accountabilityMode ==
                        AccountabilityPostMode.onWorkoutComplete,
                    onSelected: (selected) {
                      if (selected) {
                        trainingState.setAccountabilityMode(
                            AccountabilityPostMode.onWorkoutComplete);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('End-of-Day Summary'),
                    selected: trainingState.accountabilityMode ==
                        AccountabilityPostMode.endOfDaySummary,
                    onSelected: (selected) {
                      if (selected) {
                        trainingState.setAccountabilityMode(
                            AccountabilityPostMode.endOfDaySummary);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _accountabilityModeDescription(
                    trainingState.accountabilityMode),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final draft = trainingState.queueDailySummaryDraft();
                  AccountabilityPostSheet.show(context, draft: draft);
                },
                icon: const Icon(Icons.summarize, size: 16),
                label: const Text("Draft Today's End-of-Day Summary"),
              ),
              if (trainingState.accountabilityDrafts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Drafts (${trainingState.accountabilityDrafts.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () =>
                          trainingState.clearAccountabilityDrafts(),
                      child: const Text('Clear All',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trainingState.accountabilityDrafts.length,
                  itemBuilder: (context, index) {
                    final draft = trainingState.accountabilityDrafts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          draft.category == 'weight'
                              ? Icons.fitness_center
                              : (draft.category == 'daily'
                                  ? Icons.accessibility_new
                                  : Icons.calendar_today),
                          size: 20,
                        ),
                        title: Text(draft.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${draft.timestamp.year}-${draft.timestamp.month.toString().padLeft(2, '0')}-${draft.timestamp.day.toString().padLeft(2, '0')} - ${draft.category}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              tooltip: 'Open / Copy Draft',
                              onPressed: () => AccountabilityPostSheet.show(
                                  context,
                                  draft: draft),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              tooltip: 'Delete Draft',
                              onPressed: () => trainingState
                                  .removeAccountabilityDraft(draft.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const Divider(height: 32),
              const Text(
                'Social Workout Sharing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Prompt to share after workout'),
                subtitle: const Text(
                  'Offers a share sheet preview after logging a workout. User always confirms before sharing.',
                ),
                value: trainingState.socialSharePromptEnabled,
                onChanged: (val) =>
                    trainingState.setSocialSharePromptEnabled(val),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _socialHashtagController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Default share hashtags & attribution',
                  hintText: '#GreyskullLP #JohnnyPain',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saveSocialSettings,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Sharing Settings'),
              ),
              const Divider(height: 32),
              const Text(
                'Workout Timing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Countdown between sets during barbell sessions.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rest timer between sets'),
                subtitle: const Text(
                  'Starts automatically when a set is marked complete.',
                ),
                value: trainingState.restTimerEnabled,
                onChanged: (val) => trainingState.setRestTimerEnabled(val),
              ),
              if (trainingState.restTimerEnabled) ...[
                const SizedBox(height: 4),
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
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound and vibration when rest ends'),
                  value: trainingState.restTimerSoundEnabled,
                  onChanged: (val) =>
                      trainingState.setRestTimerSoundEnabled(val),
                ),
              ],
              const Divider(height: 32),
              const Text(
                'Backups',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SegmentedButton<BackupPreference>(
                segments: BackupPreference.values
                    .map(
                      (mode) => ButtonSegment<BackupPreference>(
                        value: mode,
                        label: Text(TrainingState.backupPreferenceLabel(mode)),
                      ),
                    )
                    .toList(),
                selected: <BackupPreference>{trainingState.backupPreference},
                onSelectionChanged: (selection) {
                  trainingState.setBackupPreference(selection.first);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareBackup,
                      icon: const Icon(Icons.ios_share, size: 16),
                      label: const Text('Share File'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyBackupToClipboard,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy JSON'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _backupImportController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Paste backup JSON to restore',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _restoreBackup,
                icon: const Icon(Icons.restore),
                label: const Text('Restore from Pasted Backup'),
              ),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Privacy & Data Ownership',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The official Greyskull LP app is 100% local-first and open-source. '
                      'Your workouts, lifts, body statistics, and nutrition logs belong to you, not our servers. '
                      'We do not track, profile, monetize, or harvest your personal health data.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data Loss Protection: Because records are stored on-device, deleting the app will remove local history unless you export a backup. '
                      'Use "Share File" or "Copy JSON" above before switching phones or uninstalling.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Data Storage Transparency',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app currently stores workouts, history, and settings locally on-device using SharedPreferences JSON. '
                'Cloud sync is not enabled yet; export/share backup is available.',
              ),
              if (DemoSeedService.isAvailable) ...[
                const Divider(height: 32),
                const Text(
                  'QA / Demo Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Debug builds only. Loads a realistic dataset so Stats and History can be reviewed at 90-day scale. '
                  'Replaceable anytime with a backup restore.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 10),
                ...DemoSeedService.scenarios.map(
                  (scenario) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(
                        scenario.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        scenario.description,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.download_outlined, size: 20),
                      onTap: () => _importDemoScenario(scenario),
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

class _TargetAdjuster extends StatelessWidget {
  const _TargetAdjuster({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text('$label: $value'),
            ),
            IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove)),
            IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
          ],
        ),
      ),
    );
  }
}
