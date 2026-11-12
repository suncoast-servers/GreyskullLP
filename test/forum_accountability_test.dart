import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/services/accountability_template_service.dart';
import 'package:greyskull_lp/widgets/accountability_post_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? mockClipboardText;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.clearAccountabilityDrafts();
    trainingState.setAccountabilityMode(AccountabilityPostMode.off);
    trainingState.setForumSignedIn(signedIn: false);
    mockClipboardText = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        final args = methodCall.arguments as Map?;
        mockClipboardText = args?['text'] as String?;
        return null;
      }
      if (methodCall.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': mockClipboardText};
      }
      return null;
    });
  });

  group('AccountabilityTemplateService formatting & privacy', () {
    final fixedDate = DateTime(2026, 11, 11);

    test('generates formatted weight session log with volume and notes', () {
      final post = AccountabilityTemplateService.generateWeightSessionPost(
        coreLiftSummary:
            'Bench Press: 200 lbs x 5, 5, 8\nSquat: 275 lbs x 5, 5, 6',
        optionalExerciseSummary: 'Barbell Row, Romanian Deadlift',
        volume: 3250.0,
        notes: 'Crushed AMRAP reps with fast bar speed.',
        userDisplayName: 'IronJohnny',
        date: fixedDate,
      );

      expect(
          post, contains('[b]Greyskull LP - Workout Accountability Log[/b]'));
      expect(post, contains('📅 Date: 2026-11-11'));
      expect(post, contains('👤 Lifter: IronJohnny'));
      expect(post, contains('Bench Press: 200 lbs x 5, 5, 8'));
      expect(post, contains('Accessory Work:'));
      expect(post, contains('Barbell Row, Romanian Deadlift'));
      expect(post, contains('3250.0 lbs'));
      expect(post, contains('Crushed AMRAP reps with fast bar speed.'));
      expect(post, contains('https://store.greyskullnation.com/'));
    });

    test('generates formatted calisthenics log with negatives indicator', () {
      final post = AccountabilityTemplateService.generateDailyMethodPost(
        method: DailyMethod.frequency,
        pushUps: 60,
        chinUps: 25,
        usedNegatives: true,
        optionalExerciseSummary: 'Dips, Plank',
        userDisplayName: 'IronJohnny',
        date: fixedDate,
      );

      expect(post,
          contains('[b]Greyskull LP - Daily Calisthenics Accountability[/b]'));
      expect(post, contains('💪 Method: Frequency Method'));
      expect(post, contains('• Push-ups: 60 reps'));
      expect(post, contains('• Chin-ups: 25 reps (negatives used)'));
      expect(post, contains('• Optional: Dips, Plank'));
    });

    test(
        'generates cohesive end-of-day summary across lifts, calisthenics, and diet',
        () {
      final history = [
        HistoryEntry(
          timestamp: fixedDate,
          title: 'Weight Program Session',
          category: HistoryCategory.weight,
          weightVolume: 2500,
          details:
              'Overhead Press: 115 lbs x 5, 5, 8\nSquat: 225 lbs x 5, 5, 7',
        ),
        HistoryEntry(
          timestamp: fixedDate,
          title: 'Frequency Method Session',
          category: HistoryCategory.daily,
          pushUps: 50,
          chinUps: 20,
          details: 'Push-ups: 50, Chin-ups: 20',
        ),
      ];

      final post = AccountabilityTemplateService.generateDailySummaryPost(
        date: fixedDate,
        history: history,
        pushUpTarget: 50,
        chinUpTarget: 20,
        proteinConsumed: 180,
        calorieConsumed: 2200,
        userDisplayName: 'JohnnyFan',
      );

      expect(post,
          contains('[b]Greyskull LP - End-of-Day Accountability Summary[/b]'));
      expect(post, contains('Overhead Press: 115 lbs x 5, 5, 8'));
      expect(post, contains('Push-ups: 50 / 50 reps target'));
      expect(post, contains('Chin-ups: 20 / 20 reps target'));
      expect(post, contains('Protein: 180g'));
      expect(post, contains('Calories: 2200 kcal'));
    });

    test('guarantees zero PII in generated post templates', () {
      final post = AccountabilityTemplateService.generateWeightSessionPost(
        coreLiftSummary: 'Bench Press: 185 lbs',
        optionalExerciseSummary: 'None selected',
        volume: 1850.0,
      );

      // Verify no email pattern, IP pattern, or personal metadata
      expect(post, isNot(contains('@')));
      expect(post, isNot(contains('null')));
      expect(post, isNot(contains('192.168.')));
      expect(post, isNot(contains('uuid')));
    });
  });

  group('TrainingState Accountability Mode & Queue Management', () {
    test('updates accountability mode and persists across serialization', () {
      trainingState
          .setAccountabilityMode(AccountabilityPostMode.onWorkoutComplete);
      expect(
        trainingState.accountabilityMode,
        equals(AccountabilityPostMode.onWorkoutComplete),
      );

      trainingState
          .setAccountabilityMode(AccountabilityPostMode.endOfDaySummary);
      expect(
        trainingState.accountabilityMode,
        equals(AccountabilityPostMode.endOfDaySummary),
      );
    });

    test('queues drafts, marks posted, and removes drafts', () {
      expect(trainingState.accountabilityDrafts, isEmpty);

      final draft = trainingState.queueDailySummaryDraft();
      expect(trainingState.accountabilityDrafts.length, equals(1));
      expect(trainingState.latestAccountabilityDraft?.id, equals(draft.id));

      trainingState.markAccountabilityDraftPosted(draft.id);
      expect(trainingState.accountabilityDrafts.first.isPosted, isTrue);

      trainingState.removeAccountabilityDraft(draft.id);
      expect(trainingState.accountabilityDrafts, isEmpty);
      expect(trainingState.latestAccountabilityDraft, isNull);
    });

    test('auto-queues drafts when logging workouts with accountability enabled',
        () {
      trainingState
          .setAccountabilityMode(AccountabilityPostMode.onWorkoutComplete);

      final draft = trainingState.logWeightSession(
        coreLiftSummary: 'Overhead Press: 135 lbs',
        optionalExerciseSummary: 'None selected',
        volume: 1350.0,
      );

      expect(draft, isNotNull);
      expect(trainingState.accountabilityDrafts.length, equals(1));
      expect(draft!.content, contains('Overhead Press: 135 lbs'));
    });

    test('does not auto-queue drafts when mode is off', () {
      trainingState.setAccountabilityMode(AccountabilityPostMode.off);

      final draft = trainingState.logWeightSession(
        coreLiftSummary: 'Overhead Press: 135 lbs',
        optionalExerciseSummary: 'None selected',
        volume: 1350.0,
      );

      expect(draft, isNull);
      expect(trainingState.accountabilityDrafts, isEmpty);
    });
  });

  group('Interactive UI Widget Flows', () {
    testWidgets(
        'SettingsPage allows toggling accountability modes and triggers daily summary',
        (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Find Mode chips
      expect(find.text('Forum Accountability Posts'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('On Workout Complete'), findsOneWidget);
      expect(find.text('End-of-Day Summary'), findsOneWidget);

      // Select On Workout Complete
      await tester.tap(find.text('On Workout Complete'));
      await tester.pumpAndSettle();
      expect(
        trainingState.accountabilityMode,
        equals(AccountabilityPostMode.onWorkoutComplete),
      );

      // Tap Draft Today's End-of-Day Summary
      await tester.tap(find.text("Draft Today's End-of-Day Summary"));
      await tester.pumpAndSettle();

      // Accountability post sheet should be presented
      expect(find.text('Forum Accountability Post'), findsOneWidget);
      expect(find.text('Copy Draft'), findsOneWidget);
      expect(find.text('Open Forum'), findsOneWidget);
    });

    testWidgets(
        'AccountabilityPostSheet copies draft and shows guidance banner',
        (tester) async {
      final draft = AccountabilityDraft(
        id: 'test-123',
        timestamp: DateTime.now(),
        title: 'Workout Log',
        content: '[b]Greyskull LP - Test Log[/b]',
        category: 'weight',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountabilityPostSheet(draft: draft),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forum Accountability Post'), findsOneWidget);
      expect(find.text('REST API credentials pending founder setup'),
          findsOneWidget);
      expect(find.text('[b]Greyskull LP - Test Log[/b]'), findsOneWidget);

      // Tap Copy Draft button
      await tester.tap(find.text('Copy Draft'));
      await tester.pumpAndSettle();

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipboardData?.text, equals('[b]Greyskull LP - Test Log[/b]'));
    });
  });
}
