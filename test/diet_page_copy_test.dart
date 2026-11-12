import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/pages/diet_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Diet page production copy (issue #53)', () {
    testWidgets('shows user-facing copy only, no roadmap/placeholder text',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DietPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diet Tracker'), findsOneWidget);
      expect(find.text('Search Foods'), findsOneWidget);

      // Dev-suggestion / roadmap copy must not reach end users.
      expect(find.text('Future Integration Idea'), findsNothing);
      expect(
        find.textContaining('You can integrate a free open-food database'),
        findsNothing,
      );
      expect(find.textContaining('USDA'), findsNothing);
      expect(find.textContaining('Settings'), findsNothing);
    });
  });
}
