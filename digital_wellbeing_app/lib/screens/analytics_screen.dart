import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';
import '../services/database_service.dart';
import '../services/usage_service.dart';

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String _fmtTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usagePermissionProvider.notifier).checkPermission();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permState = ref.watch(usagePermissionProvider);

    if (!permState.checked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!permState.hasPermission) {
      return _PermissionGate(
        onGrant: () async {
          await ref.read(usagePermissionProvider.notifier).openSettings();
        },
        onRefresh: () =>
            ref.read(usagePermissionProvider.notifier).checkPermission(),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Today'), Tab(text: 'This Week')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_TodayTab(), _WeekTab()],
          ),
        ),
      ],
    );
  }
}

// ── Permission Gate ────────────────────────────────────────────────────────

class _PermissionGate extends StatelessWidget {
  final VoidCallback onGrant;
  final VoidCallback onRefresh;

  const _PermissionGate({required this.onGrant, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 72, color: Colors.purple.shade300),
            const SizedBox(height: 24),
            Text(
              'Usage Access Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'To show your screen time, Digital Mindfulness needs '
              '"Usage Access" permission. This is a special Android '
              'permission that must be granted from Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onGrant,
              icon: const Icon(Icons.settings),
              label: const Text('Open Usage Access Settings'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRefresh,
              child: const Text('I\'ve granted it — refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today Tab ─────────────────────────────────────────────────────────────

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(todayUsageProvider);
    final pickupsAsync = ref.watch(pickupCountTodayProvider);
    final firstPickAsync = ref.watch(firstPickupTodayProvider);
    final lastPickAsync = ref.watch(lastPickupTodayProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayUsageProvider);
        ref.invalidate(pickupCountTodayProvider);
        ref.invalidate(firstPickupTodayProvider);
        ref.invalidate(lastPickupTodayProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary row
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.phone_android,
                  label: 'Screen Time',
                  value: usageAsync.when(
                    data: (stats) => _fmt(stats.fold(
                        Duration.zero, (s, e) => s + e.totalTime)),
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.touch_app,
                  label: 'Pickups',
                  value: pickupsAsync.when(
                    data: (c) => '$c',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // First / Last pickup
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.wb_sunny_outlined,
                  label: 'First Pickup',
                  value: firstPickAsync.when(
                    data: (dt) => dt != null ? _fmtTime(dt) : '—',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.nights_stay_outlined,
                  label: 'Last Pickup',
                  value: lastPickAsync.when(
                    data: (dt) => dt != null ? _fmtTime(dt) : '—',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Top apps
          Text('Top Apps Today',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          usageAsync.when(
            data: (stats) => _TopAppsList(stats: stats),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _TopAppsList extends ConsumerWidget {
  final List<AppUsageStat> stats;

  const _TopAppsList({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stats.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No usage data for today yet.',
            style: TextStyle(color: Colors.grey)),
      ));
    }

    final sorted = [...stats]
      ..sort((a, b) => b.totalTime.compareTo(a.totalTime));
    final top = sorted.take(10).toList();
    final maxMs = top.first.totalTime.inMilliseconds.toDouble();
    final packageNames = top.map((s) => s.packageName).toList();

    return FutureBuilder<Map<String, String>>(
      future: DatabaseService.instance.getAppNames(packageNames),
      builder: (context, snapshot) {
        final nameMap = snapshot.data ?? {};
        return Column(
          children: top.map((stat) {
            final ratio =
                maxMs > 0 ? stat.totalTime.inMilliseconds / maxMs : 0.0;
            final appName =
                nameMap[stat.packageName] ?? _shortPkg(stat.packageName);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(appName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _fmt(stat.totalTime),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _shortPkg(String pkg) {
    final parts = pkg.split('.');
    return parts.last.replaceAll('_', ' ');
  }
}

// ── Week Tab ───────────────────────────────────────────────────────────────

class _WeekTab extends ConsumerWidget {
  const _WeekTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekUsageProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(weekUsageProvider),
      child: weekAsync.when(
        data: (weekData) => _WeekContent(weekData: weekData),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _WeekContent extends StatelessWidget {
  final Map<DateTime, List<AppUsageStat>> weekData;

  const _WeekContent({required this.weekData});

  @override
  Widget build(BuildContext context) {
    final days = weekData.keys.toList()..sort();
    final totals = days.map((d) {
      final stats = weekData[d] ?? [];
      return stats.fold(Duration.zero, (s, e) => s + e.totalTime);
    }).toList();

    final maxHours =
        totals.map((d) => d.inMinutes / 60.0).fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = (maxHours + 0.5).ceilToDouble().clamp(1.0, double.infinity);

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final groups = days.asMap().entries.map((entry) {
      final i = entry.key;
      final hours = totals[i].inMinutes / 60.0;
      final isToday = entry.value == todayMidnight;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: isToday
                ? Colors.purple
                : Colors.purple.withOpacity(0.45),
            width: 22,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        _fmt(totals[group.x]),
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          final dayOfWeek =
                              days.isNotEmpty && idx < days.length
                                  ? days[idx].weekday - 1
                                  : idx % 7;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              dayLabels[dayOfWeek % 7],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    days.isNotEmpty && idx < days.length &&
                                            days[idx] == todayMidnight
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: days.isNotEmpty &&
                                        idx < days.length &&
                                        days[idx] == todayMidnight
                                    ? Colors.purple
                                    : Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: chartMax > 4 ? 2 : 1,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}h',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMax > 4 ? 2 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: groups,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Daily Breakdown',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...days.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          final total = totals[i];
          final isToday = day == todayMidnight;
          final ratio = chartMax > 0 ? (total.inMinutes / 60.0) / chartMax : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    '${dayLabels[day.weekday - 1]}\n${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.purple : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isToday
                            ? Colors.purple
                            : Colors.purple.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    _fmt(total),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
