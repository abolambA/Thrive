class DailyCheckIn {
  final int? id;
  final String date;
  final double sleepHours;
  final int waterCups;
  final int mealsEaten;
  final int stressLevel;
  final double screenTimeHours;
  final int caffeineCount;
  final String? notes;
  final String createdAt;

  DailyCheckIn({
    this.id,
    required this.date,
    required this.sleepHours,
    required this.waterCups,
    required this.mealsEaten,
    required this.stressLevel,
    required this.screenTimeHours,
    this.caffeineCount = 0,
    this.notes,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'sleep_hours': sleepHours,
    'water_cups': waterCups,
    'meals_eaten': mealsEaten,
    'stress_level': stressLevel,
    'screen_time_hours': screenTimeHours,
    'caffeine_count': caffeineCount,
    'notes': notes,
    'created_at': createdAt,
  };

  factory DailyCheckIn.fromMap(Map<String, dynamic> m) => DailyCheckIn(
    id: m['id'] as int?,
    date: m['date'] as String,
    sleepHours: (m['sleep_hours'] as num).toDouble(),
    waterCups: m['water_cups'] as int,
    mealsEaten: m['meals_eaten'] as int,
    stressLevel: m['stress_level'] as int,
    screenTimeHours: (m['screen_time_hours'] as num).toDouble(),
    caffeineCount: m['caffeine_count'] as int? ?? 0,
    notes: m['notes'] as String?,
    createdAt: m['created_at'] as String,
  );
}
