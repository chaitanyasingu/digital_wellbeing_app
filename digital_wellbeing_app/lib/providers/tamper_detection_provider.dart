import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/tamper_detection_service.dart';
import '../services/enforcement_service.dart';
import '../services/notification_service.dart';

final tamperDetectionServiceProvider = Provider(
  (ref) => TamperDetectionService(),
);

/// State for tamper detection
class TamperDetectionState {
  final bool hasRecentForceCloses;
  final int forceCloseCount;
  final bool isAccessibilityDisabled;
  final int accessibilityDisabledCount;
  final bool showWarning;

  TamperDetectionState({
    this.hasRecentForceCloses = false,
    this.forceCloseCount = 0,
    this.isAccessibilityDisabled = false,
    this.accessibilityDisabledCount = 0,
    this.showWarning = false,
  });

  TamperDetectionState copyWith({
    bool? hasRecentForceCloses,
    int? forceCloseCount,
    bool? isAccessibilityDisabled,
    int? accessibilityDisabledCount,
    bool? showWarning,
  }) {
    return TamperDetectionState(
      hasRecentForceCloses: hasRecentForceCloses ?? this.hasRecentForceCloses,
      forceCloseCount: forceCloseCount ?? this.forceCloseCount,
      isAccessibilityDisabled:
          isAccessibilityDisabled ?? this.isAccessibilityDisabled,
      accessibilityDisabledCount:
          accessibilityDisabledCount ?? this.accessibilityDisabledCount,
      showWarning: showWarning ?? this.showWarning,
    );
  }
}

/// Notifier that manages tamper detection monitoring
class TamperDetectionNotifier extends StateNotifier<TamperDetectionState> {
  final TamperDetectionService _service;
  final EnforcementService _enforcementService;
  final NotificationService _notificationService;
  Timer? _monitorTimer;
  bool _hasShownAccessibilityNotification = false;

  TamperDetectionNotifier(
    this._service,
    this._enforcementService,
    this._notificationService,
  ) : super(TamperDetectionState()) {
    _startMonitoring();
  }

  /// Start periodic monitoring (every 30 seconds)
  void _startMonitoring() {
    _checkStatus();
    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkStatus();
    });
  }

  /// Check tamper detection status
  Future<void> _checkStatus() async {
    try {
      // Check force-close count
      final forceCloseCount = await _service.getForceCloseCount();
      final hasRecentForceCloses =
          forceCloseCount >= TamperDetectionService.maxForceClosesInWindow;

      // Check accessibility service status
      final isAccessibilityEnabled = await _enforcementService
          .isAccessibilityEnabled();
      final isAccessibilityDisabled = !isAccessibilityEnabled;

      // Get accessibility disabled count
      final accessibilityDisabledCount = await _service
          .getAccessibilityDisabledCount();

      // Determine if we should show warning
      final showWarning = hasRecentForceCloses || isAccessibilityDisabled;

      if (mounted) {
        state = state.copyWith(
          hasRecentForceCloses: hasRecentForceCloses,
          forceCloseCount: forceCloseCount,
          isAccessibilityDisabled: isAccessibilityDisabled,
          accessibilityDisabledCount: accessibilityDisabledCount,
          showWarning: showWarning,
        );
      }

      // Track if accessibility was disabled
      if (isAccessibilityDisabled && !state.isAccessibilityDisabled) {
        await _service.trackAccessibilityDisabled();
        print('[TamperDetection] Accessibility service was disabled!');

        // Notification disabled - user doesn't want tamper warnings
        // if (!_hasShownAccessibilityNotification) {
        //   await _notificationService.showTamperWarning(
        //     title: '⚠️ Service Disabled',
        //     message:
        //         'Digital Mindfulness accessibility service was turned off. '
        //         'Restrictions cannot be enforced until re-enabled.',
        //   );
        //   _hasShownAccessibilityNotification = true;
        // }
      }

      // Reset notification flag when accessibility is re-enabled
      if (isAccessibilityEnabled && _hasShownAccessibilityNotification) {
        _hasShownAccessibilityNotification = false;
      }
    } catch (e) {
      print('[TamperDetection] Error checking status: $e');
    }
  }

  /// Manually refresh status
  Future<void> refresh() async {
    await _checkStatus();
  }

  /// Dismiss warning (doesn't reset tracking, just hides UI warning)
  void dismissWarning() {
    if (mounted) {
      state = state.copyWith(showWarning: false);
    }
  }

  /// Reset all tamper tracking
  Future<void> resetTracking() async {
    await _service.resetAll();
    if (mounted) {
      state = TamperDetectionState();
    }
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}

final tamperDetectionProvider =
    StateNotifierProvider<TamperDetectionNotifier, TamperDetectionState>((ref) {
      final service = ref.read(tamperDetectionServiceProvider);
      final enforcementService = EnforcementService();
      final notificationService = NotificationService();
      return TamperDetectionNotifier(
        service,
        enforcementService,
        notificationService,
      );
    });
