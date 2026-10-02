import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hardmode_provider.dart';
import '../providers/device_admin_provider.dart';

class HardmodeScreen extends ConsumerWidget {
  const HardmodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hm = ref.watch(hardmodeProvider);
    final isAdmin = ref.watch(deviceAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hardmode & Contracts')),
      body: hm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DeviceAdminCard(isAdmin: isAdmin),
                const SizedBox(height: 16),
                _HardmodePinCard(enabled: hm.isEnabled),
                const SizedBox(height: 16),
                _CommitmentContractsCard(
                  contracts: hm.contracts,
                  activeContract: hm.activeContract,
                ),
              ],
            ),
    );
  }
}

// ── Device Admin card ──────────────────────────────────────────────────────

class _DeviceAdminCard extends ConsumerWidget {
  final bool isAdmin;
  const _DeviceAdminCard({required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(deviceAdminProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield,
                    color: isAdmin ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Device Admin (Uninstall Protection)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Active — the app cannot be uninstalled without first revoking admin rights.'
                  : 'Inactive — enable to prevent this app from being uninstalled.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            isAdmin
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Revoke Admin'),
                    onPressed: () async {
                      final confirm = await _confirm(
                          context,
                          'Revoke Device Admin?',
                          'The app can then be uninstalled.');
                      if (confirm) notifier.deactivate();
                    },
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.shield),
                    label: const Text('Activate Device Admin'),
                    onPressed: () => notifier.activate(),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Hardmode PIN card ──────────────────────────────────────────────────────

class _HardmodePinCard extends ConsumerWidget {
  final bool enabled;
  const _HardmodePinCard({required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock,
                    color: enabled ? Colors.red : Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Hardmode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: enabled
                        ? Colors.red.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    enabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.red : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              enabled
                  ? 'A PIN is required to disable enforcement. Keep it somewhere safe!'
                  : 'When enabled, a PIN is required to turn off app blocking.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            enabled
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Disable Hardmode'),
                    onPressed: () => _showDisableHardmodeDialog(context, ref),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.lock),
                    label: const Text('Enable Hardmode'),
                    onPressed: () => _showEnableHardmodeDialog(context, ref),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEnableHardmodeDialog(
      BuildContext context, WidgetRef ref) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final key = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Hardmode'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set a PIN. You will need it to disable enforcement.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pinCtrl,
                decoration: const InputDecoration(labelText: 'PIN (4+ digits)'),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 4) ? 'At least 4 digits' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmCtrl,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (v) =>
                    v != pinCtrl.text ? 'PINs do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              ref.read(hardmodeProvider.notifier).enableHardmode(pinCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisableHardmodeDialog(
      BuildContext context, WidgetRef ref) async {
    final pinCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Hardmode'),
        content: TextField(
          controller: pinCtrl,
          decoration: const InputDecoration(labelText: 'Enter PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await ref
                  .read(hardmodeProvider.notifier)
                  .verifyPin(pinCtrl.text);
              if (!ctx.mounted) return;
              if (ok) {
                await ref.read(hardmodeProvider.notifier).disableHardmode();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// ── Commitment contracts card ──────────────────────────────────────────────

class _CommitmentContractsCard extends ConsumerWidget {
  final List<dynamic> contracts;
  final dynamic activeContract;

  const _CommitmentContractsCard({
    required this.contracts,
    required this.activeContract,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in),
                const SizedBox(width: 8),
                const Text(
                  'Commitment Contracts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: () => _showAddContractDialog(context, ref),
                ),
              ],
            ),
            if (activeContract != null) ...[
              const SizedBox(height: 8),
              _ActiveContractBanner(contract: activeContract),
            ],
            const SizedBox(height: 8),
            if (contracts.isEmpty)
              Text(
                'No contracts yet. Add one to lock yourself in for a session.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            else
              ...contracts.map((c) => _ContractTile(contract: c)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddContractDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(const Duration(hours: 2));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Commitment Contract'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Session name',
                  hintText: 'e.g. Deep Work Sprint',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start', style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(startTime),
                            );
                            if (t != null) {
                              setState(() {
                                startTime = DateTime(
                                    startTime.year,
                                    startTime.month,
                                    startTime.day,
                                    t.hour,
                                    t.minute);
                              });
                            }
                          },
                          child: Text(_fmtTime(startTime)),
                        ),
                      ],
                    ),
                  ),
                  const Text('→'),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End', style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(endTime),
                            );
                            if (t != null) {
                              setState(() {
                                endTime = DateTime(endTime.year, endTime.month,
                                    endTime.day, t.hour, t.minute);
                              });
                            }
                          },
                          child: Text(_fmtTime(endTime)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Warning: once started, this contract cannot be cancelled until it expires.',
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                if (!endTime.isAfter(startTime)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('End time must be after start time')),
                  );
                  return;
                }
                ref.read(hardmodeProvider.notifier).addContract(
                      nameCtrl.text.trim(),
                      startTime,
                      endTime,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Commit'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ActiveContractBanner extends StatelessWidget {
  final dynamic contract;
  const _ActiveContractBanner({required this.contract});

  @override
  Widget build(BuildContext context) {
    final remaining = contract.remaining as Duration;
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contract.name} — ACTIVE',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text(
                  'Remaining: ${hours}h ${mins}m',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractTile extends ConsumerWidget {
  final dynamic contract;
  const _ContractTile({required this.contract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentlyActive = contract.isCurrentlyActive as bool;
    return ListTile(
      dense: true,
      leading: Icon(
        isCurrentlyActive ? Icons.lock_clock : Icons.assignment,
        color: isCurrentlyActive ? Colors.red : Colors.grey,
      ),
      title: Text(contract.name as String),
      subtitle: Text(
        '${_fmtDt(contract.startTime)} → ${_fmtDt(contract.endTime)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isCurrentlyActive
          ? const Chip(
              label: Text('Active', style: TextStyle(fontSize: 11)),
              backgroundColor: Color(0x22FF0000),
            )
          : null,
    );
  }

  String _fmtDt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Helper ─────────────────────────────────────────────────────────────────

Future<bool> _confirm(
    BuildContext context, String title, String body) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm')),
      ],
    ),
  );
  return result ?? false;
}
