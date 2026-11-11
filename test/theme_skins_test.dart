import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/main.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/themes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    trainingState.setActiveSkin(GreyskullSkin.ironAndBone);
  });

  group('Greyskull Skins - Unit tests', () {
    test('defines 3 distinct on-brand skins with dark/light classification',
        () {
      expect(GreyskullSkin.values.length, equals(3));
      expect(GreyskullSkin.ironAndBone.isDark, isTrue);
      expect(GreyskullSkin.skeletorHavoc.isDark, isTrue);
      expect(GreyskullSkin.chalkAndSteel.isDark, isFalse);
    });

    test(
        'themeFor generates valid ThemeData for each skin with appropriate brightness',
        () {
      final ironTheme = AppTheme.themeFor(GreyskullSkin.ironAndBone);
      expect(ironTheme.brightness, equals(Brightness.dark));
      expect(
          ironTheme.scaffoldBackgroundColor, equals(const Color(0xFF141414)));

      final havocTheme = AppTheme.themeFor(GreyskullSkin.skeletorHavoc);
      expect(havocTheme.brightness, equals(Brightness.dark));
      expect(
          havocTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));

      final chalkTheme = AppTheme.themeFor(GreyskullSkin.chalkAndSteel);
      expect(chalkTheme.brightness, equals(Brightness.light));
      expect(
          chalkTheme.scaffoldBackgroundColor, equals(const Color(0xFFF6F7F9)));
    });

    test('trainingState defaults to Iron & Bone and updates activeSkin', () {
      expect(trainingState.activeSkin, equals(GreyskullSkin.ironAndBone));

      trainingState.setActiveSkin(GreyskullSkin.skeletorHavoc);
      expect(trainingState.activeSkin, equals(GreyskullSkin.skeletorHavoc));

      trainingState.setActiveSkin(GreyskullSkin.chalkAndSteel);
      expect(trainingState.activeSkin, equals(GreyskullSkin.chalkAndSteel));
    });

    test('backup payload serializes and restores activeSkin', () async {
      trainingState.setActiveSkin(GreyskullSkin.skeletorHavoc);
      final jsonStr = trainingState.exportBackupJson();

      expect(jsonStr, contains('"activeSkin":"skeletorHavoc"'));

      trainingState.setActiveSkin(GreyskullSkin.ironAndBone);
      expect(trainingState.activeSkin, equals(GreyskullSkin.ironAndBone));

      final success = await trainingState.importBackupJson(jsonStr);
      expect(success, isTrue);
      expect(trainingState.activeSkin, equals(GreyskullSkin.skeletorHavoc));
    });
  });

  group('Greyskull Skins - Widget tests', () {
    testWidgets('settings page displays 3 skin proposals with visual swatches',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Theme & Skins (Greyskull Motif)'), findsOneWidget);
      expect(find.text('Iron & Bone'), findsOneWidget);
      expect(find.text('Skeletor Havoc'), findsOneWidget);
      expect(find.text('Chalk & Steel'), findsOneWidget);

      // Tap Skeletor Havoc
      await tester.tap(find.text('Skeletor Havoc'));
      await tester.pumpAndSettle();

      expect(trainingState.activeSkin, equals(GreyskullSkin.skeletorHavoc));

      // Tap Chalk & Steel
      await tester.tap(find.text('Chalk & Steel'));
      await tester.pumpAndSettle();

      expect(trainingState.activeSkin, equals(GreyskullSkin.chalkAndSteel));
    });

    testWidgets('GreyskullApp dynamically re-themes when skin is changed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const GreyskullApp());
      await tester.pump();

      // Starts in Iron & Bone (Dark mode)
      MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.brightness, equals(Brightness.dark));
      expect(
          app.theme?.scaffoldBackgroundColor, equals(const Color(0xFF141414)));

      // Switch to Chalk & Steel (Daylight / Light mode)
      trainingState.setActiveSkin(GreyskullSkin.chalkAndSteel);
      await tester.pump();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.brightness, equals(Brightness.light));
      expect(
          app.theme?.scaffoldBackgroundColor, equals(const Color(0xFFF6F7F9)));
    });
  });
}
