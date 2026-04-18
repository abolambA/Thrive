import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ThriveApp());
}

class ThriveApp extends StatelessWidget {
  const ThriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thrive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return _fade(const SplashScreen());
          case '/onboard':
            return _slide(OnboardingScreen(onComplete: () {}), vertical: false);
          case '/home':
            return _fade(const AppShell());
          case '/history':
            return _slide(const HistoryScreen());
          case '/checkin':
            return _slide(CheckInScreen(existing: settings.arguments as dynamic), vertical: true);
          default:
            return _fade(const AppShell());
        }
      },
    );
  }

  PageRoute _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 350),
  );

  PageRoute _slide(Widget page, {bool vertical = false}) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(
        begin: vertical ? const Offset(0, 1) : const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 380),
  );
}

// ─── Main App Shell ─────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      floatingActionButton: _fab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _fab(BuildContext context) {
    return Container(
      height: 62, width: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'fab_checkin',
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: () async {
          await Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => const CheckInScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 380),
          ));
          _homeKey.currentState?.refresh();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: BottomAppBar(
        height: 74,
        padding: EdgeInsets.zero,
        notchMargin: 10,
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        child: Row(children: [
          _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Today'),
          _navItem(1, Icons.insights_rounded, Icons.insights_outlined, 'Insights'),
          const SizedBox(width: 68),
          _navItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
          _historyItem(),
        ]),
      ),
    );
  }

  Widget _navItem(int i, IconData activeIcon, IconData inactiveIcon, String label) {
    final sel = _tab == i;
    return Expanded(
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = i); },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: sel ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(sel ? activeIcon : inactiveIcon,
                color: sel ? AppTheme.primary : AppTheme.textMut, size: 23),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            color: sel ? AppTheme.primary : AppTheme.textMut,
          )),
        ]),
      ),
    );
  }

  Widget _historyItem() {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HistoryScreen(),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        )),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: const Icon(Icons.history_rounded, color: AppTheme.textMut, size: 23),
          ),
          const SizedBox(height: 3),
          const Text('History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppTheme.textMut)),
        ]),
      ),
    );
  }
}
