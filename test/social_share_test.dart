import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/history_page.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:greyskull_lp/services/social_share_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SocialShareService.shareHandler = null;
  });

  tearDown(() {
    SocialShareService.shareHandler = null;
  });

  group('SocialShareService caption formatting', () {
    test('formats weight session caption with attribution and hashtags', () {
      final entry = HistoryEntry(
        timestamp: DateTime(2026, 3, 15, 10, 30),
        title: 'Weight Program Session',
        details:
            'Bench Press (225 lbs x 8 AMRAP), Squat (315 lbs x 7 AMRAP)\nOptional: Barbell Row',
        category: HistoryCategory.weight,
        weightVolume: 4005.0,
      );

      final caption = SocialShareService.formatWorkoutCaption(
        entry: entry,
        customHashtag: '#GreyskullBeast #JohnnyPain',
        userNote: 'Felt strong on the AMRAP set today!',
      );

      expect(caption, contains('Crushed my Greyskull LP workout! 💥'));
      expect(caption, contains('🏋️ Program: Weight Program Session'));
      expect(caption, contains('Bench Press (225 lbs x 8 AMRAP)'));
      expect(caption, contains('Total Volume: 4005.0 lbs'));
      expect(caption, contains('💬 Note: Felt strong on the AMRAP set today!'));
      expect(caption, contains(SocialShareService.defaultAttribution));
      expect(caption, contains('#GreyskullBeast #JohnnyPain'));
    });

    test('formats calisthenics session caption with method and reps', () {
      final entry = HistoryEntry(
        timestamp: DateTime(2026, 3, 15, 12, 0),
        title: 'Frequency Method Session',
        details: 'Push-ups: 65, Chin-ups: 25\nOptional: Dips',
        category: HistoryCategory.daily,
        pushUps: 65,
        chinUps: 25,
      );

      final caption = SocialShareService.formatWorkoutCaption(entry: entry);

      expect(caption, contains('Logged my daily Greyskull LP work! 🦍'));
      expect(caption, contains('💪 Method: Frequency Method Session'));
      expect(caption, contains('Push-ups: 65'));
      expect(caption, contains('Chin-ups: 25'));
      expect(caption, contains(SocialShareService.defaultAttribution));
      expect(caption, contains(SocialShareService.defaultHashtag));
    });

    test('formats diet intake session caption', () {
      final entry = HistoryEntry(
        timestamp: DateTime(2026, 3, 15, 18, 0),
        title: 'Diet Intake',
        details: 'Chicken breast + Rice\nMode: Cutting',
        category: HistoryCategory.diet,
        proteinGrams: 185,
        calories: 2150,
      );

      final caption = SocialShareService.formatWorkoutCaption(entry: entry);

      expect(caption, contains('Greyskull LP nutrition update! 🥩'));
      expect(caption, contains('Protein: 185g'));
      expect(caption, contains('Energy: 2150 kcal'));
      expect(caption, contains(SocialShareService.defaultAttribution));
    });
  });

  group('Social share persistence in TrainingState', () {
    test('defaults socialSharePromptEnabled to true and hashtag to default',
        () {
      expect(trainingState.socialSharePromptEnabled, isTrue);
      expect(trainingState.socialShareHashtag, contains('#GreyskullLP'));
    });

    test('updates and toggles social share settings', () {
      trainingState.setSocialSharePromptEnabled(false);
      expect(trainingState.socialSharePromptEnabled, isFalse);

      trainingState.setSocialShareHashtag('#CustomGainz');
      expect(trainingState.socialShareHashtag, equals('#CustomGainz'));

      // Empty string resets to default
      trainingState.setSocialShareHashtag('   ');
      expect(
          trainingState.socialShareHashtag, equals('#GreyskullLP #JohnnyPain'));
    });
  });

  group('Social share interactive UI flows', () {
    testWidgets(
        'opens share modal sheet and executes shareHandler with custom note',
        (tester) async {
      String? sharedText;
      String? sharedSubject;
      List<XFile>? sharedFiles;

      SocialShareService.shareHandler = ({
        required String text,
        String? subject,
        Rect? sharePositionOrigin,
        List<XFile>? files,
      }) async {
        sharedText = text;
        sharedSubject = subject;
        sharedFiles = files;
      };

      final entry = HistoryEntry(
        timestamp: DateTime.now(),
        title: 'Weight Program Session',
        details: 'Squat 315 lbs x 5',
        category: HistoryCategory.weight,
        weightVolume: 1575.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SocialShareService.showShareModal(
                  context: context,
                  entry: entry,
                  defaultHashtag: '#JohnnyPain',
                ),
                child: const Text('Open Share'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pumpAndSettle();

      expect(find.text('Share Workout to Social'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Share to apps / save'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Selfie'), findsOneWidget);
      expect(find.text('Copy caption'), findsOneWidget);
      expect(find.text('Forum'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Location (optional)'),
          'Suncoast Barbell');
      await tester.tap(find.text('Share to apps / save'));
      await tester.pumpAndSettle();

      expect(sharedText, isNotNull);
      expect(sharedText, contains('Crushed my Greyskull LP workout!'));
      expect(sharedText, contains('Squat 315 lbs x 5'));
      expect(sharedText, contains('📍 Suncoast Barbell'));
      expect(sharedSubject, equals('My Greyskull LP Workout'));
      expect(sharedFiles, isNull);
    });

    testWidgets('HistoryPage displays share icon and opens share modal',
        (tester) async {
      trainingState.logWeightSession(
        coreLiftSummary: 'Overhead Press 135x5',
        optionalExerciseSummary: 'None',
        volume: 675.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsWidgets);
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();

      expect(find.text('Share Workout to Social'), findsOneWidget);
      expect(find.text('Share to apps / save'), findsOneWidget);
    });

    testWidgets('Weight workout page provides share button after logging',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutPageWeight()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Recent Weight Workout'), findsOneWidget);
    });

    testWidgets('SettingsPage allows configuring social share settings',
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

      expect(find.text('Social Workout Sharing'), findsOneWidget);
      expect(find.text('Prompt to share after workout'), findsOneWidget);
      expect(find.text('Default share hashtags & attribution'), findsOneWidget);
    });
  });
}
