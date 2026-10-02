import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/focus_service.dart';

enum FocusPhase { idle, working, breaking, paused }

class FocusTimerState {
  final FocusPhase phase;
  final int remainingSeconds;
  final int currentRound;
  final int totalRounds;
  final int workMinutes;
  final int breakMinutes;
  final int? currentSessionId;
  final List<FocusSession> todaySessions;
  final bool isPausedDuringWork;

  const FocusTimerState({
    required this.phase,
    required this.remainingSeconds,
    required this.currentRound,
    required this.totalRounds,
    required this.workMinutes,
    required this.breakMinutes,
    this.currentSessionId,
    this.todaySessions = const [],
    this.isPausedDuringWork = false,
  });

  static FocusTimerState idle({List<FocusSession> todaySessions = const []}) =>
      FocusTimerState(
        phase: FocusPhase.idle,
        remainingSeconds: 25 * 60,
        currentRound: 1,
        totalRounds: 4,
        workMinutes: 25,
        breakMinutes: 5,
        todaySessions: todaySessions,
      );

  double get progress {
    final total = phase == FocusPhase.working || isPausedDuringWork
        ? workMinutes * 60
        : breakMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (remainingSeconds / total);
  }

  int get todayFocusMinutes => todaySessions.fold<int>(
      0, (sum, s) => sum + s.workMinutes * s.completedRounds);

  FocusTimerState copyWith({
    FocusPhase? phase,
    int? remainingSeconds,
    int? currentRound,
    int? totalRounds,
    int? workMinutes,
    int? breakMinutes,
    int? currentSessionId,
    List<FocusSession>? todaySessions,
    bool? isPausedDuringWork,
  }) =>
      FocusTimerState(
        phase: phase ?? this.phase,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        currentRound: currentRound ?? this.currentRound,
        totalRounds: totalRounds ?? this.totalRounds,
        workMinutes: workMinutes ?? this.workMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        currentSessionId: currentSessionId ?? this.currentSessionId,
        todaySessions: todaySessions ?? this.todaySessions,
        isPausedDuringWork: isPausedDuringWork ?? this.isPausedDuringWork,
      );
}

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  final FocusService _service;
  Timer? _timer;

  FocusTimerNotifier(this._service) : super(FocusTimerState.idle()) {
    _loadTodaySessions();
  }

  Future<void> _loadTodaySessions() async {
    final sessions = await _service.getSessionsForToday();
    state = state.copyWith(todaySessions: sessions);
  }

  Future<void> startSession({
    int work = 25,
    int breakMins = 5,
    int rounds = 4,
  }) async {
    _timer?.cancel();

    final id = await _service.startSession(
      workMinutes: work,
      breakMinutes: breakMins,
      totalRounds: rounds,
    );

    state = FocusTimerState(
      phase: FocusPhase.working,
      remainingSeconds: work * 60,
      currentRound: 1,
      totalRounds: rounds,
      workMinutes: work,
      breakMinutes: breakMins,
      currentSessionId: id,
      todaySessions: state.todaySessions,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (state.phase != FocusPhase.working && state.phase != FocusPhase.breaking) return;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      phase: FocusPhase.paused,
      isPausedDuringWork: state.phase == FocusPhase.working,
    );
  }

  void resume() {
    if (state.phase != FocusPhase.paused) return;
    final nextPhase =
        state.isPausedDuringWork ? FocusPhase.working : FocusPhase.breaking;
    state = state.copyWith(phase: nextPhase);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> skipPhase() async {
    _timer?.cancel();
    _timer = null;
    await _onPhaseComplete(skipped: true);
  }

  Future<void> stopSession() async {
    _timer?.cancel();
    _timer = null;

    final id = state.currentSessionId;
    if (id != null) {
      final completed = state.currentRound - 1;
      await _service.completeSession(id, completedRounds: completed);
    }

    await _loadTodaySessions();
    state = FocusTimerState.idle(todaySessions: state.todaySessions);
  }

  void _tick() {
    if (state.remainingSeconds <= 1) {
      _timer?.cancel();
      _timer = null;
      _onPhaseComplete(skipped: false);
    } else {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    }
  }

  Future<void> _onPhaseComplete({required bool skipped}) async {
    if (state.phase == FocusPhase.working || state.phase == FocusPhase.paused && state.isPausedDuringWork) {
      // Work round done
      final completedRound = state.currentRound;

      if (completedRound >= state.totalRounds) {
        // All rounds done — finish session
        final id = state.currentSessionId;
        if (id != null) {
          await _service.completeSession(id,
              completedRounds: state.totalRounds);
        }
        await _loadTodaySessions();
        state = FocusTimerState.idle(todaySessions: state.todaySessions);
        return;
      }

      // Move to break
      state = state.copyWith(
        phase: FocusPhase.breaking,
        remainingSeconds: state.breakMinutes * 60,
        isPausedDuringWork: false,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      // Break done — start next work round
      final nextRound = state.currentRound + 1;
      state = state.copyWith(
        phase: FocusPhase.working,
        remainingSeconds: state.workMinutes * 60,
        currentRound: nextRound,
        isPausedDuringWork: false,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusServiceProvider = Provider((ref) => FocusService());

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>(
  (ref) => FocusTimerNotifier(ref.read(focusServiceProvider)),
);
