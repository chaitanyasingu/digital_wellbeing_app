import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/step_counter_service.dart';

class StepCounterState {
  final bool isAvailable;
  final bool hasPermission;
  final int stepsToday; // -1 = not loaded / unavailable
  final bool isLoading;

  const StepCounterState({
    this.isAvailable = false,
    this.hasPermission = false,
    this.stepsToday = -1,
    this.isLoading = false,
  });

  StepCounterState copyWith({
    bool? isAvailable,
    bool? hasPermission,
    int? stepsToday,
    bool? isLoading,
  }) =>
      StepCounterState(
        isAvailable: isAvailable ?? this.isAvailable,
        hasPermission: hasPermission ?? this.hasPermission,
        stepsToday: stepsToday ?? this.stepsToday,
        isLoading: isLoading ?? this.isLoading,
      );
}

class StepCounterNotifier extends StateNotifier<StepCounterState> {
  final StepCounterService _service;

  StepCounterNotifier(this._service) : super(const StepCounterState()) {
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    final available = await _service.isAvailable();
    final permission = await _service.hasPermission();
    state = state.copyWith(isAvailable: available, hasPermission: permission);
    if (available && permission) await refresh();
  }

  Future<void> requestPermission() async {
    await _service.requestPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    final granted = await _service.hasPermission();
    state = state.copyWith(hasPermission: granted);
    if (granted) await refresh();
  }

  Future<void> refresh() async {
    if (!state.isAvailable || !state.hasPermission) return;
    state = state.copyWith(isLoading: true);
    final steps = await _service.getStepsToday();
    state = state.copyWith(stepsToday: steps, isLoading: false);
  }
}

final stepCounterServiceProvider = Provider((ref) => StepCounterService());

final stepCounterProvider =
    StateNotifierProvider<StepCounterNotifier, StepCounterState>(
  (ref) => StepCounterNotifier(ref.read(stepCounterServiceProvider)),
);
