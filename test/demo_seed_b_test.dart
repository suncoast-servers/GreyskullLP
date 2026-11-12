import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/demo_seed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final endDate = DateTime(2026, 11, 12);
  final startDate = endDate
      .subtract(const Duration(days: DemoSeedService.scenarioBLengthDays - 1));

  group('Demo Scenario B payload (issue #56)', () {
    late Map<String, dynamic> payload;

    setUpAll(() {
      payload = DemoSeedService.buildScenarioB(endDate: endDate);
    });

    test('is a 90-day cutting block with weight, calisthenics and diet', () {
      final history =
          (payload['history'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(history.length, greaterThan(120));
      expect(payload['nutritionMode'], 'cutting');
      expect(payload['dailyCalorieTarget'], lessThan(2000));

      final categories = history.map((e) => e['category']).toSet();
      expect(categories, containsAll(['weight', 'daily', 'diet']));
    });

    test('transitions Frequency -> Ladder -> Total Work over the cut', () {
      final daily = (payload['history'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((e) => e['category'] == 'daily');

      DateTime ts(Map<String, dynamic> e) =>
          DateTime.parse(e['timestamp'] as String);

      final ladderStart = startDate.add(const Duration(days: 40));
      final totalWorkStart = startDate.add(const Duration(days: 70));

      expect(
        daily
            .where((e) => e['method'] == 'frequency')
            .every((e) => ts(e as Map<String, dynamic>).isBefore(ladderStart)),
        isTrue,
      );
      expect(
        daily
            .where((e) => e['method'] == 'ladder')
            .every((e) => !ts(e as Map<String, dynamic>).isBefore(ladderStart)),
        isTrue,
      );
      expect(
        daily.where((e) => e['method'] == 'totalWork').every(
            (e) => !ts(e as Map<String, dynamic>).isBefore(totalWorkStart)),
        isTrue,
      );
    });

    test('bodyweight trend goes down across the diet logs', () {
      final diets = (payload['history'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((e) => e['category'] == 'diet')
          .toList();

      double weightOf(Map<String, dynamic> entry) {
        final match = RegExp(r'Bodyweight: ([\d.]+) kg')
            .firstMatch(entry['details'] as String);
        return double.parse(match!.group(1)!);
      }

      expect(diets.length, greaterThan(50));
      expect(weightOf(diets.first), greaterThan(weightOf(diets.last)));
      expect(weightOf(diets.first) - weightOf(diets.last), greaterThan(3));
    });

    test('barbell loads stall and reset while cutting', () {
      final weights = (payload['history'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((e) => e['category'] == 'weight')
          .map((e) {
            final match = RegExp(r'Squat \d+x\d+ @ ([\d.]+) lb')
                .firstMatch(e['details'] as String);
            return match == null ? null : double.parse(match.group(1)!);
          })
          .whereType<double>()
          .toList();

      expect(weights.length, greaterThan(10));
      final hasReset = <int>[
        for (var i = 1; i < weights.length; i++)
          if (weights[i] < weights[i - 1]) i
      ];
      expect(hasReset, isNotEmpty,
          reason: 'cutting sessions should include at least one 10% reset');
    });

    test('imports into TrainingState', () async {
      final state = TrainingState();
      final ok = await state.importBackupJson(
        DemoSeedService.buildScenarioBJson(endDate: endDate),
      );
      expect(ok, isTrue);
      expect(state.nutritionMode, NutritionMode.cutting);
      expect(state.activeBarbellTemplate, BarbellTemplate.twoDaySplit);
      expect(state.history.length, greaterThan(120));
    });

    test('picker exposes both scenarios through one import path', () {
      final ids = DemoSeedService.scenarios.map((s) => s.id).toList();
      expect(ids, containsAll(['scenario_a', 'scenario_b']));
      expect(
        () => DemoSeedService.buildScenarioJson('scenario_b', endDate: endDate),
        returnsNormally,
      );
    });
  });
}
