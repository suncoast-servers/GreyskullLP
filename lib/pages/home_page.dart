import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/themes/app_icons.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';

/// Dashboard-style home. Every tile and action routes to an existing tab —
/// no new destinations or data were added.
class HomePage extends StatelessWidget {
  final Function(int) onItemSelected;
  const HomePage({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final tokens = context.gs;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: <Widget>[
            _ProgramHero(onTap: () => onItemSelected(0)),
            const SizedBox(height: 12),
            _TodaySessionCard(onTap: () => onItemSelected(0)),
            const SizedBox(height: 12),
            _StreakCard(onTap: () => onItemSelected(3)),
            const GsSectionTitle('Explore'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: <Widget>[
                _HomeTile(
                  icon: AppIcons.barbell,
                  label: 'Workout',
                  subtitle: 'Plan & log',
                  onTap: () => onItemSelected(0),
                ),
                _HomeTile(
                  icon: Icons.forum_outlined,
                  label: 'Forum',
                  subtitle: 'Greyskull Nation',
                  onTap: () => onItemSelected(1),
                ),
                _HomeTile(
                  icon: Icons.restaurant_outlined,
                  label: 'Diet',
                  subtitle: 'Fuel & macros',
                  onTap: () => onItemSelected(2),
                ),
                _HomeTile(
                  icon: Icons.stacked_line_chart,
                  label: 'Stats',
                  subtitle: 'Progress',
                  onTap: () => onItemSelected(3),
                ),
                _HomeTile(
                  icon: Icons.history,
                  label: 'History',
                  subtitle: 'Past sessions',
                  onTap: () => onItemSelected(4),
                ),
                _HomeTile(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Store',
                  subtitle: 'Official gear',
                  onTap: () => onItemSelected(5),
                ),
              ],
            ),
            GsSectionTitle(
              'Recent activity',
              trailing: TextButton(
                onPressed: () => onItemSelected(4),
                child: Text(
                  'View all',
                  style: TextStyle(fontSize: 11, color: tokens.accent),
                ),
              ),
            ),
            ..._recentActivity(context, onItemSelected),
          ],
        );
      },
    );
  }

  List<Widget> _recentActivity(
    BuildContext context,
    Function(int) onItemSelected,
  ) {
    final entries = trainingState.history.take(3).toList();
    if (entries.isEmpty) {
      return <Widget>[
        GsCard(
          child: Text(
            'No sessions logged yet. Start a workout and it will appear here.',
            style: gsCaption(context),
          ),
        ),
      ];
    }

    return entries.map((entry) {
      final date = entry.timestamp;
      final stamp =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final IconData icon = switch (entry.category) {
        HistoryCategory.weight => AppIcons.barbell,
        HistoryCategory.daily => Icons.accessibility_new,
        HistoryCategory.diet => Icons.restaurant_outlined,
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GsListRow(
          icon: icon,
          title: entry.title,
          subtitle: '$stamp · ${_categoryLabel(entry.category)}',
          onTap: () => onItemSelected(4),
        ),
      );
    }).toList();
  }

  String _categoryLabel(HistoryCategory category) {
    switch (category) {
      case HistoryCategory.weight:
        return 'Resistance';
      case HistoryCategory.daily:
        return 'Calisthenics';
      case HistoryCategory.diet:
        return 'Diet';
    }
  }
}

class _ProgramHero extends StatelessWidget {
  const _ProgramHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final level = trainingState.programLevel;
    return GsCard(
      onTap: onTap,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CURRENT PROGRAM',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GsFont.display,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        letterSpacing: 0.2,
                        color: tokens.bone,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.subtitle,
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GsRing(
                progress: level.levelNumber / ProgramLevel.values.length,
                size: 66,
                strokeWidth: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${level.levelNumber}',
                      style: TextStyle(
                        fontFamily: GsFont.display,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: tokens.bone,
                      ),
                    ),
                    Text(
                      'LEVEL',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              GsTag(level.badge, tone: GsTagTone.accent),
              GsTag(
                TrainingState.methodLabel(trainingState.activeDailyMethod),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  const _TodaySessionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final template = trainingState.activeBarbellTemplateDetails;
    final workout = trainingState.currentTemplateWorkout;
    final lifts = workout.coreLifts.take(4).toList();

    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "TODAY'S SESSION",
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: tokens.muted,
                  ),
                ),
              ),
              GsTag('${workout.coreLifts.length} LIFTS'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            workout.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GsFont.display,
              fontSize: 23,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: tokens.bone,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${template.name} · ${workout.subtitle}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 11.5,
              height: 1.4,
              color: tokens.muted,
            ),
          ),
          if (lifts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lifts
                  .map((lift) => GsTag(
                        lift.name,
                        icon: Icons.fitness_center,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          GsPrimaryButton(
            label: 'Start Workout',
            icon: Icons.play_arrow_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final streak = trainingState.calculateCurrentStreakDays();
    final now = DateTime.now();
    final dayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final activeDays = <bool>[];
    for (var i = 6; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      activeDays.add(
        trainingState.history.any(
          (entry) => DateUtils.isSameDay(entry.timestamp, day),
        ),
      );
    }
    final start = now.subtract(const Duration(days: 6));
    final labelOffset = start.weekday - 1;

    return GsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              GsIconTile(
                Icons.local_fire_department,
                size: 38,
                color: tokens.accent2,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      streak == 0 ? 'Start your streak' : '$streak-day streak',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.bone,
                      ),
                    ),
                    Text(
                      streak == 0
                          ? 'Log a session to begin'
                          : '${activeDays.where((active) => active).length} '
                              'active of the last 7 days',
                      style: gsCaption(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 17, color: tokens.muted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(7, (int index) {
              final active = activeDays[index];
              final isToday = index == 6;
              return Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      dayLabels[(labelOffset + index) % 7],
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: active
                            ? tokens.accent.withValues(alpha: 0.16)
                            : tokens.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active
                              ? tokens.accent.withValues(alpha: 0.5)
                              : isToday
                                  ? tokens.accent
                                  : tokens.line,
                          width: isToday && !active ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: active
                            ? Icon(Icons.check, size: 13, color: tokens.accent)
                            : Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: tokens.muted.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return GsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              GsIconTile(icon, size: 34),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: tokens.muted),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: tokens.bone,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 10.5,
              color: tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
