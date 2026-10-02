import 'database_service.dart';

class MoodEntry {
  final int? id;
  final String date; // "YYYY-MM-DD"
  final int moodScore; // 1–5
  final String? note;
  final int? screenTimeMs;
  final DateTime createdAt;

  const MoodEntry({
    this.id,
    required this.date,
    required this.moodScore,
    this.note,
    this.screenTimeMs,
    required this.createdAt,
  });

  static MoodEntry fromMap(Map<String, dynamic> m) => MoodEntry(
        id: m['id'] as int?,
        date: m['date'] as String,
        moodScore: m['mood_score'] as int,
        note: m['note'] as String?,
        screenTimeMs: m['screen_time_ms'] as int?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  static String emojiFor(int score) {
    switch (score) {
      case 1:
        return '😩';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  static String labelFor(int score) {
    switch (score) {
      case 1:
        return 'Awful';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Okay';
    }
  }
}

class MoodService {
  final DatabaseService _db = DatabaseService.instance;

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> upsertMood(MoodEntry entry) async {
    await _db.upsertMoodEntry({
      'date': entry.date,
      'mood_score': entry.moodScore,
      'note': entry.note,
      'screen_time_ms': entry.screenTimeMs,
      'created_at': entry.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<MoodEntry?> getMoodForToday() async {
    final row = await _db.getMoodEntryForDate(_todayStr());
    return row != null ? MoodEntry.fromMap(row) : null;
  }

  Future<List<MoodEntry>> getRecentMoods({int days = 7}) async {
    final rows = await _db.getRecentMoodEntries(days);
    return rows.map(MoodEntry.fromMap).toList();
  }
}
