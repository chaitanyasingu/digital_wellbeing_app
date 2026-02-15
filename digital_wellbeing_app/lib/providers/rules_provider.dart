import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restriction_rules.dart';
import '../services/storage_service.dart';
import '../services/time_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

// Simple synchronous state - no AsyncValue, no loading
final rulesProvider = StateNotifierProvider<RulesNotifier, RestrictionRules>((
  ref,
) {
  return RulesNotifier(ref.read(storageServiceProvider));
});

class RulesNotifier extends StateNotifier<RestrictionRules> {
  final StorageService _storageService;

  // Start with default rules immediately - UI shows instantly
  RulesNotifier(this._storageService) : super(RestrictionRules.defaultRules()) {
    // Load saved data in background
    _loadSavedRules();
  }

  void _loadSavedRules() {
    Future.microtask(() async {
      try {
        final rules = await _storageService.loadRules();
        if (mounted) {
          state = rules;
        }
      } catch (e) {
        print('Failed to load saved rules: $e');
      }
    });
  }

  Future<void> updateAllowedApps(List<String> apps) async {
    // Check if settings are locked
    if (state.isEnforcementEnabled &&
        TimeService.isCurrentTimeRestricted(
          state.restrictionStartTime,
          state.restrictionEndTime,
        )) {
      throw Exception('Settings are locked during restriction period');
    }

    final updatedRules = state.copyWith(alwaysAllowedApps: apps);
    await _storageService.saveRules(updatedRules);
    state = updatedRules;
  }

  Future<void> updateRestrictionTimes(String startTime, String endTime) async {
    // Check if settings are locked
    if (state.isEnforcementEnabled &&
        TimeService.isCurrentTimeRestricted(
          state.restrictionStartTime,
          state.restrictionEndTime,
        )) {
      throw Exception('Settings are locked during restriction period');
    }

    final updatedRules = state.copyWith(
      restrictionStartTime: startTime,
      restrictionEndTime: endTime,
    );
    await _storageService.saveRules(updatedRules);
    state = updatedRules;
  }

  Future<void> toggleEnforcement(bool enabled) async {
    final updatedRules = state.copyWith(isEnforcementEnabled: enabled);
    await _storageService.saveRules(updatedRules);
    state = updatedRules;
  }

  bool isSettingsLocked() {
    if (!state.isEnforcementEnabled) return false;

    return TimeService.isCurrentTimeRestricted(
      state.restrictionStartTime,
      state.restrictionEndTime,
    );
  }
}
