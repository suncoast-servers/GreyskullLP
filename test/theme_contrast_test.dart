import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  group('Theme contrast audit (issue #46)', () {
    for (final skin in GreyskullSkin.values) {
      final theme = AppTheme.themeFor(skin);
      final scheme = theme.colorScheme;
      final card = theme.cardColor;
      final nav = theme.bottomNavigationBarTheme;

      test('${skin.displayName}: text meets WCAG AA on cards', () {
        expect(
          _contrast(scheme.onSurface, card),
          greaterThanOrEqualTo(4.5),
          reason: 'Primary text on card background',
        );
        expect(
          _contrast(scheme.onSurfaceVariant, card),
          greaterThanOrEqualTo(4.5),
          reason: 'Muted/secondary text on card background',
        );
        expect(
          _contrast(theme.textTheme.bodySmall!.color!, card),
          greaterThanOrEqualTo(4.5),
          reason: 'bodySmall text on card background',
        );
        expect(
          _contrast(scheme.onSurface, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
          reason: 'Primary text on page background',
        );
      });

      test('${skin.displayName}: buttons, nav and status colours are legible',
          () {
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: 'Elevated button label',
        );
        expect(
          _contrast(nav.selectedItemColor!, nav.backgroundColor!),
          greaterThanOrEqualTo(4.5),
          reason: 'Selected bottom-nav item',
        );
        expect(
          _contrast(nav.unselectedItemColor!, nav.backgroundColor!),
          greaterThanOrEqualTo(4.5),
          reason: 'Unselected bottom-nav item',
        );
        expect(
          _contrast(scheme.error, card),
          greaterThanOrEqualTo(4.5),
          reason: 'Error text on cards',
        );
      });
    }

    test('muted text helper never falls back to hardcoded grey', () {
      // Sanity check that each skin exposes a distinct muted tone.
      final muted = GreyskullSkin.values
          .map((skin) => AppTheme.themeFor(skin).colorScheme.onSurfaceVariant)
          .toSet();
      expect(muted.length, GreyskullSkin.values.length);
    });
  });
}
