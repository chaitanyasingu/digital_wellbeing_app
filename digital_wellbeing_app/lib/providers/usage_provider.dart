import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/usage_service.dart';

final usageServiceProvider = Provider((ref) => UsageService());

// ── Permission ─────────────────────────────────────────────────────────────

class UsagePermissionState {
  final bool hasPermission;
  final bool checked;
  const UsagePermissionState({this.hasPermission = false, this.checked = false});
}

class UsagePermissionNotifier extends StateNotifier<UsagePermissionState> {
  final UsageService _service;
  UsagePermissionNotifier(this._service) : super(const UsagePermissionState()) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    final has = await _service.hasPermission();
    if (mounted) {
      state = UsagePermissionState(hasPermission: has, checked: true);
    }
  }

  Future<void> openSettings() => _service.openSettings();
}

final usagePermissionProvider =
    StateNotifierProvider<UsagePermissionNotifier, UsagePermissionState>((ref) {
  return UsagePermissionNotifier(ref.read(usageServiceProvider));
});

// ── Data providers ─────────────────────────────────────────────────────────

final todayUsageProvider = FutureProvider<List<AppUsageStat>>((ref) {
  return ref.read(usageServiceProvider).getTodayUsage();
});

final weekUsageProvider =
    FutureProvider<Map<DateTime, List<AppUsageStat>>>((ref) {
  return ref.read(usageServiceProvider).getWeekUsage();
});

final totalScreenTimeTodayProvider = FutureProvider<Duration>((ref) {
  return ref.read(usageServiceProvider).getTotalScreenTimeToday();
});

final pickupCountTodayProvider = FutureProvider<int>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return ref.read(usageServiceProvider).getPickupCount(startOfDay, now);
});

final firstPickupTodayProvider = FutureProvider<DateTime?>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return ref.read(usageServiceProvider).getFirstPickupTime(startOfDay, now);
});

final lastPickupTodayProvider = FutureProvider<DateTime?>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return ref.read(usageServiceProvider).getLastPickupTime(startOfDay, now);
});
