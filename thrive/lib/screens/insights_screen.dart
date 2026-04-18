import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../models/daily_checkin.dart';
import '../services/database_service.dart';
import '../services/risk_engine.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _db = DatabaseService.instance;
  List<DailyCheckIn> _week = [];
  bool _loading = true;
  String _report = '';
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await _db.getWeekCheckIns();
    if (mounted) setState(() { _week = w; _loading = false; });
  }

  Future<void> _genReport() async {
    if (_week.isEmpty) return;
    setState(() => _generating = true);
    final a = await AIService.analyze(today: _week.last, week: _week);
    if (mounted) setState(() { _report = a.advice; _generating = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 20),
                  FadeInDown(child: const Text('Insights',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -1))),
                  const SizedBox(height: 4),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: const Text('Your health patterns this week',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSec)),
                  ),
                  const SizedBox(height: 24),
                  if (_week.isEmpty)
                    _noData()
                  else ...[
                    FadeInUp(delay: const Duration(milliseconds: 100), child: _weekSummary()),
                    const SizedBox(height: 16),
                    FadeInUp(delay: const Duration(milliseconds: 200),
                        child: _chartCard('Sleep Trend', Icons.bedtime_rounded, const Color(0xFF6366F1), _sleepChart())),
                    const SizedBox(height: 16),
                    FadeInUp(delay: const Duration(milliseconds: 300),
                        child: _chartCard('Hydration', Icons.water_drop_rounded, AppTheme.sky, _waterChart())),
                    const SizedBox(height: 16),
                    FadeInUp(delay: const Duration(milliseconds: 400),
                        child: _chartCard('Risk Trend', Icons.show_chart_rounded, AppTheme.coral, _riskChart())),
                    const SizedBox(height: 16),
                    FadeInUp(delay: const Duration(milliseconds: 500), child: _reportCard()),
                    const SizedBox(height: 32),
                  ],
                ]),
              ),
      ),
    );
  }

  Widget _noData() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(children: [
      Icon(Icons.insights_rounded, size: 56, color: AppTheme.textMut),
      const SizedBox(height: 16),
      const Text('No data yet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.text)),
      const SizedBox(height: 8),
      const Text('Complete daily check-ins to see\nyour health trends here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.textSec, height: 1.5)),
    ]),
  );

  Widget _weekSummary() {
    final avgS = _week.map((c) => c.sleepHours).reduce((a, b) => a + b) / _week.length;
    final avgW = _week.map((c) => c.waterCups.toDouble()).reduce((a, b) => a + b) / _week.length;
    final avgSt = _week.map((c) => c.stressLevel.toDouble()).reduce((a, b) => a + b) / _week.length;
    final avgRisk = _week.map((c) => RiskEngine.score(c).toDouble()).reduce((a, b) => a + b) / _week.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Weekly Averages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
            child: Text('${_week.length} days',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSec, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _avgTile('Sleep', '${avgS.toStringAsFixed(1)}h', Icons.bedtime_rounded, const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          _avgTile('Water', '${avgW.toStringAsFixed(1)}', Icons.water_drop_rounded, AppTheme.sky),
          const SizedBox(width: 10),
          _avgTile('Stress', '${avgSt.toStringAsFixed(1)}', Icons.psychology_rounded, AppTheme.coral),
          const SizedBox(width: 10),
          _avgTile('Risk', '${avgRisk.toStringAsFixed(0)}', Icons.speed_rounded,
              AppTheme.riskColor(avgRisk.round())),
        ]),
      ]),
    );
  }

  Widget _avgTile(String l, String v, IconData ic, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Icon(ic, color: c, size: 18),
        const SizedBox(height: 6),
        Text(v, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(fontSize: 10, color: AppTheme.textMut)),
      ]),
    ),
  );

  Widget _chartCard(String title, IconData icon, Color color, Widget chart) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text)),
      ]),
      const SizedBox(height: 20),
      SizedBox(height: 180, child: chart),
    ]),
  );

  AxisTitles _noAxis() => const AxisTitles(sideTitles: SideTitles(showTitles: false));

  SideTitles _bottomTitles() => SideTitles(
    showTitles: true,
    getTitlesWidget: (v, _) {
      final i = v.toInt();
      if (i < 0 || i >= _week.length) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          DateFormat('E').format(DateTime.parse(_week[i].date)),
          style: TextStyle(fontSize: 10, color: AppTheme.textMut),
        ),
      );
    },
  );

  Widget _sleepChart() => LineChart(LineChartData(
    gridData: const FlGridData(show: false),
    titlesData: FlTitlesData(
      leftTitles: _noAxis(), topTitles: _noAxis(), rightTitles: _noAxis(),
      bottomTitles: AxisTitles(sideTitles: _bottomTitles()),
    ),
    borderData: FlBorderData(show: false),
    minY: 0, maxY: 12,
    lineBarsData: [
      LineChartBarData(
        spots: _week.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sleepHours)).toList(),
        isCurved: true, color: const Color(0xFF6366F1), barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4, color: const Color(0xFF6366F1), strokeWidth: 2, strokeColor: Colors.white),
        ),
        belowBarData: BarAreaData(show: true, color: const Color(0xFF6366F1).withValues(alpha: 0.06)),
      ),
    ],
  ));

  Widget _waterChart() => BarChart(BarChartData(
    gridData: const FlGridData(show: false),
    titlesData: FlTitlesData(
      leftTitles: _noAxis(), topTitles: _noAxis(), rightTitles: _noAxis(),
      bottomTitles: AxisTitles(sideTitles: _bottomTitles()),
    ),
    borderData: FlBorderData(show: false),
    maxY: 12,
    barGroups: _week.asMap().entries.map((e) => BarChartGroupData(
      x: e.key,
      barRods: [
        BarChartRodData(
          toY: e.value.waterCups.toDouble(),
          color: e.value.waterCups >= 8 ? AppTheme.sky : AppTheme.sky.withValues(alpha: 0.35),
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    )).toList(),
  ));

  Widget _riskChart() => LineChart(LineChartData(
    gridData: const FlGridData(show: false),
    titlesData: FlTitlesData(
      leftTitles: _noAxis(), topTitles: _noAxis(), rightTitles: _noAxis(),
      bottomTitles: AxisTitles(sideTitles: _bottomTitles()),
    ),
    borderData: FlBorderData(show: false),
    minY: 0, maxY: 100,
    lineBarsData: [
      LineChartBarData(
        spots: _week.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), RiskEngine.score(e.value).toDouble()))
            .toList(),
        isCurved: true, color: AppTheme.coral, barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 4, color: AppTheme.riskColor(spot.y.toInt()), strokeWidth: 2, strokeColor: Colors.white),
        ),
        belowBarData: BarAreaData(show: true, color: AppTheme.coral.withValues(alpha: 0.06)),
      ),
    ],
  ));

  Widget _reportCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Text('Weekly AI Report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
      ]),
      const SizedBox(height: 18),
      if (_report.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Text(_report,
              style: const TextStyle(fontSize: 14, color: AppTheme.text, height: 1.65)),
        )
      else if (_generating)
        const Center(child: Padding(padding: EdgeInsets.all(28),
            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3)))
      else
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _genReport,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Generate Report'),
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
    ]),
  );
}
