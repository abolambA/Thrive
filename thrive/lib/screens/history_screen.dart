import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../models/daily_checkin.dart';
import '../services/database_service.dart';
import '../services/risk_engine.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = DatabaseService.instance;
  List<DailyCheckIn> _all = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await _db.getAllCheckIns();
    if (mounted) setState(() { _all = all; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
                child: Text('${_all.length} entries',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSec)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3))
          : _all.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _all.length,
                  itemBuilder: (_, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 40),
                    duration: const Duration(milliseconds: 400),
                    child: _HistoryCard(checkIn: _all[i]),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_rounded, size: 64, color: AppTheme.textMut),
      const SizedBox(height: 16),
      const Text('No history yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.text)),
      const SizedBox(height: 8),
      const Text('Your completed check-ins will appear here.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSec)),
    ]),
  );
}

class _HistoryCard extends StatelessWidget {
  final DailyCheckIn checkIn;
  const _HistoryCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final rs = RiskEngine.score(checkIn);
    final rColor = AppTheme.riskColor(rs);
    final date = DateTime.parse(checkIn.date);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    String dateLabel;
    if (checkIn.date == today) {
      dateLabel = 'Today';
    } else if (checkIn.date == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.riskBg(rs),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(RiskEngine.emoji(rs), style: const TextStyle(fontSize: 22))),
        ),
        title: Text(dateLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            'Risk: $rs — ${RiskEngine.level(rs).toUpperCase()}',
            style: TextStyle(fontSize: 12, color: rColor, fontWeight: FontWeight.w600),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: rColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$rs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: rColor)),
        ),
        children: [
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 16),
          _metricRow([
            _MetricItem(Icons.bedtime_rounded, const Color(0xFF6366F1), 'Sleep', '${checkIn.sleepHours}h'),
            _MetricItem(Icons.water_drop_rounded, AppTheme.sky, 'Water', '${checkIn.waterCups} cups'),
            _MetricItem(Icons.restaurant_rounded, AppTheme.orange, 'Meals', '${checkIn.mealsEaten}'),
          ]),
          const SizedBox(height: 10),
          _metricRow([
            _MetricItem(Icons.psychology_rounded, AppTheme.coral, 'Stress', '${checkIn.stressLevel}/5'),
            _MetricItem(Icons.phone_android_rounded, AppTheme.pink, 'Screen', '${checkIn.screenTimeHours}h'),
            _MetricItem(Icons.coffee_rounded, const Color(0xFF92400E), 'Caffeine', '${checkIn.caffeineCount}'),
          ]),
        ],
      ),
    );
  }

  Widget _metricRow(List<_MetricItem> items) => Row(
    children: items.map((item) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(item.icon, color: item.color, size: 16),
          const SizedBox(height: 5),
          Text(item.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: item.color)),
          const SizedBox(height: 2),
          Text(item.label, style: TextStyle(fontSize: 10, color: AppTheme.textMut)),
        ]),
      ),
    )).toList(),
  );
}

class _MetricItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MetricItem(this.icon, this.color, this.label, this.value);
}
