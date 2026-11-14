import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/achievement_service.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:greyskull_lp/widgets/achievement_badge.dart';

/// All milestone badges, computed from real history.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: AnimatedBuilder(
        animation: trainingState,
        builder: (context, _) {
          final progress = AchievementService.evaluate(trainingState.history);
          final unlocked = progress.where((badge) => badge.isUnlocked).length;
          final longest = AchievementService.longestStreakDays(
            trainingState.history,
          );
          final sessions =
              AchievementService.totalSessions(trainingState.history);
          final volume =
              AchievementService.totalVolumeTonnes(trainingState.history);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'MILESTONES',
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$unlocked of ${progress.length} unlocked',
                      style: TextStyle(
                        fontFamily: GsFont.display,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: tokens.bone,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        GsTag('$longest DAY BEST', svgIcon: 'flame'),
                        GsTag('$sessions SESSIONS', svgIcon: 'trophy'),
                        GsTag('${volume.toStringAsFixed(1)} T', svgIcon: 'db'),
                      ],
                    ),
                  ],
                ),
              ),
              const GsSectionTitle('All badges'),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: 0.92,
                children: progress
                    .map(
                      (badge) => AchievementBadgeTile(
                        progress: badge,
                        onTap: () => showAchievementBadgeSheet(context, badge),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              GsCard(
                color: tokens.surface2,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Badges are calculated from your saved workouts on this device — '
                  'no account, no server and no fake progress. Total volume uses tonnes '
                  '(1 t = 2,204.6 lb).',
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
