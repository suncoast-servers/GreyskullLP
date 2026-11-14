import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/home_page.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) {
  return MaterialApp(
    theme: AppTheme.themeFor(GreyskullSkin.ironAndBone),
    home: Scaffold(body: home),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('UI refresh components', () {
    testWidgets('GsCard renders its child and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          GsCard(
            onTap: () => taps++,
            child: const Text('Card body'),
          ),
        ),
      );

      expect(find.text('Card body'), findsOneWidget);
      await tester.tap(find.text('Card body'));
      expect(taps, 1);
    });

    testWidgets('GsTag renders its label and icon', (tester) async {
      await tester.pumpWidget(
        _app(
          const GsTag(
            'ACTIVE',
            tone: GsTagTone.ok,
            icon: Icons.check,
          ),
        ),
      );

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('GsTabBar renders six destinations and reports selection',
        (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        _app(
          GsTabBar(
            items: const <GsTabItem>[
              GsTabItem(icon: Icons.fitness_center, label: 'Workout'),
              GsTabItem(icon: Icons.forum, label: 'Forum'),
              GsTabItem(icon: Icons.restaurant, label: 'Diet'),
              GsTabItem(icon: Icons.stacked_line_chart, label: 'Stats'),
              GsTabItem(icon: Icons.history, label: 'History'),
              GsTabItem(icon: Icons.shopping_cart, label: 'Store'),
            ],
            currentIndex: 0,
            onTap: (index) => selected = index,
          ),
        ),
      );

      for (final label in <String>[
        'WORKOUT',
        'FORUM',
        'DIET',
        'STATS',
        'HISTORY',
        'STORE',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('STATS'));
      expect(selected, 3);
    });
  });

  group('Home dashboard', () {
    testWidgets('keeps all existing destinations and the start action',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final taps = <int>[];
      await tester.pumpWidget(
        _app(HomePage(onItemSelected: taps.add)),
      );

      expect(find.text('Start Workout'), findsOneWidget);

      for (final tile in <String>[
        'Workout',
        'Forum',
        'Diet',
        'Stats',
        'History',
        'Store',
      ]) {
        expect(find.text(tile), findsOneWidget, reason: 'tile: $tile');
      }

      await tester.tap(find.text('Workout'));
      expect(taps, <int>[0]);
    });

    testWidgets('shows the active program and today\'s rotation',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _app(HomePage(onItemSelected: (_) {})),
      );

      expect(find.text(trainingState.programLevel.displayName), findsOneWidget);
      expect(find.text(trainingState.currentTemplateWorkout.title),
          findsOneWidget);
      expect(
        find.text(TrainingState.methodLabel(trainingState.activeDailyMethod)),
        findsOneWidget,
      );
    });
  });
}
