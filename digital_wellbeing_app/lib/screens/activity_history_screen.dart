import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/activity_log.dart';
import '../providers/activity_log_provider.dart';

const _categoryColors = <String, Color>{
  'Mindfulness': Color(0xFF7B61FF),
  'Fitness': Color(0xFF00C853),
  'Health': Color(0xFF00B0FF),
  'Learning': Color(0xFFFF6D00),
  'Productivity': Color(0xFF455A64),
  'Social': Color(0xFFE91E63),
  'Creativity': Color(0xFFFF8F00),
};

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: logsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text('Could not load history.',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆',
                        style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text(
                      'No activities recorded yet.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete an activity to see it here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group logs by date string (e.g. "15 Mar 2026")
          final grouped = _groupByDate(logs);
          final dateKeys = grouped.keys.toList();

          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
              final dateKey = dateKeys[index];
              final dayLogs = grouped[dateKey]!;
              return _DateGroup(
                  dateLabel: dateKey, logs: dayLogs);
            },
          );
        },
      ),
    );
  }

  static Map<String, List<ActivityLog>> _groupByDate(
      List<ActivityLog> logs) {
    final map = <String, List<ActivityLog>>{};
    for (final log in logs) {
      final key = DateFormat('d MMM yyyy').format(log.completedAt);
      (map[key] ??= []).add(log);
    }
    return map;
  }
}

// ── Date group ────────────────────────────────────────────────────────────────
class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.dateLabel, required this.logs});

  final String dateLabel;
  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    // Is this today or yesterday?
    final today = DateFormat('d MMM yyyy').format(DateTime.now());
    final yesterday = DateFormat('d MMM yyyy')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    String heading = dateLabel;
    if (dateLabel == today) heading = 'Today';
    if (dateLabel == yesterday) heading = 'Yesterday';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            heading,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.6,
            ),
          ),
        ),
        ...logs.map((log) => _LogTile(log: log)),
      ],
    );
  }
}

// ── Log tile ──────────────────────────────────────────────────────────────────
class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[log.activityCategory] ??
        Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(log.activityEmoji,
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.activityTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(
                          label: log.activityCategory,
                          color: color),
                      if (log.wasTimerBased &&
                          log.durationSeconds > 0) ...[
                        const SizedBox(width: 6),
                        _Tag(
                          label: log.formattedDuration,
                          color: color,
                          icon: Icons.timer_outlined,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Time
            Text(
              log.formattedTime,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small tag chip ────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
