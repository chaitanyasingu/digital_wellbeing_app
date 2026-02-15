import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rules_provider.dart';

class TimeConfigScreen extends ConsumerStatefulWidget {
  const TimeConfigScreen({super.key});

  @override
  ConsumerState<TimeConfigScreen> createState() => _TimeConfigScreenState();
}

class _TimeConfigScreenState extends ConsumerState<TimeConfigScreen> {
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  @override
  void initState() {
    super.initState();
    final rules = ref.read(rulesProvider);
    startTime = _parseTime(rules.restrictionStartTime);
    endTime = _parseTime(rules.restrictionEndTime);
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restriction Times'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(rulesProvider.notifier)
                    .updateRestrictionTimes(
                      _formatTime(startTime),
                      _formatTime(endTime),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Times updated successfully')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restriction Window',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Only allowed apps accessible during this time',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Start Time'),
              subtitle: Text(_formatTime(startTime)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: startTime,
                );
                if (picked != null) {
                  setState(() {
                    startTime = picked;
                  });
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: const Text('End Time'),
              subtitle: Text(_formatTime(endTime)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: endTime,
                );
                if (picked != null) {
                  setState(() {
                    endTime = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Note',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Times like 21:00-10:00 span midnight',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
