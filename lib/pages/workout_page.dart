import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'workout_setup_page.dart';
import 'workout_page_frequency.dart';
import 'workout_page_ladder.dart';
import 'workout_page_totalwork.dart';

class WorkoutPage extends StatefulWidget {
  final ValueNotifier<String> titleNotifier;

  const WorkoutPage({super.key, required this.titleNotifier});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!trainingState.hasCompletedOnboarding && mounted) {
        showStarterOnboardingDialog(context);
      }
    });
  }

  void _openSubPage(Widget page, String title) {
    setState(() {
      _currentPage = page;
    });
    widget.titleNotifier.value = title;
  }

  void _showGraduationSheet(
      {required ProgramLevel targetLevel, required VoidCallback onProceed}) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech,
                      color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Graduate to ${targetLevel.shortLabel}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                targetLevel.description,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Graduating never alters or deletes any prior workout logs or history.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText(context),
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onProceed();
                      },
                      child: const Text('Try Once Only'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        trainingState.setProgramLevel(targetLevel);
                        Navigator.of(context).pop();
                        onProceed();
                      },
                      child: Text('Graduate to Lvl ${targetLevel.levelNumber}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustLevelSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust Programming Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Switch your program level anytime without losing prior data:',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
              ),
              const SizedBox(height: 12),
              ...ProgramLevel.values.map((lvl) {
                final isCurrent = trainingState.programLevel == lvl;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      lvl == ProgramLevel.foundation
                          ? Icons.looks_one
                          : lvl == ProgramLevel.villain
                              ? Icons.looks_two
                              : Icons.looks_3,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.mutedText(context),
                    ),
                    title: Text(lvl.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(lvl.subtitle,
                        style: const TextStyle(fontSize: 12)),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Active',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        : TextButton(
                            onPressed: () {
                              trainingState.setProgramLevel(lvl);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Select'),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentPage = null;
                });
                widget.titleNotifier.value = 'Workout';
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to workout menu'),
            ),
          ),
          Expanded(child: _currentPage!),
        ],
      );
    }
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) => _buildWorkoutMainPage(),
    );
  }

  Widget _buildWorkoutMainPage() {
    widget.titleNotifier.value = "Workout";
    final level = trainingState.programLevel;
    final tokens = context.gs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: <Widget>[
        GsCard(
          gradient: LinearGradient(
            colors: <Color>[
              tokens.accent.withValues(alpha: 0.20),
              tokens.surface,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderColor: tokens.accent.withValues(alpha: 0.32),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  GsTag(level.shortLabel, tone: GsTagTone.accent),
                  const Spacer(),
                  TextButton(
                    onPressed: _showAdjustLevelSheet,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        GsIcon('reorder', size: 15, color: tokens.accent),
                        const SizedBox(width: 5),
                        const Text('Adjust Level'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                level.subtitle,
                style: TextStyle(
                  fontFamily: GsFont.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: tokens.bone,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                level.description,
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 11.5,
                  height: 1.45,
                  color: tokens.muted,
                ),
              ),
            ],
          ),
        ),
        const GsSectionTitle('Training methods'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: <Widget>[
            _buildWorkoutButton(
              'train',
              'Weight Program',
              onTap: () =>
                  _openSubPage(const WorkoutSetupPage(), 'Weight Program'),
              statusBadge: 'Core Lifts',
            ),
            _buildWorkoutButton(
              'repeat',
              'Frequency Method',
              onTap: () => _openSubPage(
                  const WorkoutPageFrequency(), 'Frequency Method'),
              isActive:
                  trainingState.activeDailyMethod == DailyMethod.frequency,
              statusBadge: 'Level 1 Active',
            ),
            _buildWorkoutButton(
              'ladder',
              'Ladder Method',
              onTap: () {
                if (!trainingState.isLadderMethodUnlocked) {
                  _showGraduationSheet(
                    targetLevel: ProgramLevel.villain,
                    onProceed: () => _openSubPage(
                        const WorkoutPageLadder(), 'Ladder Method'),
                  );
                } else {
                  _openSubPage(const WorkoutPageLadder(), 'Ladder Method');
                }
              },
              isActive: trainingState.activeDailyMethod == DailyMethod.ladder,
              statusBadge: trainingState.isLadderMethodUnlocked
                  ? 'Unlocked'
                  : 'Level 2+',
              isLocked: !trainingState.isLadderMethodUnlocked,
            ),
            _buildWorkoutButton(
              'target',
              'Total Work Method',
              onTap: () {
                if (!trainingState.isTotalWorkMethodUnlocked) {
                  _showGraduationSheet(
                    targetLevel: ProgramLevel.gladiator,
                    onProceed: () => _openSubPage(
                        const WorkoutPageTotalWork(), 'Total Work Method'),
                  );
                } else {
                  _openSubPage(
                      const WorkoutPageTotalWork(), 'Total Work Method');
                }
              },
              isActive:
                  trainingState.activeDailyMethod == DailyMethod.totalWork,
              statusBadge: trainingState.isTotalWorkMethodUnlocked
                  ? 'Unlocked'
                  : 'Level 3',
              isLocked: !trainingState.isTotalWorkMethodUnlocked,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutButton(
    String svgIcon,
    String label, {
    required VoidCallback onTap,
    bool isActive = false,
    String? statusBadge,
    bool isLocked = false,
  }) {
    final tokens = context.gs;
    final GsTagTone tone = isLocked
        ? GsTagTone.neutral
        : isActive
            ? GsTagTone.ok
            : GsTagTone.accent;

    return GsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              GsIconTile.svg(
                svgIcon,
                size: 38,
                color: isLocked ? tokens.muted : tokens.accent,
              ),
              const Spacer(),
              if (isLocked)
                GsIcon('lock', size: 16, color: tokens.muted)
              else
                GsIcon('chevron', size: 17, color: tokens.muted),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: isLocked ? tokens.muted : tokens.bone,
            ),
          ),
          if (statusBadge != null) ...<Widget>[
            const SizedBox(height: 7),
            GsTag(statusBadge, tone: tone),
          ],
        ],
      ),
    );
  }
}

void showStarterOnboardingDialog(BuildContext context,
    {VoidCallback? onCompleted}) {
  showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      ProgramLevel selected = ProgramLevel.foundation;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fitness_center, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome to Greyskull LP',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Select your initial programming level:',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Johnny Pain recommends all new trainees begin on Level 1 (Starter Base) before adding plug-in accessories or complex splits.',
                  style: TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 14),

                // Option cards
                ...ProgramLevel.values.map((level) {
                  final isChosen = selected == level;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isChosen
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isChosen ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setModalState(() => selected = level),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              level.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          if (level == ProgramLevel.foundation) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.positiveAccent(context)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.positiveAccent(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(level.subtitle,
                          style: const TextStyle(fontSize: 12)),
                      leading: Radio<ProgramLevel>(
                        value: level,
                        // ignore: deprecated_member_use
                        groupValue: selected,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selected = val);
                          }
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      trainingState.completeOnboarding(selectedLevel: selected);
                      Navigator.of(context).pop();
                      if (onCompleted != null) {
                        onCompleted();
                      }
                    },
                    child: const Text('Start Training',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
