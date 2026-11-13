import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform smoke test used for the #58 review pass (iOS simulator + Android).
///
/// Deep route coverage lives in the widget/unit suites and the Android device
/// pass; this verifies that the real app boots on a platform, renders the main
/// menu, and opens Settings without crashing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots and renders the main menu on this platform',
      (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Official Greyskull LP App'), findsOneWidget);
    for (final tile in [
      'Workout',
      'Forum',
      'Diet',
      'Stats',
      'History',
      'Store',
    ]) {
      expect(find.text(tile), findsWidgets, reason: 'menu tile: $tile');
    }

    // Settings opens (theme list is the first section).
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Theme & Skins (Greyskull Motif)'), findsOneWidget);
  });
}
