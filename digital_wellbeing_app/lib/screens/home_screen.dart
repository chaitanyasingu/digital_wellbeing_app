import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rules_provider.dart';
import '../providers/enforcement_provider.dart';
import '../services/time_service.dart';
import 'app_selection_screen.dart';
import 'time_config_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Direct state access - no async, no waiting
    final rules = ref.watch(rulesProvider);
    final accessibilityState = ref.watch(accessibilityStatusProvider);

    final isLocked = ref.read(rulesProvider.notifier).isSettingsLocked();
    final nextUnlock = TimeService.getNextUnlockTime(
      rules.restrictionStartTime,
      rules.restrictionEndTime,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Wellbeing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
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
                        const Text('Enabled'),
                        Switch(
                          value: rules.isEnforcementEnabled,
                          onChanged: isLocked
                              ? null
                              : (value) async {
                                  // Check accessibility status when toggling
                                  ref
                                      .read(
                                        accessibilityStatusProvider.notifier,
                                      )
                                      .checkStatus();

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
                                },
                        ),
                      ],
                    ),
                    if (isLocked) ...[
                      const Divider(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Locked until $nextUnlock',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Accessibility Service Status
            if (!accessibilityState.isEnabled && rules.isEnforcementEnabled)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Accessibility Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enable to enforce blocking',
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
            if (!accessibilityState.isEnabled && rules.isEnforcementEnabled)
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
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.apps),
                      title: const Text(
                        'Allowed Apps',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${rules.alwaysAllowedApps.length} apps',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isLocked
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AppSelectionScreen(),
                                ),
                              );
                            },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text(
                        'Times',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${rules.restrictionStartTime} - ${rules.restrictionEndTime}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isLocked
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TimeConfigScreen(),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
