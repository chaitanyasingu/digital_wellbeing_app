import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/goals_service.dart';

final goalsServiceProvider = Provider((ref) => GoalsService());

// ── Daily Goal & Streak ────────────────────────────────────────────────────

class DailyGoalState {
  final Goal? goal;
  final Streak? streak;
  final bool isLoading;

  const DailyGoalState({this.goal, this.streak, this.isLoading = true});
}

class DailyGoalNotifier extends StateNotifier<DailyGoalState> {
  final GoalsService _service;
  DailyGoalNotifier(this._service) : super(const DailyGoalState()) {
    load();
  }

  Future<void> load() async {
    final goal = await _service.getDailyTotalGoal();
    Streak? streak;
    if (goal?.id != null) streak = await _service.getStreak(goal!.id!);
    if (mounted) {
      state = DailyGoalState(goal: goal, streak: streak, isLoading: false);
    }
  }

  Future<void> setDailyGoal(Duration target) async {
    await _service.saveDailyTotalGoal(target);
    await load();
  }

  Future<void> removeGoal() async {
    if (state.goal?.id != null) await _service.deleteGoal(state.goal!.id!);
    if (mounted) state = const DailyGoalState(isLoading: false);
  }

  Future<bool> useFreeze() async {
    if (state.goal?.id == null) return false;
    final ok = await _service.useFreeze(state.goal!.id!);
    if (ok) await load();
    return ok;
  }

  Future<void> recordToday(bool success) async {
    if (state.goal?.id == null) return;
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _service.recordDayResult(
        goalId: state.goal!.id!, success: success, date: date);
    await load();
  }
}

final dailyGoalProvider =
    StateNotifierProvider<DailyGoalNotifier, DailyGoalState>((ref) {
  return DailyGoalNotifier(ref.read(goalsServiceProvider));
});

// ── Sleep Schedule ─────────────────────────────────────────────────────────

class SleepScheduleState {
  final SleepSchedule? active;
  final List<SleepSchedule> all;
  final bool isLoading;

  const SleepScheduleState(
      {this.active, this.all = const [], this.isLoading = true});
}

class SleepScheduleNotifier extends StateNotifier<SleepScheduleState> {
  final GoalsService _service;
  SleepScheduleNotifier(this._service) : super(const SleepScheduleState()) {
    load();
  }

  Future<void> load() async {
    final active = await _service.getActiveSleepSchedule();
    final all = await _service.getAllSleepSchedules();
    if (mounted) {
      state = SleepScheduleState(active: active, all: all, isLoading: false);
    }
  }

  Future<void> save(SleepSchedule schedule) async {
    await _service.saveSleepSchedule(schedule);
    await load();
  }

  Future<void> delete(int id) async {
    await _service.deleteSleepSchedule(id);
    await load();
  }
}

final sleepScheduleProvider =
    StateNotifierProvider<SleepScheduleNotifier, SleepScheduleState>((ref) {
  return SleepScheduleNotifier(ref.read(goalsServiceProvider));
});
