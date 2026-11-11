import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/pages/store_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Storefront State & URL configuration in TrainingState', () {
    test('defaults to official Greyskull Nation store URL', () {
      expect(
        trainingState.storeUrl,
        equals('https://store.greyskullnation.com/'),
      );
      expect(
        TrainingState.defaultStoreUrl,
        equals('https://store.greyskullnation.com/'),
      );
    });

    test('updates custom store URL and resets to default', () {
      trainingState.setStoreUrl('https://custom-shop.example.com');
      expect(trainingState.storeUrl, equals('https://custom-shop.example.com'));

      trainingState.resetStoreUrlToDefault();
      expect(
        trainingState.storeUrl,
        equals(TrainingState.defaultStoreUrl),
      );
    });
  });

  group('StorePage interactive widget flows', () {
    testWidgets('renders Greyskull Store header and launch button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StorePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Greyskull Store'), findsOneWidget);
      expect(find.text('Open Greyskull Store'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(
        find.textContaining('https://store.greyskullnation.com/'),
        findsOneWidget,
      );
    });

    testWidgets('SettingsPage allows resetting store URL to default',
        (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      trainingState.setStoreUrl('https://altered-store.com');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      final resetButton = find.text('Reset Store URL to Default');
      expect(resetButton, findsOneWidget);

      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(
        trainingState.storeUrl,
        equals(TrainingState.defaultStoreUrl),
      );
    });
  });
}
