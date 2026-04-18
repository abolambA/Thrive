import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/daily_checkin.dart';
import '../models/ai_advice.dart';
import '../services/database_service.dart';
import '../services/risk_engine.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';
import 'checkin_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _db = DatabaseService.instance;
  DailyCheckIn? _today;
  AIAdvice? _advice;
  bool _loadingAdvice = false;
  String _userName = '';
  int _streak = 0;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final checkin = await _db.getCheckIn(date);
    final advice = await _db.getLatestAdvice(date);
    final streak = await _db.getStreak();
    final total = await _db.getCheckInCount();
    if (mounted) setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _today = checkin;
      _advice = advice;
      _streak = streak;
      _total = total;
    });
  }

  void refresh() => _load();

  Future<void> _getAdvice() async {
    if (_today == null) return;
    setState(() => _loadingAdvice = true);
    final prefs = await SharedPreferences.getInstance();
    final examMode = prefs.getBool('exam_mode') ?? false;
    final examSub = prefs.getString('exam_subject');
    final examDateStr = prefs.getString('exam_date');
    final examDate = examDateStr != null ? DateTime.tryParse(examDateStr) : null;
    final week = await _db.getWeekCheckIns();
    final advice = await AIService.analyze(
      today: _today!, week: week, userName: _userName,
      examMode: examMode, examDate: examDate, examSubject: examSub,
    );
    await _db.saveAdvice(advice);
    if (mounted) setState(() { _advice = advice; _loadingAdvice = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _today == null ? _empty(context) : _dashboard(context),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening';
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const SizedBox(height: 24),
            FadeInDown(child: _header(g)),
            const SizedBox(height: 40),
            FadeInUp(delay: const Duration(milliseconds: 200), child: _checkinPrompt(context)),
            const SizedBox(height: 32),
            FadeInUp(delay: const Duration(milliseconds: 350), child: _tips()),
          ])),
        ),
      ],
    );
  }

  Widget _checkinPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCheckin(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.06), AppTheme.accent.withOpacity(0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.primary.withOpacity(0.15), width: 1.5),
        ),
        child: Column(children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))],
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 24),
          const Text('How are you today?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          const Text('15-second check-in. Your AI coach\nwill handle the rest.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSec, height: 1.6)),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Start Check-in', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tips() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Health Tips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
      const SizedBox(height: 12),
      ...[
        ('💧', 'UAE heat causes faster dehydration. Aim for 8+ cups daily.', AppTheme.sky),
        ('🛏️', 'Even 30 extra minutes of sleep improves focus by 20%.', const Color(0xFF6366F1)),
        ('🧘', 'Two minutes of deep breathing lowers cortisol significantly.', AppTheme.green),
      ].map((tip) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (tip.$3 as Color).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (tip.$3 as Color).withOpacity(0.15)),
        ),
        child: Row(children: [
          Text(tip.$1, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(tip.$2, style: const TextStyle(fontSize: 13, color: AppTheme.textSec, height: 1.5))),
        ]),
      )).toList(),
    ]);
  }

  Widget _dashboard(BuildContext context) {
    final c = _today!;
    final rs = RiskEngine.score(c);
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              FadeInDown(child: _header(null)),
              const SizedBox(height: 20),
              FadeInUp(delay: const Duration(milliseconds: 80), child: _riskCard(rs, c)),
              const SizedBox(height: 14),
              FadeInUp(delay: const Duration(milliseconds: 160), child: _vitalRow(c)),
              const SizedBox(height: 14),
              FadeInUp(delay: const Duration(milliseconds: 240), child: _secondaryRow(c)),
              const SizedBox(height: 14),
              FadeInUp(delay: const Duration(milliseconds: 320), child: _aiCard()),
              const SizedBox(height: 14),
              FadeInUp(delay: const Duration(milliseconds: 400), child: _actionRow(context)),
              const SizedBox(height: 32),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _header(String? greeting) {
    final h = DateTime.now().hour;
    final g = greeting ?? (h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening');
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'T';
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g, style: const TextStyle(fontSize: 13, color: AppTheme.textMut, fontWeight: FontWeight.w500, letterSpacing: 0.2)),
        const SizedBox(height: 2),
        Text(_userName.isNotEmpty ? _userName : 'Thrive',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -1)),
      ])),
      if (_streak > 0) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: AppTheme.coral.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.coral),
            const SizedBox(width: 4),
            Text('$_streak day${_streak == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.coral)),
          ]),
        ),
        const SizedBox(width: 8),
      ],
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
      ),
    ]);
  }

  Widget _riskCard(int rs, DailyCheckIn c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.riskBg(rs), Colors.white],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.riskColor(rs).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppTheme.riskColor(rs).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        const Text('Burnout Risk Score', style: TextStyle(fontSize: 13, color: AppTheme.textSec, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 20),
        _AnimatedGauge(score: rs, size: 190),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.riskColor(rs).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(RiskEngine.emoji(rs), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(RiskEngine.label(rs), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.riskColor(rs))),
          ]),
        ),
        if (rs >= 50) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.riskColor(rs).withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.riskColor(rs)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                rs >= 75 ? 'Immediate action needed. Tap "Get AI Advice" below.' : 'Your body is under stress. Check the AI advisor for help.',
                style: TextStyle(fontSize: 12, color: AppTheme.riskColor(rs), fontWeight: FontWeight.w500, height: 1.4),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _vitalRow(DailyCheckIn c) {
    return Row(children: [
      _vitalCard(Icons.bedtime_rounded, const Color(0xFF6366F1), 'Sleep', '${c.sleepHours}h', c.sleepHours / 9),
      const SizedBox(width: 10),
      _vitalCard(Icons.water_drop_rounded, AppTheme.sky, 'Water', '${c.waterCups} cups', c.waterCups / 8),
      const SizedBox(width: 10),
      _vitalCard(Icons.restaurant_rounded, AppTheme.orange, 'Meals', '${c.mealsEaten}/3', c.mealsEaten / 3),
      const SizedBox(width: 10),
      _vitalCard(Icons.psychology_rounded, c.stressLevel >= 4 ? AppTheme.coral : AppTheme.green, 'Stress', '${c.stressLevel}/5', c.stressLevel / 5, invert: true),
    ]);
  }

  Widget _vitalCard(IconData icon, Color color, String label, String val, double prog, {bool invert = false}) {
    final barColor = invert ? (prog > 0.6 ? AppTheme.coral : AppTheme.green) : color;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.text)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMut, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: prog.clamp(0, 1),
              backgroundColor: barColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _secondaryRow(DailyCheckIn c) {
    return Row(children: [
      Expanded(child: _secondaryCard(Icons.phone_android_rounded, AppTheme.pink, 'Screen Time', '${c.screenTimeHours}h', 'limit 4h', c.screenTimeHours / 10)),
      const SizedBox(width: 12),
      Expanded(child: _secondaryCard(Icons.coffee_rounded, const Color(0xFF92400E), 'Caffeine', '${c.caffeineCount}', 'limit 2', c.caffeineCount / 5)),
    ]);
  }

  Widget _secondaryCard(IconData icon, Color color, String title, String val, String target, double prog) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 15)),
          const Spacer(),
          Text(target, style: const TextStyle(fontSize: 10, color: AppTheme.textMut)),
        ]),
        const SizedBox(height: 12),
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSec)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: prog.clamp(0, 1),
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(prog > 0.7 ? AppTheme.coral : color),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }

  Widget _aiCard() {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hasAdvice = _advice != null && _advice!.date == todayDate;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Health Coach', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text)),
              Text('Powered by Gemini 2.0', style: TextStyle(fontSize: 11, color: AppTheme.textMut)),
            ])),
            if (hasAdvice)
              TextButton.icon(
                onPressed: _getAdvice,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (hasAdvice)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: Text(_advice!.advice, style: const TextStyle(fontSize: 14, color: AppTheme.text, height: 1.68)),
            ),
          )
        else if (_loadingAdvice)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3)),
                const SizedBox(height: 12),
                const Text('Analyzing your vitals...', style: TextStyle(color: AppTheme.textMut, fontSize: 13)),
              ]),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _getAdvice,
                icon: const Icon(Icons.auto_awesome, size: 17),
                label: const Text('Get Personalized Advice'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _actionRow(BuildContext context) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: () => _openCheckin(context),
        icon: const Icon(Icons.edit_rounded, size: 16),
        label: const Text('Update'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      )),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HistoryScreen(),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        )),
        icon: const Icon(Icons.history_rounded, size: 16),
        label: Text('History ($_total)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSec,
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      )),
    ]);
  }

  Future<void> _openCheckin(BuildContext ctx) async {
    await Navigator.push(ctx, PageRouteBuilder(
      pageBuilder: (_, __, ___) => CheckInScreen(existing: _today),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 380),
    ));
    _load();
  }
}

// ─── Animated Gauge ─────────────────────────────────────────────────────────

class _AnimatedGauge extends StatefulWidget {
  final int score;
  final double size;
  const _AnimatedGauge({required this.score, this.size = 190});
  @override
  State<_AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<_AnimatedGauge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween(begin: 0.0, end: widget.score.toDouble()).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }
  @override
  void didUpdateWidget(_AnimatedGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween(begin: _anim.value, end: widget.score.toDouble()).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl..reset()..forward();
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) {
      final v = _anim.value.round();
      return SizedBox(width: widget.size, height: widget.size, child: CustomPaint(
        painter: _GaugePainter(score: _anim.value, color: AppTheme.riskColor(v)),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$v', style: TextStyle(fontSize: widget.size * 0.24, fontWeight: FontWeight.w900, color: AppTheme.riskColor(v), letterSpacing: -3, height: 1)),
          Text('out of 100', style: TextStyle(fontSize: widget.size * 0.07, color: AppTheme.textMut, fontWeight: FontWeight.w500)),
        ])),
      ));
    },
  );
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  _GaugePainter({required this.score, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 18;
    const start = 2.4;
    const sweep = 4.88;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false,
      Paint()..color = const Color(0xFFEEF0F4)..strokeWidth = 16..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final s = sweep * (score / 100);
    if (score > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, s, false,
        Paint()..color = color..strokeWidth = 16..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      final a = start + s;
      final dot = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      canvas.drawCircle(dot, 11, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawCircle(dot, 6, Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
  }
  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.score != score || o.color != color;
}
