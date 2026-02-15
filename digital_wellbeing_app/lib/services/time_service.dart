class TimeService {
  /// Check if current time is within restriction window
  /// Returns true if current time is restricted
  static bool isCurrentTimeRestricted(String startTime, String endTime) {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    
    final start = _parseTimeString(startTime);
    final end = _parseTimeString(endTime);
    
    // If start < end (e.g., 09:00 to 17:00)
    if (start.hour < end.hour || (start.hour == end.hour && start.minute < end.minute)) {
      return _isTimeBetween(currentTime, start, end);
    }
    
    // If start > end (crosses midnight, e.g., 21:00 to 10:00)
    return !_isTimeBetween(currentTime, end, start);
  }

  static TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String getNextUnlockTime(String startTime, String endTime) {
    if (!isCurrentTimeRestricted(startTime, endTime)) {
      return 'Not restricted';
    }
    
    final end = _parseTimeString(endTime);
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});
}
