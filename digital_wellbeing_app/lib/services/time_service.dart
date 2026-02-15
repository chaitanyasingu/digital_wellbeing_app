class TimeService {
  /// Check if current time is within restriction window
  /// Returns true if current time is restricted
  static bool isCurrentTimeRestricted(String startTime, String endTime) {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final start = _parseTimeString(startTime);
    final end = _parseTimeString(endTime);

    // If start < end (e.g., 09:00 to 17:00)
    if (start.hour < end.hour ||
        (start.hour == end.hour && start.minute < end.minute)) {
      return _isTimeBetween(currentTime, start, end);
    }

    // If start > end (crosses midnight, e.g., 21:00 to 10:00)
    return !_isTimeBetween(currentTime, end, start);
  }

  /// Check if a specific DateTime is within restriction window
  /// Takes DateTime and TimeOfDay parameters for more flexible usage
  static bool isWithinRestriction(
    DateTime dateTime,
    String startTimeStr,
    String endTimeStr,
  ) {
    final currentTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    final start = _parseTimeString(startTimeStr);
    final end = _parseTimeString(endTimeStr);

    // If start < end (e.g., 09:00 to 17:00)
    if (start.hour < end.hour ||
        (start.hour == end.hour && start.minute < end.minute)) {
      return _isTimeBetween(currentTime, start, end);
    }

    // If start > end (crosses midnight, e.g., 21:00 to 10:00)
    return !_isTimeBetween(currentTime, end, start);
  }

  /// Get the next unlock time as DateTime
  /// Returns when the restriction period will end
  static DateTime getNextUnlockTime(
    DateTime now,
    String startTimeStr,
    String endTimeStr,
  ) {
    final endTime = _parseTimeString(endTimeStr);
    final startTime = _parseTimeString(startTimeStr);

    // Create DateTime for end time today
    var unlockDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endTime.hour,
      endTime.minute,
    );

    // If end time is "earlier" than start time, it spans midnight
    final spansMiddlenight =
        startTime.hour > endTime.hour ||
        (startTime.hour == endTime.hour && startTime.minute > endTime.minute);

    if (spansMiddlenight) {
      // If current time is before end time, unlock is today
      // If current time is after end time, unlock is tomorrow
      if (now.hour > endTime.hour ||
          (now.hour == endTime.hour && now.minute >= endTime.minute)) {
        // We're in the evening part, unlock is tomorrow
        unlockDateTime = unlockDateTime.add(const Duration(days: 1));
      }
    } else {
      // Normal same-day restriction
      // If we've already passed unlock time, it's tomorrow
      if (now.isAfter(unlockDateTime)) {
        unlockDateTime = unlockDateTime.add(const Duration(days: 1));
      }
    }

    return unlockDateTime;
  }

  static TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static bool _isTimeBetween(
    TimeOfDay current,
    TimeOfDay start,
    TimeOfDay end,
  ) {
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

  static String getNextUnlockTimeString(String startTime, String endTime) {
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
