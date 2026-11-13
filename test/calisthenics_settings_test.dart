import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.frequency);
    trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.ladder);
    trainingState.resetCalisthenicsAccessoriesToDefault(DailyMethod.totalWork);
  });

  testWidgets('settings hosts accessory configuration for every method',
      (tester) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Calisthenics Accessories'), findsOneWidget);
    // Defaults for the three methods are listed here, not on the workout pages.
    expect(find.text('Dips'), findsWidgets);
    expect(find.text('Inverted Rows'), findsOneWidget);
    expect(find.text('Planks'), findsWidgets);
  });
}
