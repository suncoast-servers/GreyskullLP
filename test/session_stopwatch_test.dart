import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/pages/workout_page_weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _setCircles() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('set-tap-'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session stopwatch', () {
    testWidgets('starts with the first completed set and ticks',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WorkoutPageWeight())),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Session 00:'), findsNothing);

      await tester.tap(_setCircles().first);
      await tester.pump();

      expect(find.textContaining('Session 00:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('Session 00:02'), findsOneWidget);
    });
  });
}
