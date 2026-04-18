import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
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
    // sqflite works on Android & iOS only.
    // If somehow running on web/desktop, throw a clear error.
    if (kIsWeb) {
      throw UnsupportedError('Thrive requires a physical Android or iOS device. Web is not supported.');
    }
    final p = join(await getDatabasesPath(), 'thrive_v2.db');
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
    final existing = await db.query('checkins',
        where: 'date = ?', whereArgs: [c.date], limit: 1);
    if (existing.isNotEmpty) {
      return db.update('checkins', c.toMap()..remove('id'),
          where: 'date = ?', whereArgs: [c.date]);
    }
    return db.insert('checkins', c.toMap());
  }

  Future<DailyCheckIn?> getCheckIn(String date) async {
    final db = await database;
    final r = await db.query('checkins',
        where: 'date = ?', whereArgs: [date], limit: 1);
    return r.isEmpty ? null : DailyCheckIn.fromMap(r.first);
  }

  Future<List<DailyCheckIn>> getWeekCheckIns() async {
    final db = await database;
    final d = DateTime.now().subtract(const Duration(days: 7));
    final r = await db.query('checkins',
        where: 'date >= ?',
        whereArgs: [d.toIso8601String().substring(0, 10)],
        orderBy: 'date ASC');
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
    final r = await db.query('advice',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'created_at DESC',
        limit: 1);
    return r.isEmpty ? null : AIAdvice.fromMap(r.first);
  }

  Future<List<AIAdvice>> getAdviceHistory() async {
    final db = await database;
    final r = await db.query('advice',
        orderBy: 'created_at DESC', limit: 20);
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
      final expected = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final check = DateTime.parse(all[i].date);
      if (check.year == expected.year &&
          check.month == expected.month &&
          check.day == expected.day) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
