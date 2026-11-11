import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? mockClipboardText;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  group('Backup & Export JSON Architecture', () {
    test('exports full state payload with schema version and training data',
        () {
      final payload = trainingState.exportBackupJson();

      expect(payload, contains('"schemaVersion":2'));
      expect(payload, contains('"dailyPushUpTarget":'));
      expect(payload, contains('"dailyChinUpTarget":'));
      expect(payload, contains('"history":'));
      expect(payload, contains('"selectedWeightOptionalExercises":'));
    });

    test('imports valid backup JSON and replaces training state cleanly',
        () async {
      const backupJson = '''
{
  "schemaVersion": 1,
  "activeDailyMethod": "ladder",
  "nutritionMode": "bulking",
  "backupPreference": "manualExport",
  "dailyPushUpTarget": 75,
  "dailyChinUpTarget": 35,
  "dailyProteinTarget": 200,
  "dailyCalorieTarget": 3000,
  "selectedWeightOptionalExercises": ["Deadlift", "Split Squat"],
  "selectedDailyOptionalExercises": ["Dips"],
  "history": []
}
''';

      final success = await trainingState.importBackupJson(backupJson);
      expect(success, isTrue);
      expect(trainingState.activeDailyMethod, equals(DailyMethod.ladder));
      expect(trainingState.nutritionMode, equals(NutritionMode.bulking));
      expect(trainingState.dailyPushUpTarget, equals(75));
      expect(trainingState.dailyChinUpTarget, equals(35));
      expect(trainingState.dailyProteinTarget, equals(200));
      expect(trainingState.dailyCalorieTarget, equals(3000));
      expect(trainingState.selectedWeightOptionalExercises,
          containsAll(['Deadlift', 'Split Squat']));
    });

    test('gracefully rejects corrupted or empty backup JSON without crashing',
        () async {
      final emptyResult = await trainingState.importBackupJson('');
      expect(emptyResult, isFalse);

      final corruptedResult =
          await trainingState.importBackupJson('{not: valid json');
      expect(corruptedResult, isFalse);
    });
  });

  group('SettingsPage Backup UX & Privacy Transparency', () {
    testWidgets(
        'renders Privacy & Data Ownership banner and local storage disclosures',
        (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data Ownership'), findsOneWidget);
      expect(
        find.textContaining('100% local-first and open-source'),
        findsOneWidget,
      );
      expect(
        find.textContaining('We do not track, profile, monetize, or harvest'),
        findsOneWidget,
      );
      expect(find.text('Share File'), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);
    });

    testWidgets(
        'Copy JSON button copies backup payload to clipboard with feedback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy JSON'));
      await tester.pumpAndSettle();

      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText, contains('"schemaVersion":2'));
      expect(find.text('Backup JSON copied to clipboard!'), findsOneWidget);
    });
  });
}
