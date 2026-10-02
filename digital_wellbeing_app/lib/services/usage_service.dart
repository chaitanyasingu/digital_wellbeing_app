import 'package:flutter/services.dart';

class AppUsageStat {
  final String packageName;
  final Duration totalTime;
  final DateTime lastUsed;

  const AppUsageStat({
    required this.packageName,
    required this.totalTime,
    required this.lastUsed,
  });
}

class UsageService {
  static const _channel = MethodChannel('digital_wellbeing/usage_stats');

  static const morningType = 'morning_intention';
  static const eveningType = 'evening_winddown';
  static const summaryType = 'daily_summary';

  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openSettings() async {
    await _channel.invokeMethod('openSettings');
  }

  Future<List<AppUsageStat>> getUsageStats(DateTime start, DateTime end) async {
    try {
      final result = await _channel.invokeMethod<List>('getUsageStats', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (result == null) return [];
      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return AppUsageStat(
          packageName: map['packageName'] as String,
          totalTime: Duration(milliseconds: (map['totalMs'] as num).toInt()),
          lastUsed: DateTime.fromMillisecondsSinceEpoch(
              (map['lastUsed'] as num).toInt()),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getPickupCount(DateTime start, DateTime end) async {
    try {
      return await _channel.invokeMethod<int>('getPickupCount', {
            'startMs': start.millisecondsSinceEpoch,
            'endMs': end.millisecondsSinceEpoch,
          }) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  Future<DateTime?> getFirstPickupTime(DateTime start, DateTime end) async {
    try {
      final ms = await _channel.invokeMethod<int>('getFirstPickupTime', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (ms == null || ms < 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> getLastPickupTime(DateTime start, DateTime end) async {
    try {
      final ms = await _channel.invokeMethod<int>('getLastPickupTime', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (ms == null || ms < 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  Future<List<AppUsageStat>> getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getUsageStats(startOfDay, now);
  }

  Future<Map<DateTime, List<AppUsageStat>>> getWeekUsage() async {
    final result = <DateTime, List<AppUsageStat>>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final endOfDay =
          i == 0 ? now : day.add(const Duration(days: 1));
      result[day] = await getUsageStats(day, endOfDay);
    }
    return result;
  }

  Future<Duration> getTotalScreenTimeToday() async {
    final stats = await getTodayUsage();
    return stats.fold<Duration>(Duration.zero, (sum, s) => sum + s.totalTime);
  }

  Future<void> scheduleSmartNotification({
    required String type,
    required int hour,
    required int minute,
  }) async {
    await _channel.invokeMethod('scheduleSmartNotification', {
      'type': type,
      'hour': hour,
      'minute': minute,
    });
  }

  Future<void> cancelSmartNotification(String type) async {
    await _channel.invokeMethod('cancelSmartNotification', {'type': type});
  }
}
