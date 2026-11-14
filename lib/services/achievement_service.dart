import 'package:greyskull_lp/models/training_state.dart';

/// What a badge measures.
enum BadgeMetric { firstRep, sessions, streak, amrap10, volumeTonnes }

/// One milestone badge, with Bronze/Silver/Gold thresholds.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.metric,
    required this.name,
    required this.description,
    required this.icon,
    required this.unit,
    required this.tiers,
  });

  final String id;
  final BadgeMetric metric;
  final String name;
  final String description;

  /// Name of the SVG asset in `assets/icons` (without `.svg`).
  final String icon;
  final String unit;
  final List<num> tiers;
}

/// A badge evaluated against the current history.
class BadgeProgress {
  const BadgeProgress({
    required this.badge,
    required this.value,
    required this.earnedTiers,
    required this.nextTier,
  });

  final BadgeDefinition badge;
  final num value;

  /// 0 = locked, 1 = Bronze, 2 = Silver, 3 = Gold.
  final int earnedTiers;
  final num? nextTier;

  bool get isUnlocked => earnedTiers > 0;

  double get progress {
    if (nextTier == null) {
      return 1;
    }
    return (value / nextTier!).clamp(0.0, 1.0);
  }

  String get tierLabel {
    switch (earnedTiers) {
      case 3:
        return 'GOLD';
      case 2:
        return 'SILVER';
      case 1:
        return 'BRONZE';
      default:
        return 'LOCKED';
    }
  }

  String get formattedValue {
    if (badge.unit == 't') {
      return value.toStringAsFixed(1);
    }
    return value.round().toString();
  }
}

/// Milestone badges computed from real history.
///
/// Nothing is persisted: every value is derived, so backups, edits and deletes
/// can never leave a badge out of sync.
class AchievementService {
  const AchievementService._();

  static const List<BadgeDefinition> badges = <BadgeDefinition>[
    BadgeDefinition(
      id: 'streak7',
      metric: BadgeMetric.streak,
      name: '7-Day Streak',
      description: 'Train on consecutive days.',
      icon: 'flame',
      unit: 'days',
      tiers: <num>[7, 30, 60],
    ),
    BadgeDefinition(
      id: 'streak30',
      metric: BadgeMetric.streak,
      name: 'Iron Monarch',
      description: 'Hold the longest streaks.',
      icon: 'crown',
      unit: 'days',
      tiers: <num>[30, 90, 180],
    ),
    BadgeDefinition(
      id: 'sessions',
      metric: BadgeMetric.sessions,
      name: 'Session Vet',
      description: 'Complete full training sessions.',
      icon: 'trophy',
      unit: 'sessions',
      tiers: <num>[10, 50, 100],
    ),
    BadgeDefinition(
      id: 'amrap',
      metric: BadgeMetric.amrap10,
      name: 'AMRAP Hunter',
      description: 'Hit 10+ reps on an AMRAP set.',
      icon: 'bolt',
      unit: 'sets',
      tiers: <num>[10, 50, 100],
    ),
    BadgeDefinition(
      id: 'volume',
      metric: BadgeMetric.volumeTonnes,
      name: 'Volume King',
      description: 'Move serious total tonnage.',
      icon: 'db',
      unit: 't',
      tiers: <num>[100, 500, 1000],
    ),
    BadgeDefinition(
      id: 'first',
      metric: BadgeMetric.firstRep,
      name: 'First Rep',
      description: 'Log your very first set.',
      icon: 'star',
      unit: 'done',
      tiers: <num>[1, 1, 1],
    ),
  ];

  static List<BadgeProgress> evaluate(List<HistoryEntry> history) {
    return badges.map((badge) {
      final value = valueFor(badge.metric, history);
      var earned = 0;
      num? next;
      for (final tier in badge.tiers) {
        if (value + 1e-9 >= tier) {
          earned++;
        } else {
          next ??= tier;
        }
      }
      return BadgeProgress(
        badge: badge,
        value: value,
        earnedTiers: earned,
        nextTier: next,
      );
    }).toList();
  }

  static num valueFor(BadgeMetric metric, List<HistoryEntry> history) {
    switch (metric) {
      case BadgeMetric.firstRep:
        return totalSessions(history) > 0 ? 1 : 0;
      case BadgeMetric.sessions:
        return totalSessions(history);
      case BadgeMetric.streak:
        return longestStreakDays(history);
      case BadgeMetric.amrap10:
        return amrapSetsAtLeast10(history);
      case BadgeMetric.volumeTonnes:
        return totalVolumeTonnes(history);
    }
  }

  /// Weight and calisthenics sessions count; diet entries do not.
  static int totalSessions(List<HistoryEntry> history) {
    return history
        .where((entry) =>
            entry.category == HistoryCategory.weight ||
            entry.category == HistoryCategory.daily)
        .length;
  }

  static double totalVolumeTonnes(List<HistoryEntry> history) {
    final pounds = history.fold<double>(
      0,
      (sum, entry) => sum + (entry.weightVolume ?? 0),
    );
    return pounds / 2204.6226218487757;
  }

  /// Completed barbell sets where the logged AMRAP reps reached 10+.
  ///
  /// Handles both the current live-session format
  /// (`Done, 100.0 lbs x 12 reps x 3 sets`) and the demo/legacy summary format
  /// (`3x5 @ 100.0 lb (AMRAP 12)`).
  static int amrapSetsAtLeast10(List<HistoryEntry> history) {
    final liveRegex = RegExp(
      r'\(Done,\s*[\d.]+ lbs x (\d+) reps x \d+ sets',
    );
    final summaryRegex = RegExp(r'\(AMRAP (\d+)\)');
    var count = 0;
    for (final entry in history) {
      if (entry.category != HistoryCategory.weight) {
        continue;
      }
      for (final match in liveRegex.allMatches(entry.details)) {
        final reps = int.tryParse(match.group(1) ?? '') ?? 0;
        if (reps >= 10) {
          count++;
        }
      }
      for (final match in summaryRegex.allMatches(entry.details)) {
        final reps = int.tryParse(match.group(1) ?? '') ?? 0;
        if (reps >= 10) {
          count++;
        }
      }
    }
    return count;
  }

  /// Consecutive local training days, ending today or yesterday.
  static int currentStreakDays(
    List<HistoryEntry> history, {
    DateTime? now,
  }) {
    final days = _workoutDays(history);
    if (days.isEmpty) {
      return 0;
    }
    final today = _dayKey(now ?? DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final latest = days.reduce((a, b) => a.isAfter(b) ? a : b);
    if (latest != today && latest != yesterday) {
      return 0;
    }
    var streak = 1;
    var cursor = latest;
    while (days.contains(cursor.subtract(const Duration(days: 1)))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive training days in the history.
  static int longestStreakDays(List<HistoryEntry> history) {
    final days = _workoutDays(history).toList()..sort();
    if (days.isEmpty) {
      return 0;
    }
    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static Set<DateTime> _workoutDays(List<HistoryEntry> history) {
    return history
        .where((entry) =>
            entry.category == HistoryCategory.weight ||
            entry.category == HistoryCategory.daily)
        .map((entry) => _dayKey(entry.timestamp))
        .toSet();
  }

  /// UTC-normalised day key so DST changes cannot break day comparisons.
  static DateTime _dayKey(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
