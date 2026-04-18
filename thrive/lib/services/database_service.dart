import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/daily_checkin.dart';
import '../models/ai_advice.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final p = join(await getDatabasesPath(), 'thrive_v3.db');
    return openDatabase(p, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE checkins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          sleep_hours REAL NOT NULL,
          water_cups INTEGER NOT NULL,
          meals_eaten INTEGER NOT NULL,
          stress_level INTEGER NOT NULL,
          screen_time_hours REAL NOT NULL,
          caffeine_count INTEGER DEFAULT 0,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE advice (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          advice TEXT NOT NULL,
          risk_score INTEGER NOT NULL,
          risk_level TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    });
  }

  Future<int> upsertCheckIn(DailyCheckIn c) async {
    final db = await database;
    final existing = await db.query('checkins', where: 'date = ?', whereArgs: [c.date], limit: 1);
    if (existing.isNotEmpty) {
      return db.update('checkins', c.toMap()..remove('id'), where: 'date = ?', whereArgs: [c.date]);
    }
    return db.insert('checkins', c.toMap());
  }

  Future<DailyCheckIn?> getCheckIn(String date) async {
    final db = await database;
    final r = await db.query('checkins', where: 'date = ?', whereArgs: [date], limit: 1);
    return r.isEmpty ? null : DailyCheckIn.fromMap(r.first);
  }

  Future<List<DailyCheckIn>> getWeekCheckIns() async {
    final db = await database;
    final d = DateTime.now().subtract(const Duration(days: 7));
    final r = await db.query('checkins', where: 'date >= ?', whereArgs: [d.toIso8601String().substring(0, 10)], orderBy: 'date ASC');
    return r.map((m) => DailyCheckIn.fromMap(m)).toList();
  }

  Future<List<DailyCheckIn>> getAllCheckIns() async {
    final db = await database;
    final r = await db.query('checkins', orderBy: 'date DESC');
    return r.map((m) => DailyCheckIn.fromMap(m)).toList();
  }

  Future<int> saveAdvice(AIAdvice a) async {
    final db = await database;
    return db.insert('advice', a.toMap());
  }

  Future<AIAdvice?> getLatestAdvice(String date) async {
    final db = await database;
    final r = await db.query('advice', where: 'date = ?', whereArgs: [date], orderBy: 'created_at DESC', limit: 1);
    return r.isEmpty ? null : AIAdvice.fromMap(r.first);
  }

  Future<List<AIAdvice>> getAdviceHistory() async {
    final db = await database;
    final r = await db.query('advice', orderBy: 'created_at DESC', limit: 20);
    return r.map((m) => AIAdvice.fromMap(m)).toList();
  }

  Future<int> getCheckInCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM checkins');
    return r.first['c'] as int;
  }

  Future<int> getStreak() async {
    final all = await getAllCheckIns();
    if (all.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < all.length; i++) {
      final expected = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final check = DateTime.parse(all[i].date);
      if (check.year == expected.year && check.month == expected.month && check.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── MOCK DATA SEEDER ─────────────────────────────────────────────────

  Future<void> seedMockData() async {
    final existing = await getCheckInCount();
    if (existing > 0) return; // Don't seed if data already exists

    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    // 7 days of realistic student data — tells a story
    final mockData = [
      // Day 7 (a week ago) — Good day, well rested
      DailyCheckIn(date: fmt.format(now.subtract(const Duration(days: 6))),
        sleepHours: 8.0, waterCups: 9, mealsEaten: 3, stressLevel: 1,
        screenTimeHours: 3.5, caffeineCount: 1),

      // Day 6 — Still decent
      DailyCheckIn(date: fmt.format(now.subtract(const Duration(days: 5))),
        sleepHours: 7.5, waterCups: 7, mealsEaten: 3, stressLevel: 2,
        screenTimeHours: 5.0, caffeineCount: 1),

      // Day 5 — Assignment due, stress rising
      DailyCheckIn(date: fmt.format(now.subtract(const Duration(days: 4))),
        sleepHours: 6.5, waterCups: 6, mealsEaten: 2, stressLevel: 3,
        screenTimeHours: 7.0, caffeineCount: 2),

      // Day 4 — Midterm week starts
      DailyCheckIn(date: fmt.format(now.subtract(const Duration(days: 3))),
        sleepHours: 5.5, waterCups: 4, mealsEaten: 2, stressLevel: 4,
        screenTimeHours: 9.0, caffeineCount: 3),

      // Day 3 — All-nighter territory
      DailyCheckIn(date: fmt.format(now.subtract(const Duration(days: 2))),
        sleepHours: 4.0, waterCups: 3, mealsEaten: 1, stressLevel: 5,
        screenTimeHours: 11.0, caffeineCount: 4),

      // Day 2 (yesterday) — Recovering slightly
      DailyCheckIn(date: fmt.format(now.subtract(const Duration(days: 1))),
        sleepHours: 6.0, waterCups: 5, mealsEaten: 2, stressLevel: 4,
        screenTimeHours: 8.0, caffeineCount: 3),

      // Today — Still stressed but trying
      DailyCheckIn(date: fmt.format(now),
        sleepHours: 5.0, waterCups: 3, mealsEaten: 1, stressLevel: 4,
        screenTimeHours: 6.5, caffeineCount: 2),
    ];

    for (final c in mockData) {
      await upsertCheckIn(c);
    }

    // Seed today's AI advice
    final todayAdvice = AIAdvice(
      date: fmt.format(now),
      advice: 'Your burnout risk is sitting at a concerning level — sleep debt is accumulating and hydration is critically low for Sharjah\'s climate.\n\n'
          '• Drink 500ml of water right now, then another 250ml every hour. At 3 cups today, you\'re running at half capacity — dehydration alone drops focus by up to 25%.\n\n'
          '• Eat a proper meal within 30 minutes. Your brain burns 20% of your daily calories, and running on one meal is like running a car on fumes. Protein + complex carbs — eggs, hummus with bread, or a shawarma wrap.\n\n'
          '• Tonight is non-negotiable: screen off by 10 PM, aim for 7 hours minimum. Two consecutive nights of 5 hours or less starts degrading memory consolidation — the exact thing you need for exams.\n\n'
          'You\'re in the hard part right now, but you\'re still standing. One good night of sleep changes everything. 💪',
      riskScore: 68,
      riskLevel: 'high',
    );
    await saveAdvice(todayAdvice);
  }
}
