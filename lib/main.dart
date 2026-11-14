import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/pages/diet_page.dart';
import 'package:greyskull_lp/pages/forum_page.dart';
import 'package:greyskull_lp/pages/history_page.dart';
import 'package:greyskull_lp/pages/home_page.dart';
import 'package:greyskull_lp/pages/settings_page.dart';
import 'package:greyskull_lp/pages/stats_page.dart';
import 'package:greyskull_lp/pages/store_page.dart';
import 'package:greyskull_lp/pages/workout_page.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';
import 'package:greyskull_lp/ui/gs_icon.dart';
import 'package:greyskull_lp/ui/gs_widgets.dart';
import 'themes/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await trainingState.loadFromDisk();
  runApp(const GreyskullApp());
}

class GreyskullApp extends StatelessWidget {
  const GreyskullApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: trainingState,
      builder: (context, _) {
        final currentSkin = trainingState.activeSkin;
        return MaterialApp(
          title: 'Greyskull LP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(currentSkin),
          darkTheme: AppTheme.themeFor(currentSkin),
          themeMode: currentSkin.isDark ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/main': (context) => const MainPage(),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainPage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: Center(
        child: Image.asset('assets/icon/app_splash_icon.png'),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = -1;
  final ValueNotifier<String> _appBarTitle =
      ValueNotifier("Official Greyskull LP App");
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      WorkoutPage(titleNotifier: _appBarTitle),
      const ForumPage(),
      const DietPage(),
      const StatsPage(),
      const HistoryPage(),
      const StorePage(),
    ];
  }

  @override
  void dispose() {
    _appBarTitle.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _appBarTitle.value = "Workout";
    } else {
      _appBarTitle.value = _getPageTitle(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final isHome = _selectedIndex == -1;
    final streak = trainingState.calculateCurrentStreakDays();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: isHome ? 16 : 6,
        backgroundColor: tokens.bg,
        leading: isHome
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GsSquareButton(
                  tooltip: 'Main menu',
                  onPressed: () {
                    setState(() {
                      _selectedIndex = -1;
                      _appBarTitle.value = "Official Greyskull LP App";
                    });
                  },
                  child: const GsIcon('more', size: 18),
                ),
              ),
        leadingWidth: isHome ? null : 56,
        title: ValueListenableBuilder<String>(
          valueListenable: _appBarTitle,
          builder: (context, title, _) => _GsAppBarTitle(
            isHome: isHome,
            title: title,
            subtitle: isHome
                ? 'Official Greyskull LP App'
                : _getPageSubtitle(_selectedIndex),
          ),
        ),
        actions: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onItemTapped(3),
                child: GsTag(
                  '$streak DAY STREAK',
                  tone: GsTagTone.accent,
                  svgIcon: 'flame',
                ),
              ),
            ),
          GsIconButton(
            svg: 'gear',
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isHome
          ? HomePage(onItemSelected: _onItemTapped)
          : _pages[_selectedIndex],
      bottomNavigationBar: isHome
          ? null
          : GsTabBar(
              items: const <GsTabItem>[
                GsTabItem(svg: 'train', label: 'Workout'),
                GsTabItem(svg: 'forum', label: 'Forum'),
                GsTabItem(svg: 'food', label: 'Diet'),
                GsTabItem(svg: 'stats', label: 'Stats'),
                GsTabItem(svg: 'history', label: 'History'),
                GsTabItem(svg: 'store', label: 'Store'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
    );
  }

  String _getPageSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Weight & calisthenics';
      case 1:
        return 'Greyskull Nation';
      case 2:
        return 'Fuel & macros';
      case 3:
        return 'Progress';
      case 4:
        return 'Workout log';
      case 5:
        return 'Official gear';
      default:
        return 'Greyskull LP';
    }
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Workout';
      case 1:
        return 'Forum';
      case 2:
        return 'Diet';
      case 3:
        return 'Stats';
      case 4:
        return 'History';
      case 5:
        return 'Store';
      default:
        return 'Greyskull LP Workout';
    }
  }
}

class _GsAppBarTitle extends StatelessWidget {
  const _GsAppBarTitle({
    required this.isHome,
    required this.title,
    required this.subtitle,
  });

  final bool isHome;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final displayStyle = TextStyle(
      fontFamily: GsFont.display,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      height: 1,
      color: tokens.bone,
    );

    if (isHome) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(text: 'GREYSKULL ', style: displayStyle),
                TextSpan(
                  text: 'LP',
                  style: displayStyle.copyWith(color: tokens.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.7,
              color: tokens.muted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: displayStyle.copyWith(fontSize: 17, letterSpacing: 0.6),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: GsFont.body,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: tokens.muted,
          ),
        ),
      ],
    );
  }
}
