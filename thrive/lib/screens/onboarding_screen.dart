import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({super.key, this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;

  static const _pages = [
    _Page(Icons.favorite_rounded, AppTheme.primary, 'Welcome to Thrive', 'Your AI-powered health companion,\nbuilt for university students in the UAE.'),
    _Page(Icons.speed_rounded, AppTheme.coral, 'Burnout Detection', 'Log your daily vitals in 15 seconds.\nThrive catches dangerous patterns\nbefore you crash.'),
    _Page(Icons.auto_awesome, AppTheme.accent, 'AI Health Coach', 'Get personalized, specific advice\npowered by AI — not generic tips,\nbut what YOU need right now.'),
  ];

  Future<void> _complete() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) await prefs.setString('user_name', name);
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // Skip
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
              child: _page < 3
                  ? TextButton(
                      onPressed: () => _ctrl.animateToPage(3, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut),
                      child: const Text('Skip', style: TextStyle(color: AppTheme.textMut, fontSize: 14, fontWeight: FontWeight.w500)),
                    )
                  : const SizedBox(height: 40),
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                ..._pages.map(_buildInfoPage),
                _buildNamePage(),
              ],
            ),
          ),

          // Bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
            child: Column(children: [
              SmoothPageIndicator(
                controller: _ctrl, count: 4,
                effect: const WormEffect(dotHeight: 8, dotWidth: 8, spacing: 10, activeDotColor: AppTheme.primary, dotColor: AppTheme.border),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < 3) {
                      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    } else {
                      _complete();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(_page < 3 ? 'Next →' : 'Start Thriving', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoPage(_Page p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FadeInDown(duration: const Duration(milliseconds: 550), child: Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [p.color.withOpacity(0.15), p.color.withOpacity(0.05)]),
            shape: BoxShape.circle,
            border: Border.all(color: p.color.withOpacity(0.2), width: 2),
          ),
          child: Icon(p.icon, size: 58, color: p.color),
        )),
        const SizedBox(height: 44),
        FadeInUp(delay: const Duration(milliseconds: 150), child: Text(p.title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -0.8),
          textAlign: TextAlign.center)),
        const SizedBox(height: 14),
        FadeInUp(delay: const Duration(milliseconds: 280), child: Text(p.subtitle,
          style: const TextStyle(fontSize: 15, color: AppTheme.textSec, height: 1.65),
          textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FadeInDown(child: Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.green.withOpacity(0.15), AppTheme.green.withOpacity(0.05)]),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.green.withOpacity(0.2), width: 2),
          ),
          child: const Icon(Icons.waving_hand_rounded, size: 58, color: AppTheme.green),
        )),
        const SizedBox(height: 40),
        FadeInUp(delay: const Duration(milliseconds: 150), child: const Text(
          'What should we call you?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -0.8),
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 12),
        FadeInUp(delay: const Duration(milliseconds: 250), child: const Text(
          'Your AI coach will use your name\nfor personalized advice.',
          style: TextStyle(fontSize: 15, color: AppTheme.textSec, height: 1.6),
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 36),
        FadeInUp(delay: const Duration(milliseconds: 350), child: TextField(
          controller: _nameCtrl,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.text),
          decoration: InputDecoration(
            hintText: 'Your first name',
            hintStyle: const TextStyle(fontSize: 18, color: AppTheme.textMut, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          ),
        )),
      ]),
    );
  }
}

class _Page {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Page(this.icon, this.color, this.title, this.subtitle);
}
