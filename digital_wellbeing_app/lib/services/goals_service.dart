import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class Goal {
  final int? id;
  final String goalType;
  final int targetMs;
  final String? category;
  final bool isActive;
  final int createdAt;

  const Goal({
    this.id,
    required this.goalType,
    required this.targetMs,
    this.category,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'goal_type': goalType,
        'target_ms': targetMs,
        'category': category,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  static Goal fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as int?,
        goalType: map['goal_type'] as String,
        targetMs: map['target_ms'] as int,
        category: map['category'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as int,
      );
}

class Streak {
  final int goalId;
  final int current;
  final int longest;
  final String? lastSuccessDate;
  final int freezeUsed;

  const Streak({
    required this.goalId,
    required this.current,
    required this.longest,
    this.lastSuccessDate,
    this.freezeUsed = 0,
  });

  static Streak fromMap(Map<String, dynamic> map) => Streak(
        goalId: map['goal_id'] as int,
        current: map['current_streak'] as int,
        longest: map['longest_streak'] as int,
        lastSuccessDate: map['last_success_date'] as String?,
        freezeUsed: map['freeze_used'] as int? ?? 0,
      );

  int get freezesRemaining => 2 - freezeUsed;
}

class SleepSchedule {
  final int? id;
  final String name;
  final String bedtime;
  final String wakeTime;
  final int gracePeriodMins;
  final bool blueLightReminderEnabled;
  final String blueLightReminderTime;
  final bool isActive;
  final String daysOfWeek;

  const SleepSchedule({
    this.id,
    required this.name,
    required this.bedtime,
    required this.wakeTime,
    this.gracePeriodMins = 0,
    this.blueLightReminderEnabled = false,
    this.blueLightReminderTime = '20:00',
    this.isActive = false,
    this.daysOfWeek = '1111111',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'bedtime': bedtime,
        'wake_time': wakeTime,
        'grace_period_mins': gracePeriodMins,
        'blue_light_reminder': blueLightReminderEnabled ? 1 : 0,
        'blue_light_time': blueLightReminderTime,
        'is_active': isActive ? 1 : 0,
        'days_of_week': daysOfWeek,
      };

  static SleepSchedule fromMap(Map<String, dynamic> map) => SleepSchedule(
        id: map['id'] as int?,
        name: map['name'] as String,
        bedtime: map['bedtime'] as String,
        wakeTime: map['wake_time'] as String,
        gracePeriodMins: map['grace_period_mins'] as int? ?? 0,
        blueLightReminderEnabled:
            (map['blue_light_reminder'] as int? ?? 0) == 1,
        blueLightReminderTime:
            map['blue_light_time'] as String? ?? '20:00',
        isActive: (map['is_active'] as int) == 1,
        daysOfWeek: map['days_of_week'] as String? ?? '1111111',
      );

  SleepSchedule copyWith({
    String? name,
    String? bedtime,
    String? wakeTime,
    int? gracePeriodMins,
    bool? blueLightReminderEnabled,
    String? blueLightReminderTime,
    bool? isActive,
    String? daysOfWeek,
  }) =>
      SleepSchedule(
        id: id,
        name: name ?? this.name,
        bedtime: bedtime ?? this.bedtime,
        wakeTime: wakeTime ?? this.wakeTime,
        gracePeriodMins: gracePeriodMins ?? this.gracePeriodMins,
        blueLightReminderEnabled:
            blueLightReminderEnabled ?? this.blueLightReminderEnabled,
        blueLightReminderTime:
            blueLightReminderTime ?? this.blueLightReminderTime,
        isActive: isActive ?? this.isActive,
        daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      );
}

class GoalsService {
  final DatabaseService _db = DatabaseService.instance;

  // ── Goals ──────────────────────────────────────────────────────────────────

  Future<Goal?> getDailyTotalGoal() async {
    final db = await _db.database;
    final rows = await db.query(
      'goals',
      where: "goal_type = ? AND is_active = 1",
      whereArgs: ['daily_total'],
      limit: 1,
    );
    return rows.isEmpty ? null : Goal.fromMap(rows.first);
  }

  Future<int> saveDailyTotalGoal(Duration target) async {
    final db = await _db.database;
    final existing = await getDailyTotalGoal();
    if (existing != null) {
      await db.update(
        'goals',
        {'target_ms': target.inMilliseconds},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }
    final id = await db.insert('goals', {
      'goal_type': 'daily_total',
      'target_ms': target.inMilliseconds,
      'is_active': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.insert(
      'streaks',
      {
        'goal_id': id,
        'current_streak': 0,
        'longest_streak': 0,
        'freeze_used': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id;
  }

  Future<void> deleteGoal(int goalId) async {
    final db = await _db.database;
    await db.update('goals', {'is_active': 0},
        where: 'id = ?', whereArgs: [goalId]);
  }

  // ── Streaks ────────────────────────────────────────────────────────────────

  Future<Streak?> getStreak(int goalId) async {
    final db = await _db.database;
    final rows = await db
        .query('streaks', where: 'goal_id = ?', whereArgs: [goalId]);
    return rows.isEmpty ? null : Streak.fromMap(rows.first);
  }

  Future<void> recordDayResult({
    required int goalId,
    required bool success,
    required String date,
  }) async {
    final db = await _db.database;
    final streak = await getStreak(goalId);
    if (streak == null) return;
    if (success) {
      final newCurrent = streak.current + 1;
      await db.update(
        'streaks',
        {
          'current_streak': newCurrent,
          'longest_streak':
              newCurrent > streak.longest ? newCurrent : streak.longest,
          'last_success_date': date,
        },
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );
    } else {
      await db.update(
        'streaks',
        {'current_streak': 0},
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );
    }
  }

  Future<bool> useFreeze(int goalId) async {
    final db = await _db.database;
    final streak = await getStreak(goalId);
    if (streak == null || streak.freezeUsed >= 2) return false;
    await db.update(
      'streaks',
      {'freeze_used': streak.freezeUsed + 1},
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    return true;
  }

  // ── Sleep Schedules ────────────────────────────────────────────────────────

  Future<SleepSchedule?> getActiveSleepSchedule() async {
    final db = await _db.database;
    final rows =
        await db.query('sleep_schedules', where: 'is_active = 1', limit: 1);
    return rows.isEmpty ? null : SleepSchedule.fromMap(rows.first);
  }

  Future<List<SleepSchedule>> getAllSleepSchedules() async {
    final db = await _db.database;
    final rows = await db.query('sleep_schedules', orderBy: 'id ASC');
    return rows.map(SleepSchedule.fromMap).toList();
  }

  Future<int> saveSleepSchedule(SleepSchedule schedule) async {
    final db = await _db.database;
    if (schedule.isActive) {
      await db.update('sleep_schedules', {'is_active': 0});
    }
    if (schedule.id != null) {
      await db.update(
        'sleep_schedules',
        schedule.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
      return schedule.id!;
    }
    final map = schedule.toMap()..remove('id');
    return db.insert('sleep_schedules', map);
  }

  Future<void> deleteSleepSchedule(int id) async {
    final db = await _db.database;
    await db.delete('sleep_schedules', where: 'id = ?', whereArgs: [id]);
  }
}
