import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/pages/interval_timer_page.dart';
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

  group('Interval timer (issue #75)', () {
    testWidgets('runs prep, work and rest phases', (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: IntervalTimerPage()));
      await tester.pumpAndSettle();

      expect(find.text('40 / 20'), findsOneWidget);
      expect(find.text('work / rest'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(find.text('Get ready'), findsOneWidget);
      expect(find.text('0:05'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('0:40'), findsOneWidget);
      expect(find.text('Round 1 of 8'), findsOneWidget);

      await tester.pump(const Duration(seconds: 40));
      expect(find.text('0:20'), findsOneWidget);

      // Pause freezes the clock.
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('0:20'), findsOneWidget);
    });

    testWidgets('stop returns to the idle state', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IntervalTimerPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('work / rest'), findsOneWidget);
    });
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
