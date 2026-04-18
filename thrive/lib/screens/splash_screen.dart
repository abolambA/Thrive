import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (mounted) {
      Navigator.pushReplacementNamed(context, onboarded ? '/home' : '/onboard');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Thrive',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -1.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your health. Intelligently.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSec, fontWeight: FontWeight.w500, letterSpacing: 0.2),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
