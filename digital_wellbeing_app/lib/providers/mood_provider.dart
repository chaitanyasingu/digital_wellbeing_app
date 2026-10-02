import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mood_service.dart';
import '../services/gamification_service.dart';
import 'gamification_provider.dart';

class MoodState {
  final MoodEntry? todayMood;
  final List<MoodEntry> recentMoods;
  final bool isLoading;

  const MoodState({
    this.todayMood,
    this.recentMoods = const [],
    this.isLoading = true,
  });

  MoodState copyWith({
    MoodEntry? todayMood,
    bool clearTodayMood = false,
    List<MoodEntry>? recentMoods,
    bool? isLoading,
  }) =>
      MoodState(
        todayMood: clearTodayMood ? null : (todayMood ?? this.todayMood),
        recentMoods: recentMoods ?? this.recentMoods,
        isLoading: isLoading ?? this.isLoading,
      );
}

class MoodNotifier extends StateNotifier<MoodState> {
  final MoodService _service;
  final Ref _ref;

  MoodNotifier(this._service, this._ref) : super(const MoodState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final today = await _service.getMoodForToday();
    final recent = await _service.getRecentMoods(days: 7);
    state = MoodState(
      todayMood: today,
      recentMoods: recent,
      isLoading: false,
    );
  }

  Future<void> saveMood(int score, {String? note}) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final entry = MoodEntry(
      date: dateStr,
      moodScore: score,
      note: note,
      createdAt: now,
    );
    final isNew = state.todayMood == null;
    await _service.upsertMood(entry);
    if (isNew) {
      _ref.read(gamificationProvider.notifier).awardXP(
            GamificationService.xpMoodLogged,
            10,
            description: 'Mood logged',
          );
    }
    await load();
  }
}

final moodServiceProvider = Provider((ref) => MoodService());

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>(
  (ref) => MoodNotifier(ref.read(moodServiceProvider), ref),
);
