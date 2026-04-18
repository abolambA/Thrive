import '../models/daily_checkin.dart';

class RiskEngine {
  static int score(DailyCheckIn c) {
    double s = 0;
    // Sleep 30%
    if (c.sleepHours < 4) s += 30;
    else if (c.sleepHours < 5) s += 25;
    else if (c.sleepHours < 6) s += 18;
    else if (c.sleepHours < 7) s += 10;
    else if (c.sleepHours <= 9) s += 0;
    else s += 5;
    // Water 20%
    if (c.waterCups <= 1) s += 20;
    else if (c.waterCups <= 3) s += 15;
    else if (c.waterCups <= 5) s += 8;
    else if (c.waterCups <= 7) s += 3;
    // Meals 15%
    if (c.mealsEaten == 0) s += 15;
    else if (c.mealsEaten == 1) s += 10;
    else if (c.mealsEaten == 2) s += 4;
    // Stress 20%
    s += (c.stressLevel - 1) * 5;
    // Screen 10%
    if (c.screenTimeHours > 10) s += 10;
    else if (c.screenTimeHours > 8) s += 7;
    else if (c.screenTimeHours > 6) s += 4;
    else if (c.screenTimeHours > 4) s += 2;
    // Caffeine 5%
    if (c.caffeineCount > 4) s += 5;
    else if (c.caffeineCount > 2) s += 3;
    else if (c.caffeineCount > 0) s += 1;
    return s.round().clamp(0, 100);
  }

  static String level(int s) {
    if (s >= 75) return 'critical';
    if (s >= 50) return 'high';
    if (s >= 30) return 'moderate';
    return 'low';
  }

  static String label(int s) {
    if (s >= 75) return 'Critical — Burnout Imminent';
    if (s >= 50) return 'High Risk — Take Action';
    if (s >= 30) return 'Moderate — Stay Aware';
    return 'Low — You\'re Thriving';
  }

  static String emoji(int s) {
    if (s >= 75) return '🔴';
    if (s >= 50) return '🟠';
    if (s >= 30) return '🟡';
    return '🟢';
  }
}
