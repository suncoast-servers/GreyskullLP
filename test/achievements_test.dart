import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/models/accountability_post.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/achievements_page.dart';
import 'package:greyskull_lp/pages/home_page.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.themeFor(GreyskullSkin.ironAndBone),
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    trainingState.setAccountabilityMode(AccountabilityPostMode.off);
    for (final entry in trainingState.history.toList()) {
      trainingState.deleteHistoryEntry(entry.id);
    }
  });

  testWidgets('Home shows four featured badges and opens a detail sheet',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _app(Scaffold(body: HomePage(onItemSelected: (_) {}))),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('All badges'), findsOneWidget);
    expect(find.text('7-DAY STREAK'), findsOneWidget);
    expect(find.text('IRON MONARCH'), findsOneWidget);
    expect(find.text('SESSION VET'), findsOneWidget);
    expect(find.text('AMRAP HUNTER'), findsOneWidget);

    await tester.tap(find.text('7-DAY STREAK'));
    await tester.pumpAndSettle();

    expect(find.text('CURRENT'), findsOneWidget);
    expect(find.textContaining('Bronze'), findsOneWidget);
  });

  testWidgets('Achievements page lists all real badges and unlocks First Rep',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    trainingState.logWeightSession(
      coreLiftSummary: 'Squat 100 lbs x 5',
      optionalExerciseSummary: 'None',
      volume: 1500,
    );

    await tester.pumpWidget(_app(const AchievementsPage()));
    await tester.pumpAndSettle();

    expect(find.text('FIRST REP'), findsOneWidget);
    expect(find.text('SESSION VET'), findsOneWidget);
    expect(find.text('VOLUME KING'), findsOneWidget);
    expect(find.text('1 of 6 unlocked'), findsOneWidget);

    await tester.tap(find.text('FIRST REP'));
    await tester.pumpAndSettle();

    expect(find.text('CURRENT'), findsOneWidget);
    expect(find.text('EARNED'), findsWidgets);
  });
}
