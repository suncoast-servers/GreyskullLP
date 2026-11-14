import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Design tokens (UI refresh, phase 1)', () {
    test('every skin exposes a complete token palette', () {
      for (final skin in GreyskullSkin.values) {
        final tokens = AppTheme.tokensFor(skin);
        expect(tokens.bg, isNot(equals(tokens.surface)),
            reason: '${skin.name}: page and card backgrounds must differ');
        expect(tokens.surface, isNot(equals(tokens.surface2)),
            reason: '${skin.name}: card and inset surfaces must differ');
        expect(tokens.bone, isNot(equals(tokens.muted)),
            reason: '${skin.name}: primary and muted text must differ');
        expect(tokens.accent, isNot(equals(tokens.accentInk)),
            reason: '${skin.name}: accent must contrast with accent ink');
        expect(tokens.accentGradient.colors, <Color>[
          tokens.accent2,
          tokens.accent,
        ]);
        expect(tokens.cardRadius, greaterThan(tokens.smallRadius));
      }
    });

    test('themeFor embeds the palette as a ThemeExtension', () {
      for (final skin in GreyskullSkin.values) {
        final theme = AppTheme.themeFor(skin);
        final embedded = theme.extension<GsTokens>();
        expect(embedded, isNotNull, reason: '${skin.name} is missing tokens');
        expect(embedded, equals(AppTheme.tokensFor(skin)));
      }
    });

    test('typography uses the bundled display, body and mono families', () {
      for (final skin in GreyskullSkin.values) {
        final theme = AppTheme.themeFor(skin);
        expect(theme.textTheme.bodyMedium?.fontFamily, GsFont.body);
        expect(theme.textTheme.titleMedium?.fontFamily, GsFont.body);
        expect(theme.textTheme.displayLarge?.fontFamily, GsFont.display);
        expect(theme.textTheme.titleLarge?.fontFamily, GsFont.display);
        expect(theme.appBarTheme.titleTextStyle?.fontFamily, GsFont.display);
      }
    });

    test('token text colours meet WCAG AA on cards and the page', () {
      for (final skin in GreyskullSkin.values) {
        final tokens = AppTheme.tokensFor(skin);
        expect(
          _contrast(tokens.bone, tokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.name}: primary text on cards',
        );
        expect(
          _contrast(tokens.muted, tokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.name}: muted text on cards',
        );
        expect(
          _contrast(tokens.bone, tokens.bg),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.name}: primary text on the page',
        );
        expect(
          _contrast(tokens.danger, tokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.name}: destructive text on cards',
        );
      }
    });

    test('copyWith and lerp keep the token contract', () {
      const iron = GsPalettes.ironAndBone;
      final copied = iron.copyWith(accent: const Color(0xFF123456));
      expect(copied.accent, const Color(0xFF123456));
      expect(copied.bg, iron.bg);

      final halfway = iron.lerp(GsPalettes.chalkAndSteel, 0.5);
      expect(halfway.bg, Color.lerp(iron.bg, GsPalettes.chalkAndSteel.bg, 0.5));
      expect(halfway.cardRadius, iron.cardRadius);
    });

    testWidgets('context.gs resolves the active skin tokens', (tester) async {
      late GsTokens read;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeFor(GreyskullSkin.skeletorHavoc),
          home: Builder(
            builder: (context) {
              read = context.gs;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(read, equals(GsPalettes.skeletorHavoc));
    });
  });
}
