import 'package:flutter/material.dart';
import 'package:greyskull_lp/services/achievement_service.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';

/// Compact badge tile used on Home and the Achievements page.
class AchievementBadgeTile extends StatelessWidget {
  const AchievementBadgeTile({
    super.key,
    required this.progress,
    this.onTap,
  });

  final BadgeProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final unlocked = progress.isUnlocked;
    return Material(
      color: unlocked ? tokens.accent.withValues(alpha: 0.12) : tokens.surface2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: unlocked ? tokens.accent.withValues(alpha: 0.45) : tokens.line,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GsIcon(
                progress.badge.icon,
                size: 21,
                color: unlocked ? tokens.accent : tokens.muted,
              ),
              const SizedBox(height: 6),
              Text(
                progress.badge.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 7.5,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: unlocked ? tokens.bone : tokens.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress.tierLabel,
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: unlocked ? tokens.accent : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full badge detail with Bronze/Silver/Gold tiers.
Future<void> showAchievementBadgeSheet(
  BuildContext context,
  BadgeProgress progress,
) {
  final tokens = context.gs;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: progress.isUnlocked
                            ? tokens.accent.withValues(alpha: 0.15)
                            : tokens.surface2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: progress.isUnlocked
                              ? tokens.accent.withValues(alpha: 0.45)
                              : tokens.line,
                        ),
                      ),
                      child: Center(
                        child: GsIcon(
                          progress.badge.icon,
                          size: 30,
                          color: progress.isUnlocked
                              ? tokens.accent
                              : tokens.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            progress.badge.name,
                            style: TextStyle(
                              fontFamily: GsFont.display,
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              color: tokens.bone,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress.badge.description,
                            style: TextStyle(
                              fontFamily: GsFont.body,
                              fontSize: 11.5,
                              height: 1.45,
                              color: tokens.muted,
                            ),
                          ),
                          const SizedBox(height: 7),
                          GsTag(
                            progress.tierLabel,
                            tone: progress.isUnlocked
                                ? GsTagTone.accent
                                : GsTagTone.neutral,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'CURRENT',
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.formattedValue} ${progress.badge.unit}',
                  style: TextStyle(
                    fontFamily: GsFont.mono,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: tokens.accent,
                  ),
                ),
                const SizedBox(height: 14),
                ...List<Widget>.generate(progress.badge.tiers.length, (index) {
                  final tier = progress.badge.tiers[index];
                  final earned = progress.earnedTiers > index;
                  final ratio = (progress.value / tier).clamp(0.0, 1.0);
                  final names = <String>['Bronze', 'Silver', 'Gold'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: earned
                              ? tokens.accent.withValues(alpha: 0.35)
                              : tokens.line,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${names[index]} · ${_tierLabel(progress.badge, tier)}',
                                  style: TextStyle(
                                    fontFamily: GsFont.body,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.bone,
                                  ),
                                ),
                              ),
                              GsTag(
                                earned ? 'EARNED' : '${(ratio * 100).round()}%',
                                tone: earned ? GsTagTone.ok : GsTagTone.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: tokens.line.withValues(
                                alpha: 0.45,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                earned ? tokens.ok : tokens.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                GsPrimaryButton(
                  label: 'Close',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _tierLabel(BadgeDefinition badge, num tier) {
  if (badge.unit == 't') {
    return '$tier t';
  }
  return '$tier ${badge.unit}';
}
