import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:greyskull_lp/models/training_state.dart';

/// QA-only demo data fixtures (issue #55 / #56).
///
/// These scenarios exist so the owner and contractor can review **Stats** and
/// **History** at real-world scale (90 days of training) without waiting three
/// months. They are never enabled in store builds unless the app is compiled
/// with `--dart-define=ENABLE_DEMO_DATA=true`.
class DemoSeedService {
  const DemoSeedService._();

  static const bool _compileTimeFlag = bool.fromEnvironment('ENABLE_DEMO_DATA');

  /// Demo import is available in debug/profile builds only.
  static bool get isAvailable => kDebugMode || _compileTimeFlag;

  static const int scenarioALengthDays = 90;

  static const String scenarioATitle =
      'Scenario A — 90-day newbie (OG → Villain → Gladiator)';
  static const String scenarioADescription =
      'Beginner on the OG Base program for ~30 days, Villain for ~30 days, '
      'then Gladiator with Frequency → Ladder → Total Work transitions.';

  /// Scenario B (issue #56) lands separately; the picker already reads this
  /// list so both fixtures share one import path.
  static List<DemoScenario> get scenarios => const [
        DemoScenario(
          id: 'scenario_a',
          title: scenarioATitle,
          description: scenarioADescription,
        ),
      ];

  static String buildScenarioAJson({
    DateTime? endDate,
    TrainingState? state,
  }) =>
      jsonEncode(buildScenarioA(endDate: endDate, state: state));

  /// Single import path shared by every fixture so scenario B (#56) only needs
  /// a new case here.
  static String buildScenarioJson(String scenarioId, {DateTime? endDate}) {
    switch (scenarioId) {
      case 'scenario_a':
        return buildScenarioAJson(endDate: endDate);
      default:
        throw ArgumentError.value(scenarioId, 'scenarioId', 'Unknown scenario');
    }
  }

  /// Builds a `schemaVersion: 2` backup payload that can be fed straight into
  /// [TrainingState.importBackupJson].
  ///
  /// The output is deterministic (seeded) so QA screenshots and bug reports
  /// stay comparable between runs.
  static Map<String, dynamic> buildScenarioA({
    DateTime? endDate,
    TrainingState? state,
    int seed = 42,
  }) {
    final templateState = state ?? trainingState;
    final random = Random(seed);
    final today = _dayOnly(endDate ?? DateTime.now());
    final start = today.subtract(const Duration(days: scenarioALengthDays - 1));

    const villainStart = 30;
    const gladiatorStart = 60;

    final history = <Map<String, dynamic>>[];
    final liftWeights = <String, double>{};
    var rotation = 0;

    for (var dayIndex = 0; dayIndex < scenarioALengthDays; dayIndex++) {
      final date = start.add(Duration(days: dayIndex));
      final phase =
          dayIndex < villainStart ? 1 : (dayIndex < gladiatorStart ? 2 : 3);
      final template = switch (phase) {
        1 => BarbellTemplate.ogBase,
        2 => BarbellTemplate.villain,
        _ => BarbellTemplate.gladiator,
      };
      final details = templateState.getTemplateDetails(template);
      final workouts = details.workouts;
      if (workouts.isEmpty) continue;

      // Barbell: Mon/Wed/Fri A/B rotation.
      final isLiftDay = date.weekday == DateTime.monday ||
          date.weekday == DateTime.wednesday ||
          date.weekday == DateTime.friday;
      if (isLiftDay) {
        final workout = workouts[rotation % workouts.length];
        rotation++;
        history.add(
          _weightEntry(
            date: date,
            templateName: details.name,
            workout: workout,
            liftWeights: liftWeights,
            random: random,
            phase: phase,
          ),
        );
      }

      // Calisthenics: 6 days a week, method follows the program phase.
      if (date.weekday != DateTime.sunday) {
        history.addAll(
          _calisthenicsEntries(
            date: date,
            dayIndex: dayIndex,
            phase: phase,
            random: random,
          ),
        );
      }

      // Diet: four logs a week (bulking calories/protein).
      if (date.weekday == DateTime.monday ||
          date.weekday == DateTime.tuesday ||
          date.weekday == DateTime.thursday ||
          date.weekday == DateTime.saturday) {
        final protein = 140 + (dayIndex * 0.5).round() + random.nextInt(9);
        final calories = 2450 + (dayIndex * 5) + random.nextInt(180);
        history.add({
          'timestamp': _at(date, const _ClockTime(hour: 20, minute: 15))
              .toIso8601String(),
          'title': 'Diet Intake',
          'category': 'diet',
          'proteinGrams': protein,
          'calories': calories,
          'details':
              'Protein: ${protein}g, Calories: $calories\nNote: Demo fixture (Scenario A)',
        });
      }
    }

    return {
      'schemaVersion': 2,
      'programLevel': 'gladiator',
      'hasCompletedOnboarding': true,
      'activeBarbellTemplate': 'gladiator',
      'activeBarbellRotationIndex': rotation % 3,
      'activeSkin': 'ironAndBone',
      'activeDailyMethod': 'totalWork',
      'nutritionMode': 'bulking',
      'backupPreference': 'manualExport',
      'dailyPushUpTarget': 150,
      'dailyChinUpTarget': 50,
      'dailyProteinTarget': 180,
      'dailyCalorieTarget': 2900,
      'dailyProteinConsumed': 0,
      'dailyCaloriesConsumed': 0,
      'macroTrackingDate': today.toIso8601String(),
      'frequencyTrackingDate': today.toIso8601String(),
      'todayFrequencySets': <dynamic>[],
      'todayFrequencyAccessories': <dynamic>[],
      'todayLadderLadders': <dynamic>[],
      'activeLadderExercise': 'Chin-ups',
      'activeLadderUsedNegatives': false,
      'activeCompletedLadders': <dynamic>[],
      'activeCurrentLadderRungs': <dynamic>[],
      'activeTotalWorkExercise': 'Push-ups',
      'activeTotalWorkUsedNegatives': false,
      'activeTotalWorkModel': 'daily',
      'activeTotalWorkTargetReps': 250,
      'activeTotalWorkSets': <dynamic>[],
      'accountabilityMode': 'off',
      'history': history,
    };
  }

  static Map<String, dynamic> _weightEntry({
    required DateTime date,
    required String templateName,
    required TemplateWorkoutDay workout,
    required Map<String, double> liftWeights,
    required Random random,
    required int phase,
  }) {
    final coreSummaries = <String>[];
    var volume = 0.0;

    for (final lift in workout.coreLifts) {
      final weight = _nextWeight(lift, liftWeights);
      final sets = lift.sets <= 0 ? 3 : lift.sets;
      final amrapReps = lift.isAmrap ? 5 + random.nextInt(8) : 5;
      var liftVolume = 0.0;
      for (var set = 0; set < sets; set++) {
        final reps = set == sets - 1 && lift.isAmrap ? amrapReps : 5;
        liftVolume += weight * reps;
      }
      volume += liftVolume;
      coreSummaries.add(
        '${lift.name} ${sets}x5 @ ${_fmtWeight(weight)} lb'
        '${lift.isAmrap ? ' (AMRAP $amrapReps)' : ''}',
      );
    }

    final accessories = phase == 1
        ? <String>[]
        : workout.defaultAccessories.take(2).toList(growable: false);
    final accessorySummary =
        accessories.isEmpty ? 'None' : accessories.join(', ');

    final details = StringBuffer()
      ..writeln('Core Lifts: ${coreSummaries.join('; ')}')
      ..writeln('Accessories: $accessorySummary')
      ..writeln('Total Volume: ${volume.toStringAsFixed(1)} lbs');

    return {
      'timestamp':
          _at(date, const _ClockTime(hour: 18, minute: 30)).toIso8601String(),
      'title': '$templateName — ${workout.title}',
      'category': 'weight',
      'weightVolume': double.parse(volume.toStringAsFixed(1)),
      'details': details.toString().trim(),
    };
  }

  static List<Map<String, dynamic>> _calisthenicsEntries({
    required DateTime date,
    required int dayIndex,
    required int phase,
    required Random random,
  }) {
    final progress = dayIndex / (scenarioALengthDays - 1);

    if (phase == 1) {
      // Frequency: sub-maximal sets spread through the day.
      final totalPushUps = (45 + progress * 110).round() + random.nextInt(6);
      final totalChinUps = (10 + progress * 32).round() + random.nextInt(3);
      final sets = 3 + random.nextInt(3); // 3-5 sets
      final breakdown = <String>[];
      var pushRemaining = totalPushUps;
      var chinRemaining = totalChinUps;
      for (var set = 1; set <= sets; set++) {
        final isLast = set == sets;
        final push = isLast ? pushRemaining : (pushRemaining / 2).round();
        final chin = isLast ? chinRemaining : (chinRemaining / 2).round();
        pushRemaining -= push;
        chinRemaining -= chin;
        breakdown.add('Set $set: $push push-ups, $chin chin-ups');
      }
      final targetPushUps = (50 + progress * 100).round();
      final targetChinUps = (20 + progress * 30).round();

      return [
        {
          'timestamp': _at(date, const _ClockTime(hour: 21, minute: 0))
              .toIso8601String(),
          'title': 'Frequency Method Day Summary',
          'category': 'daily',
          'method': 'frequency',
          'pushUps': totalPushUps,
          'chinUps': totalChinUps,
          'details': 'Total Push-ups: $totalPushUps / $targetPushUps\n'
              'Total Chin-ups: $totalChinUps / $targetChinUps\n'
              'Sets completed: $sets\n'
              'Optional Accessories: None\n\n'
              'Breakdown:\n${breakdown.join('\n')}',
          'methodMetadata': {
            'setsCount': sets,
            'pushUpTarget': targetPushUps,
            'chinUpTarget': targetChinUps,
            'accessories': <String>[],
          },
        },
      ];
    }

    if (phase == 2) {
      // Ladder: chin-up ladders plus the daily push-up frequency tally.
      final ladders = 3 + random.nextInt(3); // 3-5 ladders
      final peakRung = 3 + progress * 4 > 6 ? 6 : 3 + (progress * 4).round();
      final rungs = <List<int>>[];
      var totalReps = 0;
      for (var ladder = 1; ladder <= ladders; ladder++) {
        final rungList = <int>[];
        for (var rung = 1; rung <= peakRung; rung++) {
          rungList.add(rung);
          totalReps += rung;
        }
        rungs.add(rungList);
      }

      final pushUps = (70 + progress * 90).round() + random.nextInt(8);
      final pushTarget = (90 + progress * 90).round();

      return [
        {
          'timestamp': _at(date, const _ClockTime(hour: 12, minute: 30))
              .toIso8601String(),
          'title': 'Ladder Method Session (Chin-ups)',
          'category': 'daily',
          'method': 'ladder',
          'pushUps': pushUps,
          'chinUps': totalReps,
          'details': 'Exercise: Chin-ups\n'
              'Total Reps: $totalReps\n'
              'Ladders completed: $ladders\n'
              'Peak Rung: $peakRung\n'
              'Optional: Dips, Planks\n\n'
              'Ladders Breakdown:\n'
              '${rungs.asMap().entries.map((e) => 'Ladder ${e.key + 1}: ${e.value.join('-')}').join('\n')}',
          'methodMetadata': {
            'exercise': 'Chin-ups',
            'totalReps': totalReps,
            'peakRung': peakRung,
            'laddersCount': ladders,
            'usedNegatives': false,
            'pushUpTarget': pushTarget,
          },
        },
      ];
    }

    // Total Work: density sets toward a daily/weekly target.
    final weeklyModel = dayIndex.isEven;
    final targetReps = weeklyModel
        ? (300 + progress * 500).round()
        : (90 + progress * 160).round();
    final completedReps =
        (targetReps * (0.72 + random.nextDouble() * 0.26)).round();
    final setsList = <int>[];
    var remaining = completedReps;
    // Weekly targets represent several sessions, so use larger chunks to keep
    // the breakdown readable in History.
    final chunkSize = weeklyModel ? 28 : 15;
    while (remaining > 0) {
      final chunk = min(remaining, chunkSize + random.nextInt(14));
      setsList.add(chunk);
      remaining -= chunk;
    }
    return [
      {
        'timestamp':
            _at(date, const _ClockTime(hour: 17, minute: 45)).toIso8601String(),
        'title': 'Total Work Method Session (Push-ups)',
        'category': 'daily',
        'method': 'totalWork',
        'pushUps': completedReps,
        'chinUps': 0,
        'details': 'Exercise: Push-ups\n'
            'Total Reps: $completedReps\n'
            'Target Reps: $targetReps\n'
            'Model: ${weeklyModel ? 'weekly' : 'daily'}\n'
            'Sets completed: ${setsList.length}\n\n'
            'Set breakdown: ${setsList.join(' + ')}',
        'methodMetadata': {
          'exercise': 'Push-ups',
          'totalReps': completedReps,
          'targetReps': targetReps,
          'model': weeklyModel ? 'weekly' : 'daily',
          'setsCount': setsList.length,
          'usedNegatives': false,
          'sets': setsList,
        },
      },
    ];
  }

  static double _nextWeight(
    TemplateLift lift,
    Map<String, double> liftWeights,
  ) {
    final base = _baseWeightFor(lift);
    final current = liftWeights[lift.name] ?? base;
    final next = current <= 0 ? base : current;
    final increment = lift.isUpperBody ? 2.5 : 5.0;
    liftWeights[lift.name] = next + increment;
    return next;
  }

  static double _baseWeightFor(TemplateLift lift) {
    final name = lift.name.toLowerCase();
    if (name.contains('deadlift')) return 95;
    if (name.contains('squat')) return 65;
    if (name.contains('press')) return 45;
    if (name.contains('bench')) return 65;
    if (name.contains('row')) return 55;
    if (name.contains('curl')) return 25;
    if (name.contains('dip') || name.contains('chin')) return 25;
    if (name.contains('neck')) return 10;
    return lift.isUpperBody ? 45 : 65;
  }

  static String _fmtWeight(double weight) {
    final isWhole = weight == weight.roundToDouble();
    return isWhole ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1);
  }

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _at(DateTime day, _ClockTime time) => DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
}

/// Describes one selectable demo dataset (scenario A today, B in #56).
class DemoScenario {
  const DemoScenario({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

/// Minimal local time-of-day value so this file does not need Flutter widgets.
class _ClockTime {
  const _ClockTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
