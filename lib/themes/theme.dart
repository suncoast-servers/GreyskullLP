import 'package:flutter/material.dart';

enum GreyskullSkin {
  ironAndBone(
    displayName: 'Iron & Bone',
    badge: 'Standard',
    subtitle: 'Rugged dark charcoal & bone white',
    description:
        'Johnny Pain’s iconic gym aesthetic: matte iron background, bone-white typography, and amber AMRAP accents.',
    isDark: true,
    bgHex: 0xFF141414,
    surfaceHex: 0xFF1F1F1F,
    accentHex: 0xFFFFB300,
  ),
  skeletorHavoc(
    displayName: 'Skeletor Havoc',
    badge: 'Midnight OLED',
    subtitle: 'Brutalist pitch black & stark white',
    description:
        'Pure obsidian monochrome with sharp steel borders and maximum contrast for low-light gym grinding.',
    isDark: true,
    bgHex: 0xFF000000,
    surfaceHex: 0xFF121212,
    accentHex: 0xFF8E8E93,
  ),
  chalkAndSteel(
    displayName: 'Chalk & Steel',
    badge: 'Daylight',
    subtitle: 'Athletic chalk white & slate grey',
    description:
        'High-visibility daylight mode engineered for outdoor training and brightly lit gym floors.',
    isDark: false,
    bgHex: 0xFFF6F7F9,
    surfaceHex: 0xFFFFFFFF,
    accentHex: 0xFF4A4A4A,
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
  // Legacy color constants preserved for backward compatibility
  static const Color darkBackground = Color(0xFF141414);
  static const Color darkText = Color(0xFFF5F5F0);
  static const Color lightBackground = Color(0xFFF6F7F9);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color appBarColor = Color(0xFFE8E9ED);
  static const Color appBarDarkColor = Color(0xFF181818);
  static const Color appBarTextColor = Color(0xFF000000);
  static const Color bottomNavBarColor = Color(0xFFE8E9ED);
  static const Color bottomNavDarkColor = Color(0xFF181818);
  static const Color bottomNavBarSelectedColor = Color(0xFF000000);
  static const Color bottomNavBarUnselectedColor = Color(0xFF757575);

  /// Builds a cohesive, rugged, high-contrast [ThemeData] for the requested [GreyskullSkin].
  static ThemeData themeFor(GreyskullSkin skin) {
    switch (skin) {
      case GreyskullSkin.ironAndBone:
        return _buildIronAndBoneTheme();
      case GreyskullSkin.skeletorHavoc:
        return _buildSkeletorHavocTheme();
      case GreyskullSkin.chalkAndSteel:
        return _buildChalkAndSteelTheme();
    }
  }

  static ThemeData _buildIronAndBoneTheme() {
    const bg = Color(0xFF141414);
    const surface = Color(0xFF1F1F1F);
    const cardBg = Color(0xFF242424);
    const boneWhite = Color(0xFFF5F5F0);
    const mutedBone = Color(0xFFA5A59E);
    const amberAccent = Color(0xFFFFB300);
    const border = Color(0xFF333333);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: boneWhite,
      cardColor: cardBg,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF181818),
        foregroundColor: boneWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: boneWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: boneWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF181818),
        selectedItemColor: amberAccent,
        unselectedItemColor: mutedBone,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: boneWhite,
        onPrimary: Color(0xFF121212),
        secondary: amberAccent,
        onSecondary: Color(0xFF121212),
        surface: surface,
        onSurface: boneWhite,
        error: Color(0xFFCF6679),
        onError: Colors.black,
        outline: border,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: boneWhite),
        bodyMedium: TextStyle(color: boneWhite),
        bodySmall: TextStyle(color: mutedBone),
        titleLarge: TextStyle(color: boneWhite, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: boneWhite, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: boneWhite,
          foregroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: boneWhite,
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData _buildSkeletorHavocTheme() {
    const bg = Color(0xFF000000); // Pure OLED black
    const surface = Color(0xFF0D0D0D);
    const cardBg = Color(0xFF121212);
    const pureWhite = Color(0xFFFFFFFF);
    const coldSteel = Color(0xFF8E8E93);
    const sharpBorder = Color(0xFF2C2C2E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: pureWhite,
      cardColor: cardBg,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: sharpBorder, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: pureWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF080808),
        selectedItemColor: pureWhite,
        unselectedItemColor: coldSteel,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: pureWhite,
        onPrimary: Color(0xFF000000),
        secondary: coldSteel,
        onSecondary: Color(0xFF000000),
        surface: surface,
        onSurface: pureWhite,
        error: Color(0xFFFF453A),
        onError: Colors.black,
        outline: sharpBorder,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: pureWhite),
        bodyMedium: TextStyle(color: pureWhite),
        bodySmall: TextStyle(color: coldSteel),
        titleLarge: TextStyle(color: pureWhite, fontWeight: FontWeight.w900),
        titleMedium: TextStyle(color: pureWhite, fontWeight: FontWeight.bold),
      ),
      dividerTheme: const DividerThemeData(color: sharpBorder, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureWhite,
          foregroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureWhite,
          side: const BorderSide(color: pureWhite, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  static ThemeData _buildChalkAndSteelTheme() {
    const bg = Color(0xFFF6F7F9);
    const surface = Color(0xFFFFFFFF);
    const cardBg = Color(0xFFFFFFFF);
    const charcoal = Color(0xFF1A1A1A);
    const slateMuted = Color(0xFF636366);
    const rawSteel = Color(0xFF4A4A4A);
    const lightBorder = Color(0xFFE2E4E8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: charcoal,
      cardColor: cardBg,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: charcoal,
        elevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: charcoal),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: charcoal,
        unselectedItemColor: slateMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: charcoal,
        onPrimary: Color(0xFFFFFFFF),
        secondary: rawSteel,
        onSecondary: Color(0xFFFFFFFF),
        surface: surface,
        onSurface: charcoal,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        outline: lightBorder,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: charcoal),
        bodyMedium: TextStyle(color: charcoal),
        bodySmall: TextStyle(color: slateMuted),
        titleLarge: TextStyle(color: charcoal, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: charcoal, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: charcoal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          side: const BorderSide(color: charcoal, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Pre-built default themes
  static final ThemeData lightTheme = themeFor(GreyskullSkin.chalkAndSteel);
  static final ThemeData darkTheme = themeFor(GreyskullSkin.ironAndBone);
}
