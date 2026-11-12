import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/forum_page.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Forum State & URL configuration in TrainingState', () {
    test('defaults to official Greyskull Nation forum URLs', () {
      expect(
        trainingState.forumUrl,
        equals(TrainingState.defaultForumUrl),
      );
      expect(
        trainingState.forumLoginUrl,
        equals(TrainingState.defaultForumLoginUrl),
      );
    });

    test('updates custom forum URLs and resets to default', () {
      trainingState.setForumUrl('https://custom-forum.example.com');
      trainingState.setForumLoginUrl('https://custom-forum.example.com/login');

      expect(
        trainingState.forumUrl,
        equals('https://custom-forum.example.com'),
      );
      expect(
        trainingState.forumLoginUrl,
        equals('https://custom-forum.example.com/login'),
      );

      trainingState.resetForumUrlsToDefault();
      expect(
        trainingState.forumUrl,
        equals(TrainingState.defaultForumUrl),
      );
      expect(
        trainingState.forumLoginUrl,
        equals(TrainingState.defaultForumLoginUrl),
      );
    });

    test('migrates legacy 404 forum URLs on disk load', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'greyskull_training_state_v1',
        '{"forumUrl": "https://greyskullnation.com/forum"}',
      );

      await trainingState.loadFromDisk();

      expect(
        trainingState.forumUrl,
        equals(TrainingState.defaultForumUrl),
      );
    });

    test('tracks forum authentication state and display name', () {
      expect(trainingState.forumSignedIn, isFalse);

      trainingState.setForumSignedIn(
        signedIn: true,
        displayName: 'IronSkeletor',
      );
      expect(trainingState.forumSignedIn, isTrue);
      expect(trainingState.forumDisplayName, equals('IronSkeletor'));

      trainingState.setForumSignedIn(signedIn: false);
      expect(trainingState.forumSignedIn, isFalse);
      expect(trainingState.forumDisplayName, isEmpty);
    });
  });

  group('ForumPage interactive widget flows', () {
    testWidgets('renders Greyskull Nation Forum header and launch buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ForumPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Greyskull Nation Forum'), findsOneWidget);
      expect(find.text('Open Forum'), findsOneWidget);
      expect(find.text('Forum Login / Register'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(
        find.textContaining('https://forum.greyskullnation.com/'),
        findsOneWidget,
      );
    });

    testWidgets('SettingsPage hides production-irrelevant forum integration',
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

      // Issue #47: forum/store/USDA integration blocks are no longer shipped.
      expect(find.text('Forum Integration (WordPress)'), findsNothing);
      expect(find.text('Forum URL'), findsNothing);
      expect(find.text('Reset Forum URLs to Default'), findsNothing);
      expect(find.text('Store Integration'), findsNothing);
      expect(find.text('Free Calorie Data API'), findsNothing);

      // Defaults still back the in-app forum/store pages.
      expect(TrainingState.defaultForumUrl, isNotEmpty);
      expect(TrainingState.defaultStoreUrl, isNotEmpty);
    });
  });
}
