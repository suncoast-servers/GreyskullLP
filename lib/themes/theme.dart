import 'package:flutter/material.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';

enum GreyskullSkin {
  ironAndBone(
    displayName: 'Iron & Bone',
    badge: 'Standard',
    subtitle: 'Rugged dark charcoal & bone white',
    description:
        'Johnny Pain’s iconic gym aesthetic: matte iron background, bone-white typography, and amber AMRAP accents.',
    isDark: true,
    bgHex: 0xFF0A0B0D,
    surfaceHex: 0xFF15181C,
    accentHex: 0xFFC8A02A,
  ),
  skeletorHavoc(
    displayName: 'Skeletor Havoc',
    badge: 'Midnight OLED',
    subtitle: 'Brutalist pitch black & stark white',
    description:
        'Pure obsidian monochrome with sharp steel borders and maximum contrast for low-light gym grinding.',
    isDark: true,
    bgHex: 0xFF0A0714,
    surfaceHex: 0xFF161029,
    accentHex: 0xFF8B5CF6,
  ),
  chalkAndSteel(
    displayName: 'Chalk & Steel',
    badge: 'Daylight',
    subtitle: 'Athletic chalk white & slate grey',
    description:
        'High-visibility daylight mode engineered for outdoor training and brightly lit gym floors.',
    isDark: false,
    bgHex: 0xFFF5F3EE,
    surfaceHex: 0xFFFFFFFF,
    accentHex: 0xFF8A6A12,
  );

  final String displayName;
  final String badge;
  final String subtitle;
  final String description;
  final bool isDark;
  final int bgHex;
  final int surfaceHex;
  final int accentHex;

  const GreyskullSkin({
    required this.displayName,
    required this.badge,
    required this.subtitle,
    required this.description,
    required this.isDark,
    required this.bgHex,
    required this.surfaceHex,
    required this.accentHex,
  });
}

class AppTheme {
  // Legacy color constants preserved for backward compatibility.
  static const Color darkBackground = Color(0xFF0A0B0D);
  static const Color darkText = Color(0xFFEFE7D6);
  static const Color lightBackground = Color(0xFFF5F3EE);
  static const Color lightText = Color(0xFF1A1814);
  static const Color appBarColor = Color(0xFFEDEAE3);
  static const Color appBarDarkColor = Color(0xFF0F1114);
  static const Color appBarTextColor = Color(0xFF1A1814);
  static const Color bottomNavBarColor = Color(0xFFEDEAE3);
  static const Color bottomNavDarkColor = Color(0xFF0F1114);
  static const Color bottomNavBarSelectedColor = Color(0xFF1A1814);
  static const Color bottomNavBarUnselectedColor = Color(0xFF7E8792);

  /// Builds a cohesive, rugged, high-contrast [ThemeData] for the requested
  /// [GreyskullSkin]. Colours come from [GsTokens] so screens can consume the
  /// same design language through `context.gs`.
  static ThemeData themeFor(GreyskullSkin skin) {
    switch (skin) {
      case GreyskullSkin.ironAndBone:
        return _buildTheme(skin, GsPalettes.ironAndBone);
      case GreyskullSkin.skeletorHavoc:
        return _buildTheme(skin, GsPalettes.skeletorHavoc);
      case GreyskullSkin.chalkAndSteel:
        return _buildTheme(skin, GsPalettes.chalkAndSteel);
    }
  }

  /// Tokens for [skin] without building a whole [ThemeData].
  static GsTokens tokensFor(GreyskullSkin skin) {
    switch (skin) {
      case GreyskullSkin.ironAndBone:
        return GsPalettes.ironAndBone;
      case GreyskullSkin.skeletorHavoc:
        return GsPalettes.skeletorHavoc;
      case GreyskullSkin.chalkAndSteel:
        return GsPalettes.chalkAndSteel;
    }
  }

  static ThemeData _buildTheme(GreyskullSkin skin, GsTokens t) {
    final bool isDark = skin.isDark;

    // Dark skins use the accent as the primary ink so icons and active states
    // read gold/amethyst. The daylight skin keeps near-black primary ink for
    // AA contrast on white; the accent carries the highlights instead.
    final Color primary = isDark ? t.accent : t.bone;
    final Color onPrimary = isDark ? t.accentInk : Colors.white;
    final Color buttonForeground = isDark ? t.accentInk : Colors.white;
    final Color navSelected = isDark ? t.accent : t.bone;

    final TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: t.bone,
      ),
      displayMedium: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: t.bone,
      ),
      displaySmall: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: t.bone,
      ),
      headlineLarge: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: t.bone,
      ),
      headlineMedium: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 23,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: t.bone,
      ),
      headlineSmall: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: t.bone,
      ),
      titleLarge: TextStyle(
        fontFamily: GsFont.display,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: t.bone,
      ),
      titleMedium: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: t.bone,
      ),
      titleSmall: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.bone,
      ),
      bodyLarge: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 16,
        height: 1.45,
        color: t.bone,
      ),
      bodyMedium: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 14,
        height: 1.45,
        color: t.bone,
      ),
      bodySmall: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 12,
        height: 1.4,
        color: t.muted,
      ),
      labelLarge: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: t.bone,
      ),
      labelMedium: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: t.muted,
      ),
      labelSmall: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: t.muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: GsFont.body,
      scaffoldBackgroundColor: t.bg,
      primaryColor: t.accent,
      cardColor: t.surface,
      dividerColor: t.line,
      splashColor: t.accent.withValues(alpha: 0.12),
      highlightColor: t.accent.withValues(alpha: 0.08),
      extensions: <ThemeExtension<dynamic>>[t],
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: t.surface2,
        onPrimaryContainer: t.bone,
        secondary: t.accent,
        onSecondary: buttonForeground,
        secondaryContainer: t.accent.withValues(alpha: 0.16),
        onSecondaryContainer: t.bone,
        tertiary: t.ok,
        onTertiary: isDark ? t.accentInk : Colors.white,
        surface: t.surface,
        onSurface: t.bone,
        surfaceContainerHighest: t.surface2,
        onSurfaceVariant: t.muted,
        outline: t.line,
        outlineVariant: t.line,
        error: t.danger,
        onError: Colors.white,
        shadow: Colors.black,
        scrim: t.scrim,
        inverseSurface: t.bone,
        onInverseSurface: t.bg,
        inversePrimary: t.accent2,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg2,
        foregroundColor: t.bone,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: GsFont.display,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: t.bone,
        ),
        iconTheme: IconThemeData(color: t.bone),
        actionsIconTheme: IconThemeData(color: t.bone),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.bg2,
        selectedItemColor: navSelected,
        unselectedItemColor: t.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.cardRadius),
          side: BorderSide(color: t.line, width: 1),
        ),
      ),
      iconTheme: IconThemeData(color: t.bone),
      dividerTheme: DividerThemeData(color: t.line, thickness: 1),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: t.surface2,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: t.muted,
        ),
        hintStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 13,
          color: t.muted,
        ),
        prefixIconColor: t.muted,
        suffixIconColor: t.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.controlRadius),
          borderSide: BorderSide(color: t.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.controlRadius),
          borderSide: BorderSide(color: t.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.controlRadius),
          borderSide: BorderSide(color: t.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.controlRadius),
          borderSide: BorderSide(color: t.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.controlRadius),
          borderSide: BorderSide(color: t.danger, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: t.line, width: 1),
        ),
        titleTextStyle: TextStyle(
          fontFamily: GsFont.display,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: t.bone,
        ),
        contentTextStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 14,
          height: 1.5,
          color: t.muted,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        modalBackgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: t.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surface2,
        contentTextStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: t.bone,
        ),
        actionTextColor: t.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.smallRadius + 2),
          side: BorderSide(color: t.line, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: buttonForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.controlRadius),
          ),
          textStyle: TextStyle(
            fontFamily: GsFont.body,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.bone,
          side: BorderSide(color: t.line, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.controlRadius),
          ),
          textStyle: TextStyle(
            fontFamily: GsFont.body,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accent,
          textStyle: TextStyle(
            fontFamily: GsFont.body,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface2,
        selectedColor: t.accent.withValues(alpha: 0.16),
        disabledColor: t.surface2,
        side: BorderSide(color: t.line, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.tagRadius + 2),
        ),
        labelStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.bone,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: t.accent,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected) ? t.accent : t.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? t.accent.withValues(alpha: 0.35)
              : t.surface2;
        }),
        trackOutlineColor: WidgetStatePropertyAll<Color>(t.line),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected) ? t.accent : t.muted;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? t.accent
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color>(
          isDark ? t.accentInk : Colors.white,
        ),
        side: BorderSide(color: t.line, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.surface2,
        circularTrackColor: t.surface2,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.accent,
        titleTextStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: t.bone,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: GsFont.body,
          fontSize: 12,
          height: 1.4,
          color: t.muted,
        ),
      ),
    );
  }

  /// Muted/secondary foreground that stays legible on every skin.
  static Color mutedText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Subtle track/fill colour for progress bars and chips.
  static Color subtleFill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.onSurface.withValues(alpha: 0.16);
  }

  /// Accent colours for analytics and status surfaces.
  ///
  /// Completed/positive states use the skin's gold (secondary) so the
  /// interface stays on the Greyskull motif (issue #105).
  static Color positiveAccent(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  static Color negativeAccent(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// Resistance surfaces use the skin's primary ink instead of blue (#105).
  static Color resistanceAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color calisthenicsAccent(BuildContext context) => _accent(context,
      light: const Color(0xFFE65100), dark: const Color(0xFFFFB74D));

  static Color _accent(BuildContext context,
          {required Color light, required Color dark}) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // Pre-built default themes
  static final ThemeData lightTheme = themeFor(GreyskullSkin.chalkAndSteel);
  static final ThemeData darkTheme = themeFor(GreyskullSkin.ironAndBone);
}
