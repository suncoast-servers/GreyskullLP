import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/pages/stats_page.dart';
import 'package:greyskull_lp/themes/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Stats resistance icon (issue #54)', () {
    testWidgets('uses the shared Workout barbell glyph, not fitness_center',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatsPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resistance'), findsOneWidget);
      expect(find.byIcon(AppIcons.barbell), findsWidgets);
      // The third-party-looking dumbbell glyph must not appear on Stats.
      expect(find.byIcon(Icons.fitness_center), findsNothing);

      // The Workout nav and Stats now point at the same glyph definition.
      expect(AppIcons.barbell.fontFamily, 'MaterialSymbols');
      expect(AppIcons.barbell.codePoint, 0xf6e6);
    });
  });
}
