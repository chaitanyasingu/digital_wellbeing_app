import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rules_provider.dart';
import '../providers/settings_lock_provider.dart';
import '../providers/enforcement_provider.dart';

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
    final canModify = ref.watch(canModifySettingsProvider);
    final lockState = ref.watch(settingsLockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restriction Times'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: !canModify
                  ? null
                  : () async {
                      try {
                        final newStartTime = _formatTime(startTime);
                        final newEndTime = _formatTime(endTime);

                        // Update times in database
                        await ref
                            .read(rulesProvider.notifier)
                            .updateRestrictionTimes(newStartTime, newEndTime);

                        // Read updated rules after save
                        final updatedRules = ref.read(rulesProvider);

                        // If enforcement is currently enabled, restart it with new times
                        if (updatedRules.isEnforcementEnabled) {
                          final service = ref.read(enforcementServiceProvider);
                          await service.stopEnforcement();
                          await service.startEnforcement(
                            updatedRules.alwaysAllowedApps,
                            newStartTime,
                            newEndTime,
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Times updated successfully'),
                            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: canModify
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lock status banner
            if (lockState.isLocked)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${lockState.lockMessage}. Times cannot be changed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              leading: Icon(
                Icons.nightlight_round,
                color: canModify ? null : Colors.grey,
              ),
              title: Text(
                'Start Time',
                style: TextStyle(color: canModify ? null : Colors.grey),
              ),
              subtitle: Text(_formatTime(startTime)),
              trailing: Icon(
                Icons.chevron_right,
                color: canModify ? null : Colors.grey,
              ),
              onTap: !canModify
                  ? null
                  : () async {
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
              leading: Icon(
                Icons.wb_sunny,
                color: canModify ? null : Colors.grey,
              ),
              title: Text(
                'End Time',
                style: TextStyle(color: canModify ? null : Colors.grey),
              ),
              subtitle: Text(_formatTime(endTime)),
              trailing: Icon(
                Icons.chevron_right,
                color: canModify ? null : Colors.grey,
              ),
              onTap: !canModify
                  ? null
                  : () async {
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
