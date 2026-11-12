import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/services/demo_seed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final endDate = DateTime(2026, 11, 12);
  final startDate = endDate
      .subtract(const Duration(days: DemoSeedService.scenarioALengthDays - 1));

  group('Demo Scenario A payload (issue #55)', () {
    late Map<String, dynamic> payload;

    setUpAll(() {
      payload = DemoSeedService.buildScenarioA(endDate: endDate);
    });

    test('covers 90 days with weight, calisthenics, and diet history', () {
      final history =
          (payload['history'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(history.length, greaterThan(150));

      final timestamps = history
          .map((entry) => DateTime.parse(entry['timestamp'] as String))
          .toList()
        ..sort();
      expect(timestamps.first.isBefore(startDate), isFalse);
      expect(timestamps.last.isAfter(endDate.add(const Duration(days: 1))),
          isFalse);

      final categories = history.map((e) => e['category']).toSet();
      expect(categories, containsAll(['weight', 'daily', 'diet']));
    });

    test('transitions Frequency → Ladder → Total Work across the phases', () {
      final daily = (payload['history'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((entry) => entry['category'] == 'daily')
          .toList();

      final frequencyDays = daily
          .where((e) => e['method'] == 'frequency')
          .map((e) => DateTime.parse(e['timestamp'] as String))
          .toList();
      final ladderDays = daily
          .where((e) => e['method'] == 'ladder')
          .map((e) => DateTime.parse(e['timestamp'] as String))
          .toList();
      final totalWorkDays = daily
          .where((e) => e['method'] == 'totalWork')
          .map((e) => DateTime.parse(e['timestamp'] as String))
          .toList();

      expect(frequencyDays, isNotEmpty);
      expect(ladderDays, isNotEmpty);
      expect(totalWorkDays, isNotEmpty);

      final villainStart = startDate.add(const Duration(days: 30));
      final gladiatorStart = startDate.add(const Duration(days: 60));

      expect(frequencyDays.every((d) => d.isBefore(villainStart)), isTrue);
      expect(
        ladderDays.every(
            (d) => !d.isBefore(villainStart) && d.isBefore(gladiatorStart)),
        isTrue,
      );
      expect(totalWorkDays.every((d) => !d.isBefore(gladiatorStart)), isTrue);
    });

    test('barbell sessions show progressive overload', () {
      final weightEntries = (payload['history'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((entry) => entry['category'] == 'weight')
          .toList();
      expect(weightEntries.length, greaterThan(30));
      expect(
        weightEntries.every((e) =>
            (e['weightVolume'] as num).toDouble() > 0 &&
            (e['details'] as String).contains('Total Volume:')),
        isTrue,
      );

      final squashEntries = weightEntries
          .where((e) => (e['details'] as String).contains('Squat'))
          .toList();
      expect(squashEntries.length, greaterThan(10));

      double weightFrom(String details) {
        final match =
            RegExp(r'Squat \d+x\d+ @ ([\d.]+) lb').firstMatch(details);
        return double.parse(match!.group(1)!);
      }

      expect(
        weightFrom(squashEntries.last['details'] as String),
        greaterThan(weightFrom(squashEntries.first['details'] as String)),
      );
    });

    test('payload is deterministic and targets the Gladiator end state', () {
      final again = DemoSeedService.buildScenarioA(endDate: endDate);
      expect(again['history'].toString(), payload['history'].toString());
      expect(payload['programLevel'], 'gladiator');
      expect(payload['activeBarbellTemplate'], 'gladiator');
      expect(payload['hasCompletedOnboarding'], isTrue);
    });

    test('imports cleanly into TrainingState and produces milestones',
        () async {
      final state = TrainingState();
      final ok = await state.importBackupJson(
        DemoSeedService.buildScenarioAJson(endDate: endDate),
      );

      expect(ok, isTrue);
      expect(state.history.length, greaterThan(150));
      expect(state.programLevel, ProgramLevel.gladiator);
      expect(state.activeBarbellTemplate, BarbellTemplate.gladiator);
      expect(state.getMethodTransitions(), isNotEmpty);
      expect(
        state.getMethodTransitions().any(
              (m) => m.title == 'Started Barbell Program',
            ),
        isTrue,
      );
    });
  });

  group('Demo data availability', () {
    test('is exposed through a single scenario picker', () {
      expect(
          DemoSeedService.scenarios.map((s) => s.id), contains('scenario_a'));
      expect(
        DemoSeedService.buildScenarioJson('scenario_a', endDate: endDate),
        isNotEmpty,
      );
      expect(
        () => DemoSeedService.buildScenarioJson('unknown'),
        throwsArgumentError,
      );
    });

    test('demo import entry is available in debug test builds', () {
      expect(DemoSeedService.isAvailable, isTrue);
    });
  });

  group('Settings QA entry', () {
    testWidgets('offers the demo scenario and asks before replacing data',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );
      await tester.pumpAndSettle();

      final scenarioTile = find.text(DemoSeedService.scenarioATitle);
      await tester.scrollUntilVisible(
        scenarioTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('QA / Demo Data'), findsOneWidget);
      expect(scenarioTile, findsOneWidget);

      await tester.tap(scenarioTile);
      await tester.pumpAndSettle();

      expect(find.textContaining('REPLACES'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('REPLACES'), findsNothing);
    });
  });
}
