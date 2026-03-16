import 'package:intl/intl.dart';

/// Represents a single completed activity session.
class ActivityLog {
  final int? id;
  final String activityTitle;
  final String activityEmoji;
  final String activityCategory;
  final DateTime completedAt;

  /// Actual seconds the user spent (countdown duration or instant for done-type).
  final int durationSeconds;

  /// Whether this was completed via the countdown timer flow.
  final bool wasTimerBased;

  const ActivityLog({
    this.id,
    required this.activityTitle,
    required this.activityEmoji,
    required this.activityCategory,
    required this.completedAt,
    required this.durationSeconds,
    required this.wasTimerBased,
  });

  String get formattedDuration {
    if (durationSeconds <= 0) return '—';
    if (durationSeconds < 60) return '${durationSeconds}s';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  String get formattedDate => DateFormat('d MMM yyyy').format(completedAt);
  String get formattedTime => DateFormat('HH:mm').format(completedAt);

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      activityTitle: (map['activity_title'] as Object?)?.toString() ?? '',
      activityEmoji: (map['activity_emoji'] as Object?)?.toString() ?? '✨',
      activityCategory:
          (map['activity_category'] as Object?)?.toString() ?? '',
      completedAt: DateTime.fromMillisecondsSinceEpoch(
          map['completed_at'] as int),
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      wasTimerBased: ((map['was_timer_based'] as int?) ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activity_title': activityTitle,
      'activity_emoji': activityEmoji,
      'activity_category': activityCategory,
      'completed_at': completedAt.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'was_timer_based': wasTimerBased ? 1 : 0,
    };
  }
}
