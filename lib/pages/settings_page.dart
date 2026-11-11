import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _socialHashtagController;
  late final TextEditingController _forumUrlController;
  late final TextEditingController _forumLoginUrlController;
  late final TextEditingController _forumNameController;
  late final TextEditingController _storeUrlController;
  late final TextEditingController _usdaApiKeyController;
  final TextEditingController _backupImportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socialHashtagController =
        TextEditingController(text: trainingState.socialShareHashtag);
    _forumUrlController = TextEditingController(text: trainingState.forumUrl);
    _forumLoginUrlController =
        TextEditingController(text: trainingState.forumLoginUrl);
    _forumNameController =
        TextEditingController(text: trainingState.forumDisplayName);
    _storeUrlController = TextEditingController(text: trainingState.storeUrl);
    _usdaApiKeyController =
        TextEditingController(text: trainingState.usdaApiKey);
  }

  @override
  void dispose() {
    _socialHashtagController.dispose();
    _forumUrlController.dispose();
    _forumLoginUrlController.dispose();
    _forumNameController.dispose();
    _storeUrlController.dispose();
    _usdaApiKeyController.dispose();
    _backupImportController.dispose();
    super.dispose();
  }

  void _saveUrlSettings() {
    trainingState.setSocialShareHashtag(_socialHashtagController.text);
    trainingState.setForumUrl(_forumUrlController.text);
    trainingState.setForumLoginUrl(_forumLoginUrlController.text);
    trainingState.setStoreUrl(_storeUrlController.text);
    trainingState.setUsdaApiKey(_usdaApiKeyController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
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
                        ? const Icon(Icons.check_circle, color: Colors.green)
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
              const Text(
                'Johnny Pain progressive UX: start simple with the base barbell program and frequency method, then graduate to accessories and higher density methods.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
                          : Colors.grey.shade300,
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
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lvl.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black54,
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
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Zero data loss: changing your level changes UI complexity without deleting or modifying any prior workout history or PRs.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
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
              const Text(
                'Official Greyskull LP progression structures (Johnny Pain 3rd Edition):',
                style: TextStyle(fontSize: 13, color: Colors.grey),
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
                  final details = TrainingState.templateDefinitions[template]!;
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
                'Forum Integration (WordPress)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _forumNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Forum display name',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        trainingState.setForumSignedIn(
                          signedIn: true,
                          displayName: _forumNameController.text,
                        );
                      },
                      child: const Text('Mark Signed In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        trainingState.setForumSignedIn(signedIn: false);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trainingState.forumSignedIn
                    ? 'Forum status: signed in as ${trainingState.forumDisplayName.isEmpty ? 'user' : trainingState.forumDisplayName}'
                    : 'Forum status: not signed in',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _forumUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Forum URL',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _forumLoginUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Forum login URL',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  trainingState.resetForumUrlsToDefault();
                  setState(() {
                    _forumUrlController.text = TrainingState.defaultForumUrl;
                    _forumLoginUrlController.text =
                        TrainingState.defaultForumLoginUrl;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Forum URLs reset to default'),
                    ),
                  );
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset Forum URLs to Default'),
              ),
              const Divider(height: 32),
              const Text(
                'Store Integration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _storeUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Store URL',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  trainingState.resetStoreUrlToDefault();
                  setState(() {
                    _storeUrlController.text = TrainingState.defaultStoreUrl;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Store URL reset to default')),
                  );
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset Store URL to Default'),
              ),
              const Divider(height: 32),
              const Text(
                'Free Calorie Data API',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open Food Facts is used by default. Add a free USDA API key to enable fallback.',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usdaApiKeyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'USDA API key (optional)',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveUrlSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
              const Divider(height: 32),
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
              OutlinedButton.icon(
                onPressed: _shareBackup,
                icon: const Icon(Icons.ios_share),
                label: const Text('Export and Share Backup JSON'),
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
              const Text(
                'Data Storage Transparency',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app currently stores workouts, history, and settings locally on-device using SharedPreferences JSON. '
                'Cloud sync is not enabled yet; export/share backup is available.',
              ),
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
