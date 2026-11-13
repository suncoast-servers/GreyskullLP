import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/widgets/tutorial_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.replayTutorials();
    Tutorials.debugForcedEnabled = true;
  });

  tearDown(() {
    Tutorials.debugForcedEnabled = null;
  });

  group('Section tutorials (issue #83)', () {
    test('seen flags persist and replay clears them', () async {
      final state = TrainingState();
      expect(state.hasSeenTutorial('live_workout'), isFalse);

      state.markTutorialSeen('live_workout');
      final restored = TrainingState();
      expect(await restored.importBackupJson(state.exportBackupJson()), isTrue);
      expect(restored.hasSeenTutorial('live_workout'), isTrue);

      restored.replayTutorials();
      expect(restored.hasSeenTutorial('live_workout'), isFalse);
    });

    test('every section has two or more steps', () {
      for (final section in [
        'weight_setup',
        'live_workout',
        'frequency',
        'ladder',
        'total_work',
      ]) {
        expect(Tutorials.forSection(section).length, greaterThanOrEqualTo(2),
            reason: section);
      }
    });

    testWidgets('tutorial shows once, steps advance, skip marks it seen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    Tutorials.showIfNeeded(context, 'live_workout'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('5 · 5 · 5+'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 3'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(trainingState.hasSeenTutorial('live_workout'), isTrue);

      // Reopening does not show it again.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('5 · 5 · 5+'), findsNothing);
    });
  });
}
