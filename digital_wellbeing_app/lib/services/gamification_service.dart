import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;
  final String category;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.category,
  });
}

class GamificationService {
  static final instance = GamificationService._internal();
  GamificationService._internal();

  final _db = DatabaseService.instance;

  static const String xpFocusSession = 'focus_session';
  static const String xpDailyGoalMet = 'daily_goal_met';
  static const String xpMoodLogged = 'mood_logged';
  static const String xpAchievement = 'achievement_unlocked';

  static const allAchievements = <Achievement>[
    Achievement(id: 'first_focus', name: 'First Steps', description: 'Complete your first focus session', icon: '🎯', xpReward: 50, category: 'focus'),
    Achievement(id: 'focus_5', name: 'Deep Work', description: 'Complete 5 focus sessions', icon: '🎓', xpReward: 100, category: 'focus'),
    Achievement(id: 'focus_25', name: 'Flow State', description: 'Complete 25 focus sessions', icon: '🌊', xpReward: 250, category: 'focus'),
    Achievement(id: 'focus_10h', name: 'Centurion', description: 'Log 10 hours of total focus time', icon: '💪', xpReward: 300, category: 'focus'),
    Achievement(id: 'early_bird', name: 'Early Bird', description: 'Start a focus session before 8 AM', icon: '🌅', xpReward: 50, category: 'focus'),
    Achievement(id: 'night_owl', name: 'Night Owl', description: 'Start a focus session after 10 PM', icon: '🦉', xpReward: 50, category: 'focus'),
    Achievement(id: 'first_mood', name: 'Inner Compass', description: 'Log your mood for the first time', icon: '🪞', xpReward: 25, category: 'mood'),
    Achievement(id: 'mood_7', name: 'Reflective', description: 'Log mood on 7 different days', icon: '📔', xpReward: 100, category: 'mood'),
    Achievement(id: 'streak_3', name: 'Consistent', description: 'Achieve a 3-day goal streak', icon: '🔥', xpReward: 75, category: 'streak'),
    Achievement(id: 'streak_7', name: 'Week Warrior', description: 'Achieve a 7-day goal streak', icon: '⚔️', xpReward: 150, category: 'streak'),
    Achievement(id: 'streak_30', name: 'Zen Master', description: 'Achieve a 30-day goal streak', icon: '🧘', xpReward: 500, category: 'streak'),
    Achievement(id: 'level_5', name: 'Mindfulness Pro', description: 'Reach Level 5', icon: '⭐', xpReward: 200, category: 'level'),
  ];

  // ── Level math ──────────────────────────────────────────────────────────

  static int levelFromXP(int xp) {
    int level = 1;
    int threshold = 0;
    while (xp >= threshold + 100 * level) {
      threshold += 100 * level;
      level++;
    }
    return level;
  }

  static int xpInCurrentLevel(int xp) {
    int level = 1;
    int threshold = 0;
    while (xp >= threshold + 100 * level) {
      threshold += 100 * level;
      level++;
    }
    return xp - threshold;
  }

  static int xpRequiredForLevel(int xp) => 100 * levelFromXP(xp);

  // ── Plant ───────────────────────────────────────────────────────────────

  static int plantStageFromStreak(int streak) {
    if (streak <= 0) return 0;
    if (streak <= 2) return 1;
    if (streak <= 6) return 2;
    if (streak <= 13) return 3;
    if (streak <= 29) return 4;
    return 5;
  }

  static String plantEmoji(int stage) => switch (stage) {
        0 => '🪴',
        1 => '🌱',
        2 => '🌿',
        3 => '🌻',
        4 => '🌺',
        _ => '🌳',
      };

  static String plantLabel(int stage) => switch (stage) {
        0 => 'Empty Pot',
        1 => 'Seedling',
        2 => 'Sprouting',
        3 => 'Blooming',
        4 => 'Flourishing',
        _ => 'Mighty Tree',
      };

  static int streakForNextPlantStage(int streak) {
    if (streak <= 0) return 1;
    if (streak <= 2) return 3;
    if (streak <= 6) return 7;
    if (streak <= 13) return 14;
    if (streak <= 29) return 30;
    return -1; // max stage
  }

  // ── Active profile ──────────────────────────────────────────────────────

  Future<int> activeProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('active_profile_id') ?? 1;
  }

  Future<void> setActiveProfileId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_profile_id', id);
  }

  // ── XP awarding ─────────────────────────────────────────────────────────

  // Returns newly unlocked achievements.
  Future<List<Achievement>> awardXP(
    String eventType,
    int xp, {
    String? description,
    int? profileId,
  }) async {
    final id = profileId ?? await activeProfileId();
    await _db.insertXpEvent({
      'profile_id': id,
      'event_type': eventType,
      'xp_earned': xp,
      'description': description,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return _checkAchievements(id);
  }

  // ── Queries ─────────────────────────────────────────────────────────────

  Future<int> getTotalXP({int? profileId}) async {
    final id = profileId ?? await activeProfileId();
    return await _db.sumXpForProfile(id);
  }

  Future<List<String>> getUnlockedIds({int? profileId}) async {
    final id = profileId ?? await activeProfileId();
    return await _db.getUnlockedAchievementIds(id);
  }

  Future<int> getCurrentStreak() => _db.getMaxCurrentStreak();

  // ── Achievement checking ─────────────────────────────────────────────────

  Future<List<Achievement>> _checkAchievements(int profileId) async {
    final alreadyUnlocked = await getUnlockedIds(profileId: profileId);
    final newlyUnlocked = <Achievement>[];

    final focusSessions = await _db.countCompletedFocusSessions();
    final focusMinutes = await _db.sumFocusMinutes();
    final moodDays = await _db.countDistinctMoodDays();
    final streak = await _db.getMaxCurrentStreak();
    final totalXP = await getTotalXP(profileId: profileId);
    final level = levelFromXP(totalXP);
    final hour = DateTime.now().hour;

    for (final a in allAchievements) {
      if (alreadyUnlocked.contains(a.id)) continue;
      final unlocked = switch (a.id) {
        'first_focus'  => focusSessions >= 1,
        'focus_5'      => focusSessions >= 5,
        'focus_25'     => focusSessions >= 25,
        'focus_10h'    => focusMinutes >= 600,
        'early_bird'   => hour < 8 && focusSessions >= 1,
        'night_owl'    => hour >= 22 && focusSessions >= 1,
        'first_mood'   => moodDays >= 1,
        'mood_7'       => moodDays >= 7,
        'streak_3'     => streak >= 3,
        'streak_7'     => streak >= 7,
        'streak_30'    => streak >= 30,
        'level_5'      => level >= 5,
        _              => false,
      };
      if (!unlocked) continue;

      await _db.insertAchievementUnlock({
        'achievement_id': a.id,
        'profile_id': profileId,
        'unlocked_at': DateTime.now().millisecondsSinceEpoch,
        'xp_awarded': a.xpReward,
      });
      await _db.insertXpEvent({
        'profile_id': profileId,
        'event_type': xpAchievement,
        'xp_earned': a.xpReward,
        'description': a.name,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      newlyUnlocked.add(a);
    }
    return newlyUnlocked;
  }
}
