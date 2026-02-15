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
          print(
            '[RulesProvider] Loaded rules: ${rules.alwaysAllowedApps.length} apps, ${rules.restrictionStartTime} - ${rules.restrictionEndTime}',
          );
        }
      } catch (e) {
        print('Failed to load saved rules: $e');
      }
    });
  }

  /// Reload rules from storage (useful after navigation back)
  Future<void> reloadRules() async {
    try {
      final rules = await _storageService.loadRules();
      if (mounted) {
        state = rules;
        print(
          '[RulesProvider] Reloaded rules: ${rules.alwaysAllowedApps.length} apps, ${rules.restrictionStartTime} - ${rules.restrictionEndTime}',
        );
      }
    } catch (e) {
      print('[RulesProvider] Failed to reload rules: $e');
    }
  }

  Future<void> updateAllowedApps(List<String> apps) async {
    try {
      print(
        '[RulesProvider] Updating allowed apps. Old count: ${state.alwaysAllowedApps.length}, New count: ${apps.length}',
      );

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

      print(
        '[RulesProvider] State updated. New count: ${state.alwaysAllowedApps.length}',
      );
      print('[RulesProvider] Apps: ${state.alwaysAllowedApps.join(", ")}');
    } catch (e) {
      print('[RulesProvider] Error updating allowed apps: $e');
      // Re-throw for UI to handle
      rethrow;
    }
  }

  Future<void> updateRestrictionTimes(String startTime, String endTime) async {
    try {
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
    } catch (e) {
      // Re-throw for UI to handle
      rethrow;
    }
  }

  Future<void> toggleEnforcement(bool enabled) async {
    try {
      final updatedRules = state.copyWith(isEnforcementEnabled: enabled);
      await _storageService.saveRules(updatedRules);
      state = updatedRules;
    } catch (e) {
      // Re-throw for UI to handle
      rethrow;
    }
  }

  bool isSettingsLocked() {
    if (!state.isEnforcementEnabled) return false;

    return TimeService.isCurrentTimeRestricted(
      state.restrictionStartTime,
      state.restrictionEndTime,
    );
  }
}
