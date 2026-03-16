import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../services/database_service.dart';

class ActivityLogNotifier extends AsyncNotifier<List<ActivityLog>> {
  @override
  Future<List<ActivityLog>> build() => DatabaseService.instance.getActivityLogs();

  Future<void> addLog(ActivityLog log) async {
    await DatabaseService.instance.insertActivityLog(log);
    // Prepend to existing list without full reload
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([log, ...current]);
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await DatabaseService.instance.getActivityLogs());
  }
}

final activityLogProvider =
    AsyncNotifierProvider<ActivityLogNotifier, List<ActivityLog>>(
  ActivityLogNotifier.new,
);
