import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings/settings_common.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';

/// Forum accountability drafts and social sharing preferences.
class SharingSettingsPage extends StatefulWidget {
  const SharingSettingsPage({super.key});

  @override
  State<SharingSettingsPage> createState() => _SharingSettingsPageState();
}

class _SharingSettingsPageState extends State<SharingSettingsPage> {
  late final TextEditingController _hashtagController;

  @override
  void initState() {
    super.initState();
    _hashtagController =
        TextEditingController(text: trainingState.socialShareHashtag);
  }

  @override
  void dispose() {
    _hashtagController.dispose();
    super.dispose();
  }

  String _modeDescription(AccountabilityPostMode mode) {
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

  void _saveSocialSettings() {
    trainingState.setSocialShareHashtag(_hashtagController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Sharing')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              const SettingsSectionTitle(
                'Forum Accountability Posts',
                description:
                    'Share progress with the Greyskull Nation community for mutual accountability.',
              ),
              Text(
                'Posting Mode',
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.bone,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _modeChip('Off', AccountabilityPostMode.off),
                  _modeChip('Manual', AccountabilityPostMode.manual),
                  _modeChip('On Workout Complete',
                      AccountabilityPostMode.onWorkoutComplete),
                  _modeChip('End-of-Day Summary',
                      AccountabilityPostMode.endOfDaySummary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _modeDescription(trainingState.accountabilityMode),
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 11,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: tokens.muted,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final draft = trainingState.queueDailySummaryDraft();
                  AccountabilityPostSheet.show(context, draft: draft);
                },
                icon: const GsIcon('book', size: 15),
                label: const Text("Draft Today's End-of-Day Summary"),
              ),
              if (trainingState.accountabilityDrafts.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Pending Drafts (${trainingState.accountabilityDrafts.length})',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.bone,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          trainingState.clearAccountabilityDrafts(),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                ...trainingState.accountabilityDrafts.map(
                  (draft) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: GsListRow(
                      svg: draft.category == 'weight'
                          ? 'db'
                          : draft.category == 'daily'
                              ? 'bolt'
                              : 'food',
                      title: draft.title,
                      subtitle:
                          '${draft.timestamp.year}-${draft.timestamp.month.toString().padLeft(2, '0')}-${draft.timestamp.day.toString().padLeft(2, '0')} · ${draft.category}',
                      onTap: () =>
                          AccountabilityPostSheet.show(context, draft: draft),
                      trailing: IconButton(
                        tooltip: 'Delete Draft',
                        icon: GsIcon('trash', size: 17, color: tokens.danger),
                        onPressed: () =>
                            trainingState.removeAccountabilityDraft(draft.id),
                      ),
                    ),
                  ),
                ),
              ],
              const SettingsSectionTitle('Social Workout Sharing'),
              GsCard(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prompt to share after workout'),
                      subtitle: const Text(
                        'Offers a share sheet preview after logging a workout. User always confirms before sharing.',
                      ),
                      value: trainingState.socialSharePromptEnabled,
                      onChanged: (value) =>
                          trainingState.setSocialSharePromptEnabled(value),
                    ),
                    TextField(
                      controller: _hashtagController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Default share hashtags & attribution',
                        hintText: '#GreyskullLP #JohnnyPain',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _saveSocialSettings,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Save Sharing Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _modeChip(String label, AccountabilityPostMode mode) {
    final selected = trainingState.accountabilityMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (value) {
          trainingState.setAccountabilityMode(mode);
        }
      },
    );
  }
}
