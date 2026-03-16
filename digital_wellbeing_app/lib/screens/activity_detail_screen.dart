import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_idea.dart';
import '../models/activity_log.dart';
import '../providers/activity_log_provider.dart';
import 'activity_history_screen.dart';

const _categoryColors = <String, Color>{
  'Mindfulness': Color(0xFF7B61FF),
  'Fitness': Color(0xFF00C853),
  'Health': Color(0xFF00B0FF),
  'Learning': Color(0xFFFF6D00),
  'Productivity': Color(0xFF455A64),
  'Social': Color(0xFFE91E63),
  'Creativity': Color(0xFFFF8F00),
};

// ── Session phase ─────────────────────────────────────────────────────────────
enum _Phase { idle, running, completed }

// ── Screen ────────────────────────────────────────────────────────────────────
class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final ActivityIdea activity;

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  _Phase _phase = _Phase.idle;
  int _totalSeconds = 0;
  int _secondsLeft = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Color get _accent =>
      _categoryColors[widget.activity.category] ?? const Color(0xFF6B4FA0);

  // ── Timer helpers ─────────────────────────────────────────────────────────
  void _startCountdown(int seconds) {
    setState(() {
      _totalSeconds = seconds;
      _secondsLeft = seconds;
      _phase = _Phase.running;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    setState(() {
      if (_secondsLeft > 0) {
        _secondsLeft--;
      } else {
        t.cancel();
        _finishTimer();
      }
    });
  }

  void _finishTimer() {
    _persist(durationSeconds: _totalSeconds);
    setState(() => _phase = _Phase.completed);
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _totalSeconds = 0;
      _secondsLeft = 0;
    });
  }

  void _markDone() {
    _persist(durationSeconds: 0);
    setState(() => _phase = _Phase.completed);
  }

  void _persist({required int durationSeconds}) {
    final log = ActivityLog(
      activityTitle: widget.activity.title,
      activityEmoji: widget.activity.emoji,
      activityCategory: widget.activity.category,
      completedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      wasTimerBased: widget.activity.isTimerBased,
    );
    ref.read(activityLogProvider.notifier).addLog(log);
  }

  // ── Duration picker ───────────────────────────────────────────────────────
  Future<void> _pickDurationAndStart() async {
    int minutes = widget.activity.durationMinutes.clamp(1, 99);
    int seconds = 0;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DurationPickerDialog(
        initialMinutes: minutes,
        accentColor: _accent,
        onConfirm: (m, s) {
          minutes = m;
          seconds = s;
        },
      ),
    );

    if (confirmed == true && mounted) {
      final total = minutes * 60 + seconds;
      if (total > 0) _startCountdown(total);
    }
  }

  static String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _DetailContent(activity: widget.activity, accentColor: _accent),

          if (_phase != _Phase.running)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ActionBar(
                phase: _phase,
                isTimerBased: widget.activity.isTimerBased,
                accentColor: _accent,
                onStart: _pickDurationAndStart,
                onDone: _markDone,
                onViewHistory: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ActivityHistoryScreen()),
                ),
                onBack: () => Navigator.pop(context),
              ),
            ),

          if (_phase == _Phase.running)
            _TimerOverlay(
              activity: widget.activity,
              accentColor: _accent,
              totalSeconds: _totalSeconds,
              secondsLeft: _secondsLeft,
              formatTime: _fmt,
              onStop: _stopTimer,
            ),
        ],
      ),
    );
  }
}

// ── Scrollable detail content ─────────────────────────────────────────────────
class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.activity, required this.accentColor});

  final ActivityIdea activity;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor,
                  Color.alphaBlend(Colors.black26, accentColor),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(activity.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      activity.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Chip(label: activity.category, color: Colors.white),
                      const SizedBox(width: 8),
                      _Chip(
                        label: '${activity.durationMinutes} min',
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),

                if (activity.steps.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'How to do it',
                    color: accentColor,
                  ),
                  const SizedBox(height: 12),
                  ...activity.steps.asMap().entries.map(
                        (e) => _StepTile(
                          number: e.key + 1,
                          text: e.value,
                          accentColor: accentColor,
                        ),
                      ),
                ],

                if (activity.benefits.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.star_rounded,
                    label: 'Benefits',
                    color: accentColor,
                  ),
                  const SizedBox(height: 12),
                  ...activity.benefits.map(
                    (b) => _BenefitTile(text: b, color: accentColor),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.phase,
    required this.isTimerBased,
    required this.accentColor,
    required this.onStart,
    required this.onDone,
    required this.onViewHistory,
    required this.onBack,
  });

  final _Phase phase;
  final bool isTimerBased;
  final Color accentColor;
  final VoidCallback onStart;
  final VoidCallback onDone;
  final VoidCallback onViewHistory;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (phase == _Phase.completed) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: accentColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Activity recorded!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onViewHistory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onBack,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
      child: isTimerBased
          ? ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Start Activity',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onStart,
            )
          : ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Done',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onDone,
            ),
    );
  }
}

// ── Full-screen countdown overlay ─────────────────────────────────────────────
class _TimerOverlay extends StatelessWidget {
  const _TimerOverlay({
    required this.activity,
    required this.accentColor,
    required this.totalSeconds,
    required this.secondsLeft,
    required this.formatTime,
    required this.onStop,
  });

  final ActivityIdea activity;
  final Color accentColor;
  final int totalSeconds;
  final int secondsLeft;
  final String Function(int) formatTime;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds == 0
        ? 0.0
        : (totalSeconds - secondsLeft) / totalSeconds;

    return Container(
      color: Colors.black.withAlpha(220),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(activity.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(
              activity.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 44),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTime(secondsLeft),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Text(
                        'remaining',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                32,
                0,
                32,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                label: const Text(
                  'Stop',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onStop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Duration picker dialog ────────────────────────────────────────────────────
class _DurationPickerDialog extends StatefulWidget {
  const _DurationPickerDialog({
    required this.initialMinutes,
    required this.accentColor,
    required this.onConfirm,
  });

  final int initialMinutes;
  final Color accentColor;
  final void Function(int minutes, int seconds) onConfirm;

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int _minutes;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes.clamp(1, 99);
  }

  bool get _valid => _minutes > 0 || _seconds > 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How long do you want to spend on this?',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SpinnerField(
                value: _minutes,
                label: 'min',
                min: 0,
                max: 99,
                accentColor: widget.accentColor,
                onChanged: (v) => setState(() => _minutes = v),
              ),
              const SizedBox(width: 24),
              _SpinnerField(
                value: _seconds,
                label: 'sec',
                min: 0,
                max: 59,
                accentColor: widget.accentColor,
                onChanged: (v) => setState(() => _seconds = v),
              ),
            ],
          ),
          if (!_valid)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Duration must be greater than zero.',
                style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor,
            foregroundColor: Colors.white,
          ),
          onPressed: _valid
              ? () {
                  widget.onConfirm(_minutes, _seconds);
                  Navigator.pop(context, true);
                }
              : null,
          child: const Text('Start'),
        ),
      ],
    );
  }
}

// ── Spinner field (minutes / seconds picker) ──────────────────────────────────
class _SpinnerField extends StatelessWidget {
  const _SpinnerField({
    required this.value,
    required this.label,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.onChanged,
  });

  final int value;
  final String label;
  final int min;
  final int max;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.expand_less_rounded, color: accentColor),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withAlpha(80)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.expand_more_rounded, color: accentColor),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.text,
    required this.accentColor,
  });

  final int number;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
