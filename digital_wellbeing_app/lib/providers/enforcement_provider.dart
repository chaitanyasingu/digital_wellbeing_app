import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enforcement_service.dart';

final enforcementServiceProvider = Provider((ref) => EnforcementService());

// State for accessibility status
class AccessibilityState {
  final bool isEnabled;
  final bool isLoading;

  AccessibilityState({this.isEnabled = false, this.isLoading = false});

  AccessibilityState copyWith({bool? isEnabled, bool? isLoading}) {
    return AccessibilityState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  final EnforcementService _service;

  AccessibilityNotifier(this._service) : super(AccessibilityState()) {
    // Don't check on initialization - let UI load first
  }

  Future<void> checkStatus() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final isEnabled = await _service.isAccessibilityEnabled();
      if (mounted) {
        state = state.copyWith(isEnabled: isEnabled, isLoading: false);
      }
    } catch (e) {
      print('Error checking accessibility: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

final accessibilityStatusProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilityState>((ref) {
      return AccessibilityNotifier(ref.read(enforcementServiceProvider));
    });
