import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../models/daily_checkin.dart';
import '../services/database_service.dart';
import '../services/risk_engine.dart';
import '../utils/app_theme.dart';

class CheckInScreen extends StatefulWidget {
  final DailyCheckIn? existing;
  const CheckInScreen({super.key, this.existing});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _db = DatabaseService.instance;
  double _sleep = 7;
  int _water = 4;
  int _meals = 2;
  int _stress = 2;
  double _screen = 4;
  int _caffeine = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _sleep = e.sleepHours; _water = e.waterCups; _meals = e.mealsEaten;
      _stress = e.stressLevel; _screen = e.screenTimeHours; _caffeine = e.caffeineCount;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final checkin = DailyCheckIn(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      sleepHours: _sleep, waterCups: _water, mealsEaten: _meals,
      stressLevel: _stress, screenTimeHours: _screen, caffeineCount: _caffeine,
    );
    await _db.upsertCheckIn(checkin);
    if (mounted) {
      final rs = RiskEngine.score(checkin);
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _resultSheet(rs),
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _resultSheet(int rs) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 28),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppTheme.riskBg(rs), shape: BoxShape.circle),
          child: Center(child: Text(RiskEngine.emoji(rs), style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: 20),
        Text('Risk Score: $rs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.riskColor(rs))),
        const SizedBox(height: 6),
        Text(RiskEngine.label(rs), style: TextStyle(fontSize: 14, color: AppTheme.riskColor(rs), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Check your dashboard for AI-powered advice', style: TextStyle(fontSize: 13, color: AppTheme.textMut)),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('View Dashboard'),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.existing != null ? 'Update Check-in' : 'Daily Check-in'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: const Text('How\'s your day going?', style: TextStyle(fontSize: 13, color: AppTheme.textMut, height: 1.5)),
                  ),
                  const SizedBox(height: 24),

                  FadeInUp(delay: const Duration(milliseconds: 50), child: _sliderTile(
                    Icons.bedtime_rounded, const Color(0xFF6366F1), 'Sleep Last Night',
                    '${_sleep.toStringAsFixed(1)}h', _sleep, 0, 12, 24,
                    (v) => setState(() => _sleep = v),
                  )),

                  FadeInUp(delay: const Duration(milliseconds: 100), child: _stepperTile(
                    Icons.water_drop_rounded, AppTheme.sky, 'Water Cups',
                    '$_water cups', _water, 0, 15, (v) => setState(() => _water = v),
                  )),

                  FadeInUp(delay: const Duration(milliseconds: 150), child: _stepperTile(
                    Icons.restaurant_rounded, AppTheme.orange, 'Meals Eaten',
                    '$_meals meals', _meals, 0, 5, (v) => setState(() => _meals = v),
                  )),

                  FadeInUp(delay: const Duration(milliseconds: 200), child: _stressTile()),

                  FadeInUp(delay: const Duration(milliseconds: 250), child: _sliderTile(
                    Icons.phone_android_rounded, AppTheme.pink, 'Screen Time',
                    '${_screen.toStringAsFixed(1)}h', _screen, 0, 16, 32,
                    (v) => setState(() => _screen = v),
                  )),

                  FadeInUp(delay: const Duration(milliseconds: 300), child: _stepperTile(
                    Icons.coffee_rounded, const Color(0xFF92400E), 'Caffeine Drinks',
                    '$_caffeine drinks', _caffeine, 0, 10, (v) => setState(() => _caffeine = v),
                  )),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Bottom save bar
          Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                ),
                child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(widget.existing != null ? 'Update Check-in' : 'Save Check-in', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderTile(IconData icon, Color color, String title, String val, double current, double min, double max, int div, ValueChanged<double> onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text)),
          const Spacer(),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ]),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color, inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color, overlayColor: color.withOpacity(0.1),
            trackHeight: 5, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(value: current, min: min, max: max, divisions: div, onChanged: (v) { HapticFeedback.selectionClick(); onChange(v); }),
        ),
      ]),
    );
  }

  Widget _stepperTile(IconData icon, Color color, String title, String val, int count, int min, int max, ValueChanged<int> onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text)),
          Text(val, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ])),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.remove_rounded, size: 18), onPressed: count > min ? () { HapticFeedback.selectionClick(); onChange(count - 1); } : null, color: AppTheme.textSec, constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
            SizedBox(width: 28, child: Center(child: Text('$count', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.text)))),
            IconButton(icon: const Icon(Icons.add_rounded, size: 18), onPressed: count < max ? () { HapticFeedback.selectionClick(); onChange(count + 1); } : null, color: AppTheme.textSec, constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
          ]),
        ),
      ]),
    );
  }

  Widget _stressTile() {
    final colors = [AppTheme.green, const Color(0xFF84CC16), AppTheme.amber, AppTheme.coral, AppTheme.danger];
    final labels = ['Chill', 'Low', 'Medium', 'High', 'Extreme'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors[_stress - 1].withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.psychology_rounded, color: colors[_stress - 1], size: 18)),
          const SizedBox(width: 12),
          const Text('Stress Level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: colors[_stress - 1].withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(labels[_stress - 1], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors[_stress - 1])),
          ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
          final sel = _stress == i + 1;
          return GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); setState(() => _stress = i + 1); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: sel ? colors[i] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? colors[i] : AppTheme.border, width: sel ? 2 : 1),
                boxShadow: sel ? [BoxShadow(color: colors[i].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: sel ? Colors.white : colors[i]))),
            ),
          );
        })),
      ]),
    );
  }
}
