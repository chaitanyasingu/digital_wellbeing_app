import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/goals_provider.dart';
import '../providers/usage_provider.dart';

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalState = ref.watch(dailyGoalProvider);
    final permState = ref.watch(usagePermissionProvider);
    final todayAsync = ref.watch(totalScreenTimeTodayProvider);

    if (goalState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Streak card ──────────────────────────────────────────────────
        _StreakCard(goalState: goalState, ref: ref),
        const SizedBox(height: 16),

        // ── Daily goal card ──────────────────────────────────────────────
        _DailyGoalCard(
          goalState: goalState,
          permState: permState,
          todayAsync: todayAsync,
          ref: ref,
        ),
        const SizedBox(height: 16),

        // ── How streaks work ────────────────────────────────────────────
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text('How streaks work',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay under your daily screen-time goal to keep your streak alive. '
                  'Each day you succeed adds 1 to your streak. '
                  'Missing a day resets it to 0 — but you have 2 streak freezes per month '
                  'to protect it when life gets in the way.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Streak Card ────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final DailyGoalState goalState;
  final WidgetRef ref;

  const _StreakCard({required this.goalState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final streak = goalState.streak;
    final current = streak?.current ?? 0;
    final longest = streak?.longest ?? 0;
    final freezesLeft = streak?.freezesRemaining ?? 2;
    final hasGoal = goalState.goal != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🔥',
                    style:
                        TextStyle(fontSize: hasGoal ? 48 : 36)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$current',
                      style: TextStyle(
                        fontSize: hasGoal ? 56 : 40,
                        fontWeight: FontWeight.bold,
                        color: current > 0
                            ? Colors.orange.shade700
                            : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      current == 1 ? 'day streak' : 'day streak',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            if (hasGoal) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                      label: 'Longest',
                      value: '$longest days',
                      icon: Icons.emoji_events_outlined,
                      color: Colors.amber),
                  _StatChip(
                      label: 'Freezes left',
                      value: '$freezesLeft / 2',
                      icon: Icons.ac_unit,
                      color: Colors.blue),
                ],
              ),
              if (freezesLeft > 0) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await ref
                        .read(dailyGoalProvider.notifier)
                        .useFreeze();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? '❄️ Streak freeze used! Streak protected.'
                            : 'No freezes remaining this month.'),
                      ));
                    }
                  },
                  icon: const Icon(Icons.ac_unit, size: 16),
                  label: Text('Use Streak Freeze ($freezesLeft left)'),
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Set a daily goal below to start your streak!',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── Daily Goal Card ────────────────────────────────────────────────────────

class _DailyGoalCard extends StatefulWidget {
  final DailyGoalState goalState;
  final UsagePermissionState permState;
  final AsyncValue<Duration> todayAsync;
  final WidgetRef ref;

  const _DailyGoalCard({
    required this.goalState,
    required this.permState,
    required this.todayAsync,
    required this.ref,
  });

  @override
  State<_DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<_DailyGoalCard> {
  bool _editing = false;
  double _sliderHours = 2.0;

  @override
  void initState() {
    super.initState();
    if (widget.goalState.goal != null) {
      _sliderHours =
          (widget.goalState.goal!.targetMs / 3600000.0).clamp(0.5, 6.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goalState.goal;
    final today = widget.todayAsync;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Daily Screen-Time Goal',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (goal != null)
                  IconButton(
                    icon: Icon(_editing ? Icons.check : Icons.edit,
                        size: 20),
                    onPressed: () async {
                      if (_editing) {
                        await widget.ref
                            .read(dailyGoalProvider.notifier)
                            .setDailyGoal(Duration(
                                milliseconds:
                                    (_sliderHours * 3600000).round()));
                      }
                      setState(() => _editing = !_editing);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (goal == null && !_editing) ...[
              Text('No goal set yet.',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Set Daily Goal'),
              ),
            ] else ...[
              if (_editing) ...[
                Text(
                  '${_sliderHours == _sliderHours.roundToDouble() ? _sliderHours.toInt().toString() : _sliderHours.toStringAsFixed(1)}h per day',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _sliderHours,
                  min: 0.5,
                  max: 6.0,
                  divisions: 11,
                  label:
                      '${_sliderHours == _sliderHours.roundToDouble() ? _sliderHours.toInt() : _sliderHours.toStringAsFixed(1)}h',
                  onChanged: (v) => setState(() => _sliderHours = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('30m', style: TextStyle(fontSize: 11)),
                    const Text('6h', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await widget.ref
                            .read(dailyGoalProvider.notifier)
                            .setDailyGoal(Duration(
                                milliseconds:
                                    (_sliderHours * 3600000).round()));
                        setState(() => _editing = false);
                      },
                      child: const Text('Save Goal'),
                    ),
                    const SizedBox(width: 12),
                    if (goal != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _editing = false),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ] else if (goal != null) ...[
                // Progress display
                today.when(
                  data: (used) {
                    final target =
                        Duration(milliseconds: goal.targetMs);
                    final ratio = (used.inMilliseconds /
                            goal.targetMs.toDouble())
                        .clamp(0.0, 1.0);
                    final over = used > target;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _fmt(used),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: over
                                      ? Colors.red.shade700
                                      : Colors.purple),
                            ),
                            Text(
                              ' / ${_fmt(target)}',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 12,
                            backgroundColor:
                                Colors.grey.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              over
                                  ? Colors.red.shade400
                                  : Colors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          over
                              ? '⚠️ ${_fmt(used - target)} over goal'
                              : '${_fmt(target - used)} remaining',
                          style: TextStyle(
                              fontSize: 12,
                              color: over
                                  ? Colors.red.shade700
                                  : Colors.green.shade700),
                        ),
                        if (!widget.permState.hasPermission) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Usage Access not granted — progress unavailable.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const LinearProgressIndicator(),
                  error: (_, __) => Text(
                      'Could not load today\'s usage',
                      style: TextStyle(
                          color: Colors.grey.shade500)),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove Goal'),
                        content: const Text(
                            'This will also reset your streak. Continue?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Remove')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.ref
                          .read(dailyGoalProvider.notifier)
                          .removeGoal();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove Goal'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
