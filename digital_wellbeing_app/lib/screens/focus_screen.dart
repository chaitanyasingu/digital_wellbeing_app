import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/focus_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/step_counter_provider.dart';
import '../services/mood_service.dart';

// ── Top-level helpers ──────────────────────────────────────────────────────

String _fmtSeconds(int s) {
  final m = s ~/ 60;
  final sec = s % 60;
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String _fmtMinutes(int m) {
  if (m == 0) return '0m';
  final h = m ~/ 60;
  final rem = m % 60;
  if (h == 0) return '${rem}m';
  if (rem == 0) return '${h}h';
  return '${h}h ${rem}m';
}

// ── FocusScreen ────────────────────────────────────────────────────────────

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _rounds = 4;
  bool _showSettings = false;
  bool _mindfulDelayEnabled = true;
  bool _eyeBreakEnabled = false;
  bool _settingsLoaded = false;

  static const _workPresets = [15, 25, 50, 90];
  static const _breakPresets = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mindfulDelayEnabled = prefs.getBool('mindful_delay_enabled') ?? true;
      _eyeBreakEnabled = prefs.getBool('eye_break_enabled') ?? false;
      _settingsLoaded = true;
    });
  }

  Future<void> _setMindfulDelay(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mindful_delay_enabled', enabled);
    setState(() => _mindfulDelayEnabled = enabled);
  }

  Future<void> _setEyeBreak(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eye_break_enabled', enabled);
    setState(() => _eyeBreakEnabled = enabled);
    // Schedule or cancel via usage_stats channel
    // (handled in SmartNotificationReceiver when type = eye_break_20_20_20)
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(focusTimerProvider);
    final moodState = ref.watch(moodProvider);
    final stepState = ref.watch(stepCounterProvider);

    if (!_settingsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Pomodoro Timer ────────────────────────────────────────────────
        _TimerCard(
          timerState: timerState,
          workMinutes: _workMinutes,
          breakMinutes: _breakMinutes,
          rounds: _rounds,
          showSettings: _showSettings,
          workPresets: _workPresets,
          breakPresets: _breakPresets,
          onToggleSettings: () => setState(() => _showSettings = !_showSettings),
          onWorkChanged: (v) => setState(() => _workMinutes = v),
          onBreakChanged: (v) => setState(() => _breakMinutes = v),
          onRoundsChanged: (v) => setState(() => _rounds = v),
          onStart: () => ref.read(focusTimerProvider.notifier).startSession(
            work: _workMinutes,
            breakMins: _breakMinutes,
            rounds: _rounds,
          ),
          onPause: () => ref.read(focusTimerProvider.notifier).pause(),
          onResume: () => ref.read(focusTimerProvider.notifier).resume(),
          onSkip: () => ref.read(focusTimerProvider.notifier).skipPhase(),
          onStop: () => ref.read(focusTimerProvider.notifier).stopSession(),
        ),
        const SizedBox(height: 16),

        // ── Today's Summary ───────────────────────────────────────────────
        _TodaySummaryCard(timerState: timerState, stepState: stepState),
        const SizedBox(height: 16),

        // ── Mood Check-in ─────────────────────────────────────────────────
        _MoodCard(moodState: moodState),
        const SizedBox(height: 16),

        // ── Mindfulness Settings ──────────────────────────────────────────
        _MindfulnessSettingsCard(
          mindfulDelayEnabled: _mindfulDelayEnabled,
          eyeBreakEnabled: _eyeBreakEnabled,
          onMindfulDelayChanged: _setMindfulDelay,
          onEyeBreakChanged: _setEyeBreak,
        ),
      ],
    );
  }
}

// ── Timer Card ─────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final FocusTimerState timerState;
  final int workMinutes;
  final int breakMinutes;
  final int rounds;
  final bool showSettings;
  final List<int> workPresets;
  final List<int> breakPresets;
  final VoidCallback onToggleSettings;
  final ValueChanged<int> onWorkChanged;
  final ValueChanged<int> onBreakChanged;
  final ValueChanged<int> onRoundsChanged;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkip;
  final VoidCallback onStop;

  const _TimerCard({
    required this.timerState,
    required this.workMinutes,
    required this.breakMinutes,
    required this.rounds,
    required this.showSettings,
    required this.workPresets,
    required this.breakPresets,
    required this.onToggleSettings,
    required this.onWorkChanged,
    required this.onBreakChanged,
    required this.onRoundsChanged,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onSkip,
    required this.onStop,
  });

  bool get _isActive =>
      timerState.phase == FocusPhase.working ||
      timerState.phase == FocusPhase.breaking ||
      timerState.phase == FocusPhase.paused;

  Color get _phaseColor {
    switch (timerState.phase) {
      case FocusPhase.working:
      case FocusPhase.paused:
        return Colors.purple;
      case FocusPhase.breaking:
        return Colors.green;
      case FocusPhase.idle:
        return Colors.grey.shade400;
    }
  }

  String get _phaseLabel {
    switch (timerState.phase) {
      case FocusPhase.working:
        return 'Focus Time';
      case FocusPhase.breaking:
        return 'Break';
      case FocusPhase.paused:
        return timerState.isPausedDuringWork ? 'Paused (Focus)' : 'Paused (Break)';
      case FocusPhase.idle:
        return 'Ready';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Phase label + settings toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _phaseLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _phaseColor,
                  ),
                ),
                if (!_isActive)
                  IconButton(
                    icon: Icon(
                      showSettings ? Icons.tune : Icons.tune_outlined,
                      size: 20,
                    ),
                    onPressed: onToggleSettings,
                    tooltip: 'Timer settings',
                  ),
              ],
            ),

            // Settings panel
            if (showSettings && !_isActive) ...[
              const SizedBox(height: 8),
              _SettingsPanel(
                workMinutes: workMinutes,
                breakMinutes: breakMinutes,
                rounds: rounds,
                workPresets: workPresets,
                breakPresets: breakPresets,
                onWorkChanged: onWorkChanged,
                onBreakChanged: onBreakChanged,
                onRoundsChanged: onRoundsChanged,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

            // Circular timer
            _CircularTimer(
              progress: timerState.progress,
              color: _phaseColor,
              remainingSeconds: timerState.phase == FocusPhase.idle
                  ? workMinutes * 60
                  : timerState.remainingSeconds,
              subtitle: _phaseLabel,
            ),
            const SizedBox(height: 16),

            // Round dots
            if (_isActive || timerState.phase == FocusPhase.idle)
              _RoundDots(
                totalRounds: _isActive ? timerState.totalRounds : rounds,
                currentRound: _isActive ? timerState.currentRound : 1,
                isInWorkPhase: timerState.phase == FocusPhase.working ||
                    (timerState.phase == FocusPhase.paused &&
                        timerState.isPausedDuringWork),
              ),
            const SizedBox(height: 20),

            // Controls
            _Controls(
              phase: timerState.phase,
              onStart: onStart,
              onPause: onPause,
              onResume: onResume,
              onSkip: onSkip,
              onStop: onStop,
              phaseColor: _phaseColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  final double progress;
  final Color color;
  final int remainingSeconds;
  final String subtitle;

  const _CircularTimer({
    required this.progress,
    required this.color,
    required this.remainingSeconds,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmtSeconds(remainingSeconds),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundDots extends StatelessWidget {
  final int totalRounds;
  final int currentRound;
  final bool isInWorkPhase;

  const _RoundDots({
    required this.totalRounds,
    required this.currentRound,
    required this.isInWorkPhase,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalRounds, (i) {
        final roundNum = i + 1;
        if (roundNum < currentRound) {
          // Completed
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.check_circle, color: Colors.purple, size: 20),
          );
        } else if (roundNum == currentRound) {
          // Current
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.circle, color: Colors.purple, size: 20),
          );
        } else {
          // Future
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.circle_outlined,
                color: Colors.grey.shade400, size: 20),
          );
        }
      }),
    );
  }
}

class _Controls extends StatelessWidget {
  final FocusPhase phase;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkip;
  final VoidCallback onStop;
  final Color phaseColor;

  const _Controls({
    required this.phase,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onSkip,
    required this.onStop,
    required this.phaseColor,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == FocusPhase.idle) {
      return ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Focus'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(160, 48),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause / Resume
        if (phase == FocusPhase.working || phase == FocusPhase.breaking)
          IconButton.filled(
            onPressed: onPause,
            icon: const Icon(Icons.pause),
            style: IconButton.styleFrom(
              backgroundColor: phaseColor,
              foregroundColor: Colors.white,
            ),
          )
        else
          IconButton.filled(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            style: IconButton.styleFrom(
              backgroundColor: phaseColor,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(width: 12),
        // Skip phase
        IconButton.outlined(
          onPressed: onSkip,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Skip phase',
        ),
        const SizedBox(width: 12),
        // Stop session
        IconButton.outlined(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          tooltip: 'End session',
          style: IconButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final int workMinutes;
  final int breakMinutes;
  final int rounds;
  final List<int> workPresets;
  final List<int> breakPresets;
  final ValueChanged<int> onWorkChanged;
  final ValueChanged<int> onBreakChanged;
  final ValueChanged<int> onRoundsChanged;

  const _SettingsPanel({
    required this.workMinutes,
    required this.breakMinutes,
    required this.rounds,
    required this.workPresets,
    required this.breakPresets,
    required this.onWorkChanged,
    required this.onBreakChanged,
    required this.onRoundsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Work',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: workPresets.map((p) => ChoiceChip(
              label: Text('${p}m'),
              selected: workMinutes == p,
              onSelected: (_) => onWorkChanged(p),
              selectedColor: Colors.purple.shade100,
            )).toList(),
          ),
          const SizedBox(height: 10),
          const Text('Break',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: breakPresets.map((p) => ChoiceChip(
              label: Text('${p}m'),
              selected: breakMinutes == p,
              onSelected: (_) => onBreakChanged(p),
              selectedColor: Colors.green.shade100,
            )).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Rounds: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ...List.generate(
                8,
                (i) => GestureDetector(
                  onTap: () => onRoundsChanged(i + 1),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rounds == i + 1
                          ? Colors.purple
                          : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: rounds == i + 1
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Today's Summary Card ───────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  final FocusTimerState timerState;
  final StepCounterState stepState;

  const _TodaySummaryCard({
    required this.timerState,
    required this.stepState,
  });

  @override
  Widget build(BuildContext context) {
    final focusMin = timerState.todayFocusMinutes;
    final sessions = timerState.todaySessions.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Focus",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.timer_outlined,
                  value: _fmtMinutes(focusMin),
                  label: 'Focus time',
                  color: Colors.purple,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.repeat,
                  value: '$sessions',
                  label: sessions == 1 ? 'session' : 'sessions',
                  color: Colors.indigo,
                ),
                if (stepState.stepsToday > 0) ...[
                  const SizedBox(width: 12),
                  _SummaryChip(
                    icon: Icons.directions_walk,
                    value: '${stepState.stepsToday}',
                    label: 'steps',
                    color: Colors.teal,
                  ),
                ],
              ],
            ),
            if (!stepState.isAvailable && !stepState.hasPermission)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Enable Activity Recognition to track steps',
                  style: TextStyle(
                      fontSize: 11, color: Colors.orange.shade700),
                ),
              ),
            if (stepState.isAvailable && !stepState.hasPermission) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.directions_walk, size: 16),
                label: const Text('Enable step tracking',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── Mood Card ──────────────────────────────────────────────────────────────

class _MoodCard extends ConsumerStatefulWidget {
  final MoodState moodState;

  const _MoodCard({required this.moodState});

  @override
  ConsumerState<_MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends ConsumerState<_MoodCard> {
  int? _selectedScore;
  final _noteController = TextEditingController();
  bool _showNoteInput = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedScore == null) return;
    await ref.read(moodProvider.notifier).saveMood(
          _selectedScore!,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    setState(() {
      _selectedScore = null;
      _showNoteInput = false;
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodState = widget.moodState;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Check-in',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (moodState.isLoading)
              const LinearProgressIndicator()
            else if (moodState.todayMood != null) ...[
              // Today already logged
              _LoggedMood(entry: moodState.todayMood!),
              const SizedBox(height: 10),
              // 7-day history
              if (moodState.recentMoods.isNotEmpty)
                _MoodHistory(moods: moodState.recentMoods),
            ] else ...[
              // Prompt to log
              Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final score = i + 1;
                  final emoji = MoodEntry.emojiFor(score);
                  final selected = _selectedScore == score;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedScore = score;
                        _showNoteInput = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.purple.shade100
                            : Colors.grey.shade100,
                        border: selected
                            ? Border.all(color: Colors.purple, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: TextStyle(
                                fontSize: selected ? 28 : 24)),
                      ),
                    ),
                  );
                }),
              ),
              if (_selectedScore != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    MoodEntry.labelFor(_selectedScore!),
                    style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              if (_showNoteInput) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedScore = null;
                          _showNoteInput = false;
                          _noteController.clear();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LoggedMood extends StatelessWidget {
  final MoodEntry entry;

  const _LoggedMood({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(MoodEntry.emojiFor(entry.moodScore),
            style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MoodEntry.labelFor(entry.moodScore),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (entry.note != null && entry.note!.isNotEmpty)
              Text(
                entry.note!,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        const Spacer(),
        Chip(
          label: const Text('Today', style: TextStyle(fontSize: 11)),
          backgroundColor: Colors.purple.shade50,
        ),
      ],
    );
  }
}

class _MoodHistory extends StatelessWidget {
  final List<MoodEntry> moods;

  const _MoodHistory({required this.moods});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Last ${moods.length} days',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: moods.map((m) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Text(MoodEntry.emojiFor(m.moodScore),
                      style: const TextStyle(fontSize: 20)),
                  Text(
                    _shortDate(m.date),
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _shortDate(String ymd) {
    final parts = ymd.split('-');
    if (parts.length < 3) return ymd;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month]} $day';
  }
}

// ── Mindfulness Settings Card ──────────────────────────────────────────────

class _MindfulnessSettingsCard extends StatelessWidget {
  final bool mindfulDelayEnabled;
  final bool eyeBreakEnabled;
  final ValueChanged<bool> onMindfulDelayChanged;
  final ValueChanged<bool> onEyeBreakChanged;

  const _MindfulnessSettingsCard({
    required this.mindfulDelayEnabled,
    required this.eyeBreakEnabled,
    required this.onMindfulDelayChanged,
    required this.onEyeBreakChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mindfulness Settings',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Micro-interventions to build healthier habits.',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mindful Delay',
                  style: TextStyle(fontSize: 14)),
              subtitle: Text(
                '5-second breathing pause before a blocked app opens.',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              secondary: const Icon(Icons.self_improvement),
              value: mindfulDelayEnabled,
              onChanged: onMindfulDelayChanged,
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('20-20-20 Eye Breaks',
                  style: TextStyle(fontSize: 14)),
              subtitle: Text(
                'Reminder every 20 minutes to look 20 feet away for 20 seconds.',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              secondary: const Icon(Icons.remove_red_eye_outlined),
              value: eyeBreakEnabled,
              onChanged: onEyeBreakChanged,
            ),
          ],
        ),
      ),
    );
  }
}
