import 'package:flutter/material.dart';

/// Font families bundled with the app for the Greyskull UI refresh.
///
/// The families match the approved design prototype:
/// * [display] — condensed headings, ranks and large numerals.
/// * [body] — all reading text and controls.
/// * [mono] — weights, reps, timers and tabular numerals.
abstract final class GsFont {
  static const String display = 'BarlowCondensed';
  static const String body = 'Inter';
  static const String mono = 'JetBrainsMono';
}

/// Design tokens lifted from the approved UI prototype.
///
/// Field names intentionally mirror the prototype's CSS variables so screens
/// can be ported without re-mapping colours. [bone] is the primary foreground
/// colour (it is near-black in the daylight skin), matching the prototype's
/// `--bone` usage.
@immutable
class GsTokens extends ThemeExtension<GsTokens> {
  const GsTokens({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.bone,
    required this.muted,
    required this.accent,
    required this.accent2,
    required this.accentInk,
    required this.ok,
    required this.danger,
    this.cardRadius = 18,
    this.controlRadius = 13,
    this.smallRadius = 10,
    this.tagRadius = 7,
  });

  /// Page background.
  final Color bg;

  /// Slightly raised background used by the app bar and nav bar.
  final Color bg2;

  /// Card background.
  final Color surface;

  /// Nested/inset surface (set rows, inputs, chips).
  final Color surface2;

  /// Hairline borders and dividers.
  final Color line;

  /// Primary foreground colour.
  final Color bone;

  /// Secondary/muted foreground colour. Meets WCAG AA on cards.
  final Color muted;

  /// Primary accent for actions, active states and highlights.
  final Color accent;

  /// Brighter companion accent for gradients and glows.
  final Color accent2;

  /// Foreground colour used on top of [accent].
  final Color accentInk;

  /// Positive/confirmation colour.
  final Color ok;

  /// Error/destructive colour.
  final Color danger;

  final double cardRadius;
  final double controlRadius;
  final double smallRadius;
  final double tagRadius;

  /// Prototype's signature gold/amethyst/steel gradient.
  LinearGradient get accentGradient => LinearGradient(
        colors: <Color>[accent2, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Scrim used behind modal sheets and dialogs.
  Color get scrim => bg.withValues(alpha: 0.66);

  @override
  GsTokens copyWith({
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? bone,
    Color? muted,
    Color? accent,
    Color? accent2,
    Color? accentInk,
    Color? ok,
    Color? danger,
    double? cardRadius,
    double? controlRadius,
    double? smallRadius,
    double? tagRadius,
  }) {
    return GsTokens(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      bone: bone ?? this.bone,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      accentInk: accentInk ?? this.accentInk,
      ok: ok ?? this.ok,
      danger: danger ?? this.danger,
      cardRadius: cardRadius ?? this.cardRadius,
      controlRadius: controlRadius ?? this.controlRadius,
      smallRadius: smallRadius ?? this.smallRadius,
      tagRadius: tagRadius ?? this.tagRadius,
    );
  }

  @override
  GsTokens lerp(covariant GsTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return GsTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      bone: Color.lerp(bone, other.bone, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      cardRadius: _lerpDouble(cardRadius, other.cardRadius, t),
      controlRadius: _lerpDouble(controlRadius, other.controlRadius, t),
      smallRadius: _lerpDouble(smallRadius, other.smallRadius, t),
      tagRadius: _lerpDouble(tagRadius, other.tagRadius, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Token palettes for the three shipped skins.
///
/// Values are tuned for WCAG AA: [muted] passes 4.5:1 on cards and [danger]
/// passes 4.5:1 on cards in every skin. The daylight accent is darkened from
/// the prototype's decorative gold so it is legible on white.
abstract final class GsPalettes {
  static const GsTokens ironAndBone = GsTokens(
    bg: Color(0xFF0A0B0D),
    bg2: Color(0xFF0F1114),
    surface: Color(0xFF15181C),
    surface2: Color(0xFF1C2027),
    line: Color(0xFF282D35),
    bone: Color(0xFFEFE7D6),
    muted: Color(0xFF7E8792),
    accent: Color(0xFFC8A02A),
    accent2: Color(0xFFE8C766),
    accentInk: Color(0xFF0A0B0D),
    ok: Color(0xFF4C9F70),
    danger: Color(0xFFE05260),
  );

  static const GsTokens skeletorHavoc = GsTokens(
    bg: Color(0xFF0A0714),
    bg2: Color(0xFF0F0A1D),
    surface: Color(0xFF161029),
    surface2: Color(0xFF1E1636),
    line: Color(0xFF2E2350),
    bone: Color(0xFFEAE4FF),
    muted: Color(0xFF8E82B5),
    accent: Color(0xFF8B5CF6),
    accent2: Color(0xFFC084FC),
    accentInk: Color(0xFF0A0714),
    ok: Color(0xFF3FB6A8),
    danger: Color(0xFFE05260),
  );

  static const GsTokens chalkAndSteel = GsTokens(
    bg: Color(0xFFF5F3EE),
    bg2: Color(0xFFEDEAE3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0EDE6),
    line: Color(0xFFDDD8CC),
    bone: Color(0xFF1A1814),
    muted: Color(0xFF6E6860),
    accent: Color(0xFF8A6A12),
    accent2: Color(0xFFC8A02A),
    accentInk: Color(0xFFFFFFFF),
    ok: Color(0xFF3E8A5A),
    danger: Color(0xFFB4402E),
  );
}

/// Convenience accessor: `context.gs.accent`, `context.gs.surface`, …
extension GsThemeContext on BuildContext {
  GsTokens get gs =>
      Theme.of(this).extension<GsTokens>() ?? GsPalettes.ironAndBone;
}
