import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/time_service.dart';
import '../providers/rules_provider.dart';

/// Provider that checks if settings are currently locked
final settingsLockProvider =
    StateNotifierProvider<SettingsLockNotifier, SettingsLockState>((ref) {
      return SettingsLockNotifier(ref);
    });

/// State representing settings lock status
class SettingsLockState {
  final bool isLocked;
  final DateTime? unlockTime;
  final Duration? timeUntilUnlock;
  final String lockMessage;

  const SettingsLockState({
    required this.isLocked,
    this.unlockTime,
    this.timeUntilUnlock,
    this.lockMessage = '',
  });

  factory SettingsLockState.unlocked() {
    return const SettingsLockState(
      isLocked: false,
      lockMessage: 'Settings are currently unlocked',
    );
  }

  factory SettingsLockState.locked({
    required DateTime unlockTime,
    required Duration timeUntilUnlock,
  }) {
    final hours = timeUntilUnlock.inHours;
    final minutes = timeUntilUnlock.inMinutes % 60;

    String message;
    if (hours > 0) {
      message =
          'Settings locked for $hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    } else if (minutes > 0) {
      message = 'Settings locked for $minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      message = 'Settings locked (unlocking soon)';
    }

    return SettingsLockState(
      isLocked: true,
      unlockTime: unlockTime,
      timeUntilUnlock: timeUntilUnlock,
      lockMessage: message,
    );
  }

  SettingsLockState copyWith({
    bool? isLocked,
    DateTime? unlockTime,
    Duration? timeUntilUnlock,
    String? lockMessage,
  }) {
    return SettingsLockState(
      isLocked: isLocked ?? this.isLocked,
      unlockTime: unlockTime ?? this.unlockTime,
      timeUntilUnlock: timeUntilUnlock ?? this.timeUntilUnlock,
      lockMessage: lockMessage ?? this.lockMessage,
    );
  }
}

/// Notifier that manages settings lock state and countdown timer
class SettingsLockNotifier extends StateNotifier<SettingsLockState> {
  final Ref ref;
  Timer? _timer;

  SettingsLockNotifier(this.ref) : super(SettingsLockState.unlocked()) {
    _startTimer();
  }

  /// Start a timer that updates lock state every minute
  void _startTimer() {
    _updateLockState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLockState();
    });
  }

  /// Update lock state based on current time and rules
  void _updateLockState() {
    try {
      final rules = ref.read(rulesProvider);

      print(
        '[SettingsLock] Checking lock state. Enforcement: ${rules.isEnforcementEnabled}, Times: ${rules.restrictionStartTime} - ${rules.restrictionEndTime}',
      );

      // If enforcement is not active, settings are always unlocked
      if (!rules.isEnforcementEnabled) {
        state = SettingsLockState.unlocked();
        return;
      }

      final now = DateTime.now();
      final isInRestriction = TimeService.isWithinRestriction(
        now,
        rules.restrictionStartTime,
        rules.restrictionEndTime,
      );

      print(
        '[SettingsLock] Current time: ${now.hour}:${now.minute}, In restriction: $isInRestriction',
      );

      if (!isInRestriction) {
        state = SettingsLockState.unlocked();
        return;
      }

      // Calculate unlock time
      final unlockTime = TimeService.getNextUnlockTime(
        now,
        rules.restrictionStartTime,
        rules.restrictionEndTime,
      );

      final timeUntilUnlock = unlockTime.difference(now);

      state = SettingsLockState.locked(
        unlockTime: unlockTime,
        timeUntilUnlock: timeUntilUnlock,
      );

      print(
        '[SettingsLock] LOCKED until ${unlockTime.hour}:${unlockTime.minute}',
      );
    } catch (e) {
      print('[SettingsLock] Error updating lock state: $e');
      // On error, default to unlocked to prevent lockout
      state = SettingsLockState.unlocked();
    }
  }

  /// Force immediate update of lock state
  void refresh() {
    _updateLockState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for formatted countdown string
final countdownStringProvider = Provider<String>((ref) {
  final lockState = ref.watch(settingsLockProvider);

  if (!lockState.isLocked || lockState.timeUntilUnlock == null) {
    return '';
  }

  final duration = lockState.timeUntilUnlock!;
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')} remaining';
  } else if (minutes > 0) {
    return '$minutes minute${minutes != 1 ? 's' : ''} remaining';
  } else {
    return 'Unlocking soon...';
  }
});

/// Provider to check if settings modification is allowed
final canModifySettingsProvider = Provider<bool>((ref) {
  final lockState = ref.watch(settingsLockProvider);
  return !lockState.isLocked;
});
