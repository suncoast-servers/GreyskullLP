import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greyskull_lp/themes/theme.dart';

/// Issue #105: accents must not resolve to unrelated blue or green. The
/// approved UI refresh gives Skeletor Havoc its signature violet (hue ≈ 262),
/// so the forbidden band stops before violet; blue (~180–240) and green
/// (~80–160) are still rejected.
void main() {
  for (final skin in GreyskullSkin.values) {
    testWidgets('${skin.name} accents stay off blue and green', (tester) async {
      late Color resistance;
      late Color positive;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeFor(skin),
          home: Builder(
            builder: (context) {
              resistance = AppTheme.resistanceAccent(context);
              positive = AppTheme.positiveAccent(context);
              return const SizedBox();
            },
          ),
        ),
      );

      for (final colour in [resistance, positive]) {
        final hsv = HSVColor.fromColor(colour);
        final offMotif = hsv.saturation > 0.2 && hsv.hue > 80 && hsv.hue < 250;
        expect(offMotif, isFalse,
            reason: '${skin.name} accent $colour is blue/green');
      }
    });
  }
}
