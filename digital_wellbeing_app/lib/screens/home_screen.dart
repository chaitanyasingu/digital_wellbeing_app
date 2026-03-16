import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_idea.dart';
import '../providers/activities_provider.dart';
import '../providers/password_provider.dart';
import 'activity_detail_screen.dart';
import 'activity_history_screen.dart';
import '../providers/rules_provider.dart';
import '../providers/enforcement_provider.dart';
import '../providers/settings_lock_provider.dart';
import '../providers/tamper_detection_provider.dart';
import '../services/time_service.dart' as time_utils;
import '../widgets/password_dialog.dart';
import 'app_selection_screen.dart';
import 'profile_screen.dart';
import 'time_config_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check accessibility status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accessibilityStatusProvider.notifier).checkStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload rules when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rulesProvider.notifier).reloadRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Direct state access - no async, no waiting
    final rules = ref.watch(rulesProvider);
    final accessibilityState = ref.watch(accessibilityStatusProvider);
    final lockState = ref.watch(settingsLockProvider);
    final canModify = ref.watch(canModifySettingsProvider);
    final tamperState = ref.watch(tamperDetectionProvider);

    print(
      '[HomeScreen] Building with ${rules.alwaysAllowedApps.length} allowed apps',
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.self_improvement, size: 24),
            const SizedBox(width: 8),
            const Text('Digital Mindfulness'),
          ],
        ),
        actions: [
          if (lockState.isLocked)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'LOCKED',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile & Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card - ONLY the toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enforcement Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rules.isEnforcementEnabled
                                    ? 'Apps will be blocked during restriction hours'
                                    : 'Apps will not be blocked',
                                style: const TextStyle(fontSize: 13),
                              ),
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
                                    // Turning OFF requires password verification
                                    if (!value) {
                                      final passwordService =
                                          ref.read(passwordServiceProvider);
                                      if (!context.mounted) return;
                                      final authorized =
                                          await PasswordDialog.showVerify(
                                              context, passwordService);
                                      if (!authorized || !context.mounted) return;
                                    }

                                    // If trying to enable, check accessibility permission first
                                    if (value) {
                                      // Check accessibility status
                                      await ref
                                          .read(
                                            accessibilityStatusProvider.notifier,
                                          )
                                          .checkStatus();

                                      // Get the updated accessibility state
                                      final isAccessibilityEnabled = ref
                                          .read(accessibilityStatusProvider)
                                          .isEnabled;

                                      if (!isAccessibilityEnabled) {
                                        // Show dialog and redirect to settings
                                        if (context.mounted) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Accessibility Permission Required',
                                              ),
                                              content: const Text(
                                                'Enable Accessibility Service in Settings to start enforcement.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    ref
                                                        .read(
                                                          enforcementServiceProvider,
                                                        )
                                                        .openAccessibilitySettings();
                                                  },
                                                  child: const Text(
                                                    'Go to Settings',
                                                  ),
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
                                      final service = ref.read(
                                        enforcementServiceProvider,
                                      );
                                      await service.startEnforcement(
                                        rules.alwaysAllowedApps,
                                        rules.restrictionStartTime,
                                        rules.restrictionEndTime,
                                      );
                                    } else {
                                      final service = ref.read(
                                        enforcementServiceProvider,
                                      );
                                      await service.stopEnforcement();
                                    }
                                  } catch (e) {
                                    // Show error but don't crash
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
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
            const SizedBox(height: 16),

            // ONLY ONE Notification: Accessibility Service Status (when not enabled)
            if (!accessibilityState.isEnabled && rules.isEnforcementEnabled)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Accessibility Service Needed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enable to enforce app blocking',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(enforcementServiceProvider)
                              .openAccessibilitySettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Configuration Card
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
                      leading: Icon(
                        Icons.apps,
                        color: canModify ? null : Colors.grey,
                      ),
                      title: Text(
                        'Allowed Apps',
                        style: TextStyle(
                          fontSize: 14,
                          color: canModify ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        '${rules.alwaysAllowedApps.length} apps',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: canModify ? null : Colors.grey,
                      ),
                      onTap: canModify
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AppSelectionScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.schedule,
                        color: canModify ? null : Colors.grey,
                      ),
                      title: Text(
                        'Restriction Times',
                        style: TextStyle(
                          fontSize: 14,
                          color: canModify ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        '${rules.restrictionStartTime} - ${rules.restrictionEndTime}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: canModify ? null : Colors.grey,
                      ),
                      onTap: canModify
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TimeConfigScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Activities Section
            const _ActivitiesSection(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Activities Section ────────────────────────────────────────────────────────

class _ActivitiesSection extends ConsumerWidget {
  const _ActivitiesSection();

  static const _categoryColors = <String, Color>{
    'Mindfulness': Color(0xFF7B61FF),
    'Fitness': Color(0xFF00C853),
    'Health': Color(0xFF00B0FF),
    'Learning': Color(0xFFFF6D00),
    'Productivity': Color(0xFF455A64),
    'Social': Color(0xFFE91E63),
    'Creativity': Color(0xFFFF8F00),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Things to do during restriction',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shuffle, size: 20),
                tooltip: 'Shuffle activities',
                onPressed: () =>
                    ref.read(activitiesProvider.notifier).shuffle(),
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 20),
                tooltip: 'Activity history',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivityHistoryScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        activitiesAsync.when(
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, __) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load activities.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(activitiesProvider.notifier).shuffle(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          data: (activities) => SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final activity = activities[index];
                final color = _categoryColors[activity.category] ??
                    Theme.of(context).colorScheme.primary;
                return _ActivityCard(activity: activity, accentColor: color);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.accentColor,
  });

  final ActivityIdea activity;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(activity: activity),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(activity.emoji, style: const TextStyle(fontSize: 26)),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${activity.durationMinutes} min',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    activity.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
