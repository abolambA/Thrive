import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_checkin.dart';
import '../models/ai_advice.dart';
import 'risk_engine.dart';

class AIService {
  static const String _key = 'AIzaSyAvr-g7yeJZXXR3-Mp1z1V5QDZ-vWAeHrg';
  static const String _url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<AIAdvice> analyze({
    required DailyCheckIn today,
    List<DailyCheckIn>? week,
    String? userName,
    bool examMode = false,
    DateTime? examDate,
    String? examSubject,
  }) async {
    final rs = RiskEngine.score(today);
    final rl = RiskEngine.level(rs);
    final prompt = _prompt(today, rs, rl, week, userName, examMode, examDate, examSubject);

    try {
      final res = await http.post(
        Uri.parse('$_url?key=$_key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 800},
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? _fallback(rs, today);
        return AIAdvice(date: today.date, advice: text, riskScore: rs, riskLevel: rl);
      }
      return AIAdvice(date: today.date, advice: _fallback(rs, today), riskScore: rs, riskLevel: rl);
    } catch (_) {
      return AIAdvice(date: today.date, advice: _fallback(rs, today), riskScore: rs, riskLevel: rl);
    }
  }

  static String _prompt(DailyCheckIn c, int rs, String rl, List<DailyCheckIn>? week, String? name, bool exam, DateTime? examDate, String? examSubject) {
    var weekCtx = '';
    if (week != null && week.length > 1) {
      final avgS = week.map((x) => x.sleepHours).reduce((a, b) => a + b) / week.length;
      final avgW = week.map((x) => x.waterCups).reduce((a, b) => a + b) / week.length;
      weekCtx = '''
WEEKLY TREND (${week.length} days):
- Avg sleep: ${avgS.toStringAsFixed(1)}h | Today: ${c.sleepHours}h (${c.sleepHours < avgS ? '⬇ DECLINING' : '⬆ GOOD'})
- Avg water: ${avgW.toStringAsFixed(1)} cups | Today: ${c.waterCups} (${c.waterCups < avgW ? '⬇ DECLINING' : '⬆ GOOD'})
''';
    }

    var examCtx = '';
    if (exam && examDate != null) {
      final days = examDate.difference(DateTime.now()).inDays;
      examCtx = '\n⚠️ EXAM MODE: ${examSubject ?? "Exam"} in $days days. Optimize advice for peak cognitive performance.\n';
    }

    return '''
You are Thrive's AI Health Coach. You're warm, specific, and action-oriented. You speak like a caring friend who happens to be a health expert.

${name != null ? 'Student name: $name' : ''}

TODAY'S VITALS:
• Sleep: ${c.sleepHours}h | Water: ${c.waterCups} cups | Meals: ${c.mealsEaten}
• Stress: ${c.stressLevel}/5 | Screen: ${c.screenTimeHours}h | Caffeine: ${c.caffeineCount}
• Burnout Risk: $rs/100 ($rl)
$weekCtx$examCtx
CONTEXT: University student in Sharjah, UAE. Hot climate = dehydration risk. High academic pressure.

YOUR RESPONSE (under 180 words, no markdown headers):
1. One-sentence assessment of their state right now
2. Three specific interventions for the NEXT 4 HOURS — include exact quantities, timing, actions. Not generic. Example: "Drink 500ml water in the next 30 minutes" not "stay hydrated"
3. One warm, encouraging closing sentence

Start directly with the assessment. No greetings.
''';
  }

  static String _fallback(int rs, DailyCheckIn c) {
    final tips = <String>[];
    if (c.sleepHours < 6) tips.add('• Your sleep is critically low. Set an alarm to start winding down in 6 hours — dim lights, no screens. Your brain consolidates memory during sleep, so this directly impacts your performance.');
    if (c.waterCups < 4) tips.add('• You\'re dehydrated — in Sharjah\'s heat, this is dangerous. Drink 500ml of water right now, then 250ml every hour. Dehydration drops cognitive function by up to 25%.');
    if (c.mealsEaten < 2) tips.add('• You\'ve barely eaten. Grab something with protein and complex carbs within 30 minutes — eggs, nuts, or a sandwich. Your brain burns 20% of your daily calories.');
    if (c.stressLevel >= 4) tips.add('• Stress is spiking. Right now: close your eyes, breathe in for 4 counts, hold for 7, out for 8. Repeat 3 times. This activates your parasympathetic nervous system.');
    if (c.screenTimeHours > 7) tips.add('• ${c.screenTimeHours.toStringAsFixed(0)}+ hours of screen time is straining your eyes and disrupting your circadian rhythm. Take a 10-minute screen break right now — look at distant objects.');
    if (c.caffeineCount > 3) tips.add('• ${c.caffeineCount} caffeine drinks is excessive. No more caffeine today — it takes 6 hours to clear half the caffeine from your system, and it will wreck tonight\'s sleep.');
    if (tips.isEmpty) tips.add('• Your vitals are balanced. Maintain this rhythm — consistency prevents burnout better than any single intervention.');

    final assessment = rs >= 75 ? 'Your burnout risk is at $rs — this needs immediate attention.' :
      rs >= 50 ? 'Your risk score is $rs — elevated. Let\'s course-correct now before it gets worse.' :
      rs >= 30 ? 'Risk score $rs — not bad, but a few tweaks will keep you in the green zone.' :
      'Risk score $rs — you\'re in great shape today. Here\'s how to maintain it.';

    return '$assessment\n\n${tips.take(3).join('\n\n')}\n\nSmall wins now compound into big results. You\'ve got this. 💪';
  }
}
