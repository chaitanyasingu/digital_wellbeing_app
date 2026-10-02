import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/goals_provider.dart';
import '../providers/rules_provider.dart';
import '../services/goals_service.dart';
import '../services/usage_service.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  // Sleep schedule form state
  String _bedtime = '22:00';
  String _wakeTime = '07:00';
  int _graceMins = 0;
  bool _blueLightEnabled = false;
  String _blueLightTime = '21:00';
  bool _scheduleActive = false;
  bool _initialized = false;

  // Smart notification state
  bool _morningEnabled = false;
  int _morningHour = 8;
  int _morningMinute = 0;
  bool _eveningEnabled = false;
  int _eveningHour = 21;
  int _eveningMinute = 0;
  bool _summaryEnabled = false;
  int _summaryHour = 21;
  int _summaryMinute = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schedState = ref.read(sleepScheduleProvider);
      if (!schedState.isLoading && schedState.active != null) {
        final s = schedState.active!;
        setState(() {
          _bedtime = s.bedtime;
          _wakeTime = s.wakeTime;
          _graceMins = s.gracePeriodMins;
          _blueLightEnabled = s.blueLightReminderEnabled;
          _blueLightTime = s.blueLightReminderTime;
          _scheduleActive = s.isActive;
          _initialized = true;
        });
      } else {
        setState(() => _initialized = true);
      }
    });
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _todStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmt12(String t) {
    final tod = _parseTime(t);
    final h = tod.hour % 12 == 0 ? 12 : tod.hour % 12;
    final m = tod.minute.toString().padLeft(2, '0');
    final p = tod.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  Future<void> _pickTime(String current, ValueChanged<String> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(current),
    );
    if (picked != null) onPicked(_todStr(picked));
  }

  Future<void> _applyToEnforcement() async {
    try {
      await ref
          .read(rulesProvider.notifier)
          .updateRestrictionTimes(_bedtime, _wakeTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sleep window applied: $_bedtime – $_wakeTime'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not apply: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    final schedule = SleepSchedule(
      id: ref.read(sleepScheduleProvider).active?.id,
      name: 'Sleep',
      bedtime: _bedtime,
      wakeTime: _wakeTime,
      gracePeriodMins: _graceMins,
      blueLightReminderEnabled: _blueLightEnabled,
      blueLightReminderTime: _blueLightTime,
      isActive: _scheduleActive,
    );
    await ref.read(sleepScheduleProvider.notifier).save(schedule);
    if (_scheduleActive) await _applyToEnforcement();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep schedule saved.')),
      );
    }
  }

  Future<void> _toggleSmartNotif(
      String type, bool enabled, int hour, int minute) async {
    final svc = UsageService();
    if (enabled) {
      await svc.scheduleSmartNotification(
          type: type, hour: hour, minute: minute);
    } else {
      await svc.cancelSmartNotification(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Sleep Schedule ──────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sleep Schedule',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _scheduleActive,
                      onChanged: (v) => setState(() => _scheduleActive = v),
                    ),
                  ],
                ),
                Text(
                  'App restrictions will follow this schedule.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Bedtime + Wake time row
                Row(
                  children: [
                    Expanded(
                        child: _TimeTile(
                      icon: Icons.bedtime_outlined,
                      label: 'Bedtime',
                      time: _fmt12(_bedtime),
                      color: Colors.indigo,
                      onTap: () => _pickTime(
                          _bedtime, (t) => setState(() => _bedtime = t)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _TimeTile(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Wake Time',
                      time: _fmt12(_wakeTime),
                      color: Colors.orange,
                      onTap: () => _pickTime(
                          _wakeTime, (t) => setState(() => _wakeTime = t)),
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // Grace period
                Text(
                  'Grace period: ${_graceMins == 0 ? 'None' : '$_graceMins min'}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Slider(
                  value: _graceMins.toDouble(),
                  min: 0,
                  max: 30,
                  divisions: 6,
                  label:
                      _graceMins == 0 ? 'None' : '$_graceMins min',
                  onChanged: (v) =>
                      setState(() => _graceMins = v.round()),
                ),
                Text(
                  'Extra minutes after wake-up before enforcement starts.',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),

                // Blue light reminder
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Blue Light Reminder',
                      style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    'Notification before bedtime to reduce screen use.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _blueLightEnabled,
                  onChanged: (v) =>
                      setState(() => _blueLightEnabled = v),
                ),
                if (_blueLightEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _TimeTile(
                      icon: Icons.lightbulb_outline,
                      label: 'Reminder at',
                      time: _fmt12(_blueLightTime),
                      color: Colors.amber,
                      onTap: () => _pickTime(_blueLightTime,
                          (t) => setState(() => _blueLightTime = t)),
                    ),
                  ),
                const SizedBox(height: 16),

                // Save + Apply buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveSchedule,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Schedule'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _applyToEnforcement,
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Apply Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Smart Notifications ─────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminders',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Scheduled via AlarmManager — fires even when app is closed.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Morning
                _NotifRow(
                  icon: '🌅',
                  title: 'Morning Intention',
                  subtitle: 'Daily prompt to set your focus before opening apps.',
                  enabled: _morningEnabled,
                  hour: _morningHour,
                  minute: _morningMinute,
                  onToggle: (v) {
                    setState(() => _morningEnabled = v);
                    _toggleSmartNotif(UsageService.morningType, v,
                        _morningHour, _morningMinute);
                  },
                  onTimeTap: () => _pickTime(
                    '${_morningHour.toString().padLeft(2, '0')}:${_morningMinute.toString().padLeft(2, '0')}',
                    (t) {
                      final parts = t.split(':');
                      setState(() {
                        _morningHour = int.parse(parts[0]);
                        _morningMinute = int.parse(parts[1]);
                      });
                      if (_morningEnabled) {
                        _toggleSmartNotif(UsageService.morningType, true,
                            _morningHour, _morningMinute);
                      }
                    },
                  ),
                ),
                const Divider(),

                // Evening
                _NotifRow(
                  icon: '🌙',
                  title: 'Evening Wind-Down',
                  subtitle: 'Gentle reminder to start winding down for the night.',
                  enabled: _eveningEnabled,
                  hour: _eveningHour,
                  minute: _eveningMinute,
                  onToggle: (v) {
                    setState(() => _eveningEnabled = v);
                    _toggleSmartNotif(UsageService.eveningType, v,
                        _eveningHour, _eveningMinute);
                  },
                  onTimeTap: () => _pickTime(
                    '${_eveningHour.toString().padLeft(2, '0')}:${_eveningMinute.toString().padLeft(2, '0')}',
                    (t) {
                      final parts = t.split(':');
                      setState(() {
                        _eveningHour = int.parse(parts[0]);
                        _eveningMinute = int.parse(parts[1]);
                      });
                      if (_eveningEnabled) {
                        _toggleSmartNotif(UsageService.eveningType, true,
                            _eveningHour, _eveningMinute);
                      }
                    },
                  ),
                ),
                const Divider(),

                // Daily summary
                _NotifRow(
                  icon: '📊',
                  title: 'Daily Summary',
                  subtitle: 'See how your screen time looked today.',
                  enabled: _summaryEnabled,
                  hour: _summaryHour,
                  minute: _summaryMinute,
                  onToggle: (v) {
                    setState(() => _summaryEnabled = v);
                    _toggleSmartNotif(UsageService.summaryType, v,
                        _summaryHour, _summaryMinute);
                  },
                  onTimeTap: () => _pickTime(
                    '${_summaryHour.toString().padLeft(2, '0')}:${_summaryMinute.toString().padLeft(2, '0')}',
                    (t) {
                      final parts = t.split(':');
                      setState(() {
                        _summaryHour = int.parse(parts[0]);
                        _summaryMinute = int.parse(parts[1]);
                      });
                      if (_summaryEnabled) {
                        _toggleSmartNotif(UsageService.summaryType, true,
                            _summaryHour, _summaryMinute);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final VoidCallback onTap;

  const _TimeTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(label,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _NotifRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    required this.onTimeTap,
  });

  String get _timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final p = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (enabled)
            TextButton(
              onPressed: onTimeTap,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text(_timeLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}
