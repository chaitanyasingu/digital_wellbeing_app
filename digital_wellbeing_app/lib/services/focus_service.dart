import 'database_service.dart';

class FocusSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int workMinutes;
  final int breakMinutes;
  final int completedRounds;
  final int totalRounds;
  final String? notes;

  const FocusSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.workMinutes,
    required this.breakMinutes,
    required this.completedRounds,
    required this.totalRounds,
    this.notes,
  });

  Duration get totalFocusTime => Duration(minutes: workMinutes * completedRounds);

  static FocusSession fromMap(Map<String, dynamic> m) => FocusSession(
        id: m['id'] as int?,
        startTime: DateTime.fromMillisecondsSinceEpoch(m['start_time'] as int),
        endTime: m['end_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['end_time'] as int)
            : null,
        workMinutes: m['work_minutes'] as int,
        breakMinutes: m['break_minutes'] as int,
        completedRounds: m['completed_rounds'] as int,
        totalRounds: m['total_rounds'] as int,
        notes: m['notes'] as String?,
      );
}

class FocusService {
  final DatabaseService _db = DatabaseService.instance;

  Future<int> startSession({
    required int workMinutes,
    required int breakMinutes,
    required int totalRounds,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _db.insertFocusSession({
      'start_time': now,
      'work_minutes': workMinutes,
      'break_minutes': breakMinutes,
      'completed_rounds': 0,
      'total_rounds': totalRounds,
      'created_at': now,
    });
  }

  Future<void> completeSession(
    int id, {
    required int completedRounds,
    String? notes,
  }) async {
    final values = <String, dynamic>{
      'end_time': DateTime.now().millisecondsSinceEpoch,
      'completed_rounds': completedRounds,
    };
    if (notes != null) values['notes'] = notes;
    await _db.updateFocusSession(id, values);
  }

  Future<List<FocusSession>> getSessionsForToday() async {
    final now = DateTime.now();
    final ymd =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final rows = await _db.getFocusSessionsForDate(ymd);
    return rows.map(FocusSession.fromMap).toList();
  }

  Future<int> getTodayFocusMinutes() async {
    final sessions = await getSessionsForToday();
    return sessions.fold<int>(
        0, (sum, s) => sum + s.workMinutes * s.completedRounds);
  }
}
