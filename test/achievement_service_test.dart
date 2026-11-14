import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/achievement_service.dart';

HistoryEntry _entry({
  required DateTime at,
  HistoryCategory category = HistoryCategory.weight,
  String details = '',
  double? volume,
}) {
  return HistoryEntry(
    timestamp: at,
    title: 'Session',
    details: details,
    category: category,
    weightVolume: volume,
  );
}

void main() {
  group('AchievementService', () {
    test('empty history leaves every badge locked', () {
      final progress = AchievementService.evaluate(<HistoryEntry>[]);
      expect(progress.length, AchievementService.badges.length);
      expect(progress.every((badge) => !badge.isUnlocked), isTrue);
      expect(progress.every((badge) => badge.progress == 0), isTrue);
    });

    test('first rep unlocks all three tiers immediately', () {
      final progress = AchievementService.evaluate(<HistoryEntry>[
        _entry(at: DateTime(2026, 1, 1)),
      ]);
      final first = progress.firstWhere((badge) => badge.badge.id == 'first');
      expect(first.isUnlocked, isTrue);
      expect(first.earnedTiers, 3);
      expect(first.tierLabel, 'GOLD');
    });

    test('session tiers progress from Bronze to Gold', () {
      List<HistoryEntry> sessions(int count) {
        return List<HistoryEntry>.generate(
          count,
          (index) =>
              _entry(at: DateTime(2026, 1, 1).add(Duration(days: index))),
        );
      }

      final bronze = AchievementService.evaluate(sessions(10))
          .firstWhere((badge) => badge.badge.id == 'sessions');
      expect(bronze.earnedTiers, 1);
      expect(bronze.nextTier, 50);
      expect(bronze.progress, closeTo(0.2, 0.001));

      final silver = AchievementService.evaluate(sessions(50))
          .firstWhere((badge) => badge.badge.id == 'sessions');
      expect(silver.earnedTiers, 2);

      final gold = AchievementService.evaluate(sessions(100))
          .firstWhere((badge) => badge.badge.id == 'sessions');
      expect(gold.earnedTiers, 3);
    });

    test('longest streak counts consecutive training days', () {
      final history = <HistoryEntry>[
        _entry(at: DateTime(2026, 1, 1)),
        _entry(at: DateTime(2026, 1, 2)),
        _entry(at: DateTime(2026, 1, 3)),
        _entry(at: DateTime(2026, 1, 7)),
      ];
      expect(AchievementService.longestStreakDays(history), 3);
    });

    test('diet entries do not count toward sessions or streaks', () {
      final history = <HistoryEntry>[
        _entry(at: DateTime(2026, 1, 1), category: HistoryCategory.diet),
        _entry(at: DateTime(2026, 1, 2), category: HistoryCategory.diet),
      ];
      expect(AchievementService.totalSessions(history), 0);
      expect(AchievementService.longestStreakDays(history), 0);
      expect(
        AchievementService.evaluate(history)
            .firstWhere((badge) => badge.badge.id == 'first')
            .isUnlocked,
        isFalse,
      );
    });

    test('volume converts pounds to tonnes and crosses the first tier', () {
      final history = <HistoryEntry>[
        _entry(
          at: DateTime(2026, 1, 1),
          volume: 220462.26218487757, // 100 tonnes
        ),
      ];
      expect(
          AchievementService.totalVolumeTonnes(history), closeTo(100, 0.001));
      final volume = AchievementService.evaluate(history)
          .firstWhere((badge) => badge.badge.id == 'volume');
      expect(volume.earnedTiers, 1);
      expect(volume.nextTier, 500);
    });

    test('AMRAP Hunter counts completed barbell sets at 10+ reps', () {
      final history = <HistoryEntry>[
        _entry(
          at: DateTime(2026, 1, 1),
          details:
              'Overhead Press (Done, 100.0 lbs x 12 reps x 3 sets, AMRAP 30s)\n'
              'Squat (Done, 150.0 lbs x 8 reps x 3 sets)',
        ),
        _entry(
          at: DateTime(2026, 1, 2),
          details: 'Bench Press (Not marked, 135.0 lbs x 11 reps x 3 sets)',
        ),
      ];
      expect(AchievementService.amrapSetsAtLeast10(history), 1);
    });

    test('AMRAP Hunter also reads legacy demo summaries', () {
      final history = <HistoryEntry>[
        _entry(
          at: DateTime(2026, 1, 1),
          details: 'Core Lifts: Squat 3x5 @ 150.0 lb (AMRAP 12); '
              'Overhead Press 3x5 @ 80.0 lb (AMRAP 9)',
        ),
      ];
      expect(AchievementService.amrapSetsAtLeast10(history), 1);
    });
  });
}
