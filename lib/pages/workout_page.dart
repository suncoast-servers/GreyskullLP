import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'workout_page_frequency.dart';
import 'workout_page_ladder.dart';
import 'workout_page_totalwork.dart';
import 'workout_page_weight.dart';

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
              const Text(
                'Note: Graduating never alters or deletes any prior workout logs or history.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
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
              const Text(
                'Switch your program level anytime without losing prior data:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
                          : Colors.grey,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Program Level Banner
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        level.shortLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAdjustLevelSheet,
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Adjust Level',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  level.subtitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  level.description,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Workout Buttons Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWorkoutButton(
              IconData(0xf6e6, fontFamily: 'MaterialSymbols'),
              'Weight Program',
              onTap: () =>
                  _openSubPage(const WorkoutPageWeight(), 'Weight Program'),
              statusBadge: 'Core Lifts',
            ),
            _buildWorkoutButton(
              Icons.repeat,
              'Frequency Method',
              onTap: () => _openSubPage(
                  const WorkoutPageFrequency(), 'Frequency Method'),
              isActive:
                  trainingState.activeDailyMethod == DailyMethod.frequency,
              statusBadge: 'Level 1 Active',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWorkoutButton(
              Icons.trending_up,
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
              Icons.balance,
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
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isActive = false,
    String? statusBadge,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 46,
                  color: isLocked
                      ? Colors.grey.shade400
                      : Theme.of(context).primaryColor,
                ),
                if (isLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.lock, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLocked ? Colors.grey.shade600 : null,
              ),
            ),
            if (statusBadge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : isLocked
                          ? Colors.grey.withValues(alpha: 0.15)
                          : Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusBadge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? Colors.green.shade800
                        : isLocked
                            ? Colors.grey.shade700
                            : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Greyskull LP',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Select your initial programming level:',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54),
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
                            : Colors.grey.shade300,
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
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
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
