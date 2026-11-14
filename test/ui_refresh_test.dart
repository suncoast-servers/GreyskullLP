import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/home_page.dart';
import 'package:greyskull_lp/pages/settings/appearance_settings_page.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
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
              GsTabItem(svg: 'train', label: 'Workout'),
              GsTabItem(svg: 'forum', label: 'Forum'),
              GsTabItem(svg: 'food', label: 'Diet'),
              GsTabItem(svg: 'stats', label: 'Stats'),
              GsTabItem(svg: 'history', label: 'History'),
              GsTabItem(svg: 'store', label: 'Store'),
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

  group('Workout dock components', () {
    testWidgets('GsSetRow shows weight, reps, AMRAP and reports taps',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          GsSetRow(
            weightLabel: '100 lb',
            repsLabel: '5',
            isDone: false,
            isAmrap: true,
            onTap: () => taps++,
            onLongPress: () {},
          ),
        ),
      );

      expect(find.text('100 lb'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('AMRAP'), findsOneWidget);

      await tester.tap(find.text('100 lb'));
      expect(taps, 1);
    });

    testWidgets('GsStickyDock renders its child', (tester) async {
      await tester.pumpWidget(
        _app(
          const GsStickyDock(child: Text('Rest dock')),
        ),
      );

      expect(find.text('Rest dock'), findsOneWidget);
    });
  });

  group('SVG icon set', () {
    test('icons used by the refreshed shell exist as assets', () {
      for (final name in <String>[
        'train',
        'forum',
        'food',
        'stats',
        'history',
        'store',
        'gear',
        'more',
        'flame',
        'check',
        'play',
        'chevron',
        'db',
        'repeat',
        'ladder',
        'lock',
        'target',
        'reorder',
        'bolt',
      ]) {
        expect(
          File('assets/icons/$name.svg').existsSync(),
          isTrue,
          reason: 'missing icon asset: $name',
        );
      }
    });

    testWidgets('GsIcon renders a tinted SVG', (tester) async {
      await tester.pumpWidget(_app(const GsIcon('flame', size: 24)));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
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

  group('Settings hub', () {
    testWidgets('groups settings into sub-pages and opens appearance',
        (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeFor(GreyskullSkin.ironAndBone),
          home: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      for (final row in <String>[
        'Appearance & themes',
        'Program & level',
        'Training preferences',
        'Barbell program',
        'Accessories',
        'Sharing & accountability',
        'Timing & alerts',
        'Backup & data',
        'Help & tutorials',
      ]) {
        expect(find.text(row), findsOneWidget, reason: row);
      }

      await tester.tap(find.text('Appearance & themes'));
      await tester.pumpAndSettle();

      expect(find.byType(AppearanceSettingsPage), findsOneWidget);
      expect(find.text('Theme & Skins (Greyskull Motif)'), findsOneWidget);
    });
  });
}
