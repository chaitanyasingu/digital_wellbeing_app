import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/goals_provider.dart';
import '../providers/usage_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/family_provider.dart';
import '../services/gamification_service.dart';
import '../services/family_service.dart';

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Progress'),
              Tab(text: 'Badges'),
              Tab(text: 'Family'),
            ],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Expanded(
            child: TabBarView(children: [
              _ProgressTab(),
              _BadgesTab(),
              _FamilyTab(),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Progress Tab ────────────────────────────────────────────────────────────

class _ProgressTab extends ConsumerWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalState = ref.watch(dailyGoalProvider);
    final permState = ref.watch(usagePermissionProvider);
    final todayAsync = ref.watch(totalScreenTimeTodayProvider);
    final gamState = ref.watch(gamificationProvider);

    if (goalState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _XPLevelCard(state: gamState),
        const SizedBox(height: 16),
        _StreakCard(goalState: goalState, ref: ref),
        const SizedBox(height: 16),
        _DailyGoalCard(
          goalState: goalState,
          permState: permState,
          todayAsync: todayAsync,
          ref: ref,
        ),
        const SizedBox(height: 16),
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

// ── XP / Level Card ─────────────────────────────────────────────────────────

class _XPLevelCard extends StatelessWidget {
  final GamificationState state;
  const _XPLevelCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final plant = GamificationService.plantEmoji(state.plantStage);
    final plantLabel = GamificationService.plantLabel(state.plantStage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Level badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${state.level}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level ${state.level}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('${state.totalXP} XP total',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.levelProgress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor:
                              Colors.purple.withOpacity(0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.purple),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.xpInLevel} / ${state.xpNeededForLevel} XP to next level',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(plant, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plantLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Your virtual plant',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badges Tab ───────────────────────────────────────────────────────────────

class _BadgesTab extends ConsumerWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamState = ref.watch(gamificationProvider);
    final all = GamificationService.allAchievements;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: all.length,
      itemBuilder: (_, i) {
        final a = all[i];
        final unlocked = gamState.unlockedIds.contains(a.id);
        return _BadgeTile(achievement: a, unlocked: unlocked);
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _BadgeTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? Colors.purple : Colors.grey.shade400;

    return Card(
      color: unlocked ? Colors.purple.shade50 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: unlocked ? Colors.purple.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Text(achievement.icon,
                    style: TextStyle(
                        fontSize: 36,
                        color: unlocked ? null : Colors.transparent)),
                if (!unlocked)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.lock, size: 18, color: Colors.grey),
                  ),
                if (unlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: unlocked
                    ? Colors.purple.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${achievement.xpReward} XP',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.purple : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Family Tab ───────────────────────────────────────────────────────────────

class _FamilyTab extends ConsumerStatefulWidget {
  const _FamilyTab();

  @override
  ConsumerState<_FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends ConsumerState<_FamilyTab> {
  @override
  Widget build(BuildContext context) {
    final famState = ref.watch(familyProvider);

    if (famState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sorted = famState.sortedByXP;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('Leaderboard',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showAddProfile(context),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No profiles yet.'),
          ))
        else
          ...sorted.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final profile = entry.value;
            final xp = famState.xpPerProfile[profile.id] ?? 0;
            final isActive = profile.isActive;

            return Card(
              color: isActive ? Colors.purple.shade50 : null,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: isActive
                    ? BorderSide(color: Colors.purple.shade300, width: 1.5)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child:
                          Text(profile.avatarEmoji, style: const TextStyle(fontSize: 22)),
                    ),
                    if (rank <= 3)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Text(
                          rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Text(profile.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isActive ? Colors.purple.shade700 : null,
                        )),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (profile.isChildMode) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.child_care,
                          size: 14, color: Colors.orange),
                    ],
                  ],
                ),
                subtitle: Text(
                  'Level ${GamificationService.levelFromXP(xp)} · $xp XP',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: profile.id != null
                    ? _ProfileMenu(
                        profile: profile,
                        isActive: isActive,
                        onSwitch: () => ref
                            .read(familyProvider.notifier)
                            .switchProfile(profile.id!),
                        onToggleKids: (v) => ref
                            .read(familyProvider.notifier)
                            .toggleChildMode(profile.id!, v),
                        onDelete: () => ref
                            .read(familyProvider.notifier)
                            .removeProfile(profile.id!),
                      )
                    : null,
              ),
            );
          }),
      ],
    );
  }

  void _showAddProfile(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = FamilyProfile.availableAvatars[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name', hintText: 'e.g. Alex'),
              ),
              const SizedBox(height: 16),
              const Text('Choose avatar:',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FamilyProfile.availableAvatars
                    .map((e) => GestureDetector(
                          onTap: () => setS(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedEmoji == e
                                    ? Colors.purple
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(e,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(familyProvider.notifier)
                    .addProfile(name, selectedEmoji);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final FamilyProfile profile;
  final bool isActive;
  final VoidCallback onSwitch;
  final ValueChanged<bool> onToggleKids;
  final VoidCallback onDelete;

  const _ProfileMenu({
    required this.profile,
    required this.isActive,
    required this.onSwitch,
    required this.onToggleKids,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'switch':
            onSwitch();
          case 'kids':
            onToggleKids(!profile.isChildMode);
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        if (!isActive)
          const PopupMenuItem(value: 'switch', child: Text('Switch to this')),
        PopupMenuItem(
          value: 'kids',
          child: Text(profile.isChildMode
              ? 'Disable child mode'
              : 'Enable child mode'),
        ),
        if (!isActive)
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
                    style: TextStyle(fontSize: hasGoal ? 48 : 36)),
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
                      'day streak',
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
                    final ok =
                        await ref.read(dailyGoalProvider.notifier).useFreeze();
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
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
                    icon: Icon(_editing ? Icons.check : Icons.edit, size: 20),
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
                  children: const [
                    Text('30m', style: TextStyle(fontSize: 11)),
                    Text('6h', style: TextStyle(fontSize: 11)),
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
                        onPressed: () => setState(() => _editing = false),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ] else if (goal != null) ...[
                today.when(
                  data: (used) {
                    final target = Duration(milliseconds: goal.targetMs);
                    final ratio = (used.inMilliseconds / goal.targetMs.toDouble())
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
                              over ? Colors.red.shade400 : Colors.purple,
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
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text('Could not load today\'s usage',
                      style: TextStyle(color: Colors.grey.shade500)),
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
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
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
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
