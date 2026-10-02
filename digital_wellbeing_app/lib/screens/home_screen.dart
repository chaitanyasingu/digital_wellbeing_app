import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rules_provider.dart';
import '../providers/enforcement_provider.dart';
import '../providers/settings_lock_provider.dart';
import '../providers/tamper_detection_provider.dart';
import '../providers/usage_provider.dart';
import '../services/enforcement_service.dart';
import 'analytics_screen.dart';
import 'goals_screen.dart';
import 'sleep_screen.dart';
import 'app_selection_screen.dart';
import 'time_config_screen.dart';

String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accessibilityStatusProvider.notifier).checkStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rulesProvider.notifier).reloadRules();
    });
  }

  static const _tabs = [
    _HomeTab(),
    AnalyticsScreen(),
    GoalsScreen(),
    SleepScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tamperState = ref.watch(tamperDetectionProvider);

    return Scaffold(
      appBar: _buildAppBar(context, tamperState),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.bedtime_outlined),
            selectedIcon: Icon(Icons.bedtime),
            label: 'Sleep',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, TamperDetectionState tamperState) {
    final lockState = ref.watch(settingsLockProvider);
    final titles = ['Digital Mindfulness', 'Analytics', 'Goals', 'Sleep'];
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentIndex == 0) ...[
            const Icon(Icons.self_improvement, size: 24),
            const SizedBox(width: 8),
          ],
          Text(titles[_currentIndex]),
        ],
      ),
      actions: [
        if (lockState.isLocked && _currentIndex == 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.red.shade300, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'LOCKED',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

// ── Home Tab ───────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final accessibilityState = ref.watch(accessibilityStatusProvider);
    final canModify = ref.watch(canModifySettingsProvider);
    final tamperState = ref.watch(tamperDetectionProvider);
    final permState = ref.watch(usagePermissionProvider);
    final totalTimeAsync = ref.watch(totalScreenTimeTodayProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Today's screen time summary ──────────────────────────────
          if (permState.hasPermission)
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.phone_android,
                        color: Colors.purple.shade600, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Screen Time",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple.shade700)),
                          totalTimeAsync.when(
                            data: (d) => Text(
                              _fmtDuration(d),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                            ),
                            loading: () => const Text('…',
                                style: TextStyle(fontSize: 20)),
                            error: (_, __) => const Text('—',
                                style: TextStyle(fontSize: 20)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Details →'),
                    ),
                  ],
                ),
              ),
            ),
          if (permState.hasPermission) const SizedBox(height: 12),

          // ── Enforcement status ───────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enforcement Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Enabled'),
                            if (!canModify)
                              Text(
                                'Cannot change during restriction',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: rules.isEnforcementEnabled,
                        onChanged: canModify
                            ? (value) async {
                                try {
                                  if (value) {
                                    await ref
                                        .read(
                                          accessibilityStatusProvider.notifier,
                                        )
                                        .checkStatus();
                                    final isEnabled = ref
                                        .read(accessibilityStatusProvider)
                                        .isEnabled;
                                    if (!isEnabled) {
                                      if (context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                                'Accessibility Permission Required'),
                                            content: const Text(
                                                'Enable Accessibility Service in Settings to start enforcement.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  ref
                                                      .read(
                                                        enforcementServiceProvider,
                                                      )
                                                      .openAccessibilitySettings();
                                                },
                                                child: const Text(
                                                    'Go to Settings'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }
                                  await ref
                                      .read(rulesProvider.notifier)
                                      .toggleEnforcement(value);
                                  if (value) {
                                    await ref
                                        .read(enforcementServiceProvider)
                                        .startEnforcement(
                                          rules.alwaysAllowedApps,
                                          rules.restrictionStartTime,
                                          rules.restrictionEndTime,
                                        );
                                  } else {
                                    await ref
                                        .read(enforcementServiceProvider)
                                        .stopEnforcement();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tamper warning: accessibility disabled ───────────────────
          if (tamperState.showWarning && tamperState.isAccessibilityDisabled)
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Service Disabled',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enforcement cannot run until the accessibility service is re-enabled.',
                      style:
                          TextStyle(fontSize: 13, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => ref
                              .read(tamperDetectionProvider.notifier)
                              .dismissWarning(),
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              EnforcementService().openAccessibilitySettings(),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Re-enable'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Tamper warning: force-close pattern ─────────────────────
          if (tamperState.showWarning &&
              tamperState.hasRecentForceCloses &&
              !tamperState.isAccessibilityDisabled)
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.orange.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Bypass Attempt Detected',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Detected ${tamperState.forceCloseCount} force-close attempt${tamperState.forceCloseCount == 1 ? '' : 's'} in the last 5 minutes. Enforcement continues regardless.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => ref
                            .read(tamperDetectionProvider.notifier)
                            .dismissWarning(),
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Accessibility info (no tamper event, just not enabled) ───
          if (!accessibilityState.isEnabled &&
              rules.isEnforcementEnabled &&
              !tamperState.isAccessibilityDisabled)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Accessibility Service Needed',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable to enforce app blocking',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(enforcementServiceProvider)
                          .openAccessibilitySettings(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── Configuration ────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (!canModify)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '🔒 Settings locked during restriction window',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.apps,
                        color: canModify ? null : Colors.grey),
                    title: Text('Allowed Apps',
                        style: TextStyle(
                            fontSize: 14,
                            color: canModify ? null : Colors.grey)),
                    subtitle: Text('${rules.alwaysAllowedApps.length} apps',
                        style: const TextStyle(fontSize: 12)),
                    trailing: Icon(Icons.chevron_right,
                        color: canModify ? null : Colors.grey),
                    onTap: canModify
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AppSelectionScreen()),
                            )
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.schedule,
                        color: canModify ? null : Colors.grey),
                    title: Text('Restriction Times',
                        style: TextStyle(
                            fontSize: 14,
                            color: canModify ? null : Colors.grey)),
                    subtitle: Text(
                        '${rules.restrictionStartTime} - ${rules.restrictionEndTime}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: Icon(Icons.chevron_right,
                        color: canModify ? null : Colors.grey),
                    onTap: canModify
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const TimeConfigScreen()),
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
