import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hardmode_service.dart';
import '../services/enforcement_service.dart';

class HardmodeState {
  final bool isEnabled;
  final bool hasPin;
  final List<CommitmentContract> contracts;
  final CommitmentContract? activeContract;
  final bool isLoading;

  const HardmodeState({
    this.isEnabled = false,
    this.hasPin = false,
    this.contracts = const [],
    this.activeContract,
    this.isLoading = false,
  });

  bool get contractActive => activeContract != null;

  HardmodeState copyWith({
    bool? isEnabled,
    bool? hasPin,
    List<CommitmentContract>? contracts,
    CommitmentContract? activeContract,
    bool clearActiveContract = false,
    bool? isLoading,
  }) =>
      HardmodeState(
        isEnabled: isEnabled ?? this.isEnabled,
        hasPin: hasPin ?? this.hasPin,
        contracts: contracts ?? this.contracts,
        activeContract:
            clearActiveContract ? null : (activeContract ?? this.activeContract),
        isLoading: isLoading ?? this.isLoading,
      );
}

class HardmodeNotifier extends StateNotifier<HardmodeState> {
  final HardmodeService _svc = HardmodeService();
  final EnforcementService _enforcement = EnforcementService();

  HardmodeNotifier() : super(const HardmodeState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final enabled = await _svc.isHardmodeEnabled();
    final pinSet = await _svc.hasPin();
    final contracts = await _svc.getContracts();
    final active = await _svc.getActiveContract();
    state = state.copyWith(
      isEnabled: enabled,
      hasPin: pinSet,
      contracts: contracts,
      activeContract: active,
      clearActiveContract: active == null,
      isLoading: false,
    );
    await _syncFlags();
  }

  Future<void> _syncFlags() async {
    await _enforcement.updateContextFlags(
      hardmodeEnabled: state.isEnabled,
      contractActive: state.contractActive,
    );
  }

  /// Returns true if PIN is correct (or no PIN is set).
  Future<bool> verifyPin(String pin) => _svc.verifyPin(pin);

  Future<void> enableHardmode(String pin) async {
    await _svc.enableHardmode(pin);
    state = state.copyWith(isEnabled: true, hasPin: true);
    await _syncFlags();
  }

  Future<void> disableHardmode() async {
    await _svc.disableHardmode();
    state = state.copyWith(isEnabled: false, hasPin: false);
    await _syncFlags();
  }

  Future<void> addContract(
      String name, DateTime start, DateTime end) async {
    await _svc.addContract(name, start, end);
    await load();
  }

  Future<void> cancelContract(int id) async {
    await _svc.cancelContract(id);
    await load();
  }

  /// Call periodically (e.g. on app resume) to re-check contract expiry.
  Future<void> refreshContractStatus() async {
    final active = await _svc.getActiveContract();
    final hadContract = state.contractActive;
    state = state.copyWith(
      activeContract: active,
      clearActiveContract: active == null,
    );
    if (hadContract != state.contractActive) {
      await _syncFlags();
    }
  }
}

final hardmodeProvider =
    StateNotifierProvider<HardmodeNotifier, HardmodeState>(
  (_) => HardmodeNotifier(),
);
