import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';

class GamificationState {
  final int totalXP;
  final int level;
  final int xpInLevel;
  final int xpNeededForLevel;
  final int plantStage;
  final List<String> unlockedIds;
  final bool isLoading;

  const GamificationState({
    this.totalXP = 0,
    this.level = 1,
    this.xpInLevel = 0,
    this.xpNeededForLevel = 100,
    this.plantStage = 0,
    this.unlockedIds = const [],
    this.isLoading = false,
  });

  double get levelProgress =>
      xpNeededForLevel == 0 ? 0 : xpInLevel / xpNeededForLevel;

  GamificationState copyWith({
    int? totalXP,
    int? level,
    int? xpInLevel,
    int? xpNeededForLevel,
    int? plantStage,
    List<String>? unlockedIds,
    bool? isLoading,
  }) =>
      GamificationState(
        totalXP: totalXP ?? this.totalXP,
        level: level ?? this.level,
        xpInLevel: xpInLevel ?? this.xpInLevel,
        xpNeededForLevel: xpNeededForLevel ?? this.xpNeededForLevel,
        plantStage: plantStage ?? this.plantStage,
        unlockedIds: unlockedIds ?? this.unlockedIds,
        isLoading: isLoading ?? this.isLoading,
      );
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier(this._service) : super(const GamificationState()) {
    load();
  }

  final GamificationService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final xp = await _service.getTotalXP();
    final ids = await _service.getUnlockedIds();
    final streak = await _service.getCurrentStreak();
    final level = GamificationService.levelFromXP(xp);
    state = GamificationState(
      totalXP: xp,
      level: level,
      xpInLevel: GamificationService.xpInCurrentLevel(xp),
      xpNeededForLevel: GamificationService.xpRequiredForLevel(xp),
      plantStage: GamificationService.plantStageFromStreak(streak),
      unlockedIds: ids,
      isLoading: false,
    );
  }

  Future<List<Achievement>> awardXP(String type, int xp,
      {String? description}) async {
    final newAchievements =
        await _service.awardXP(type, xp, description: description);
    await load();
    return newAchievements;
  }
}

final gamificationServiceProvider = Provider<GamificationService>(
  (_) => GamificationService.instance,
);

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>(
  (ref) => GamificationNotifier(ref.read(gamificationServiceProvider)),
);
