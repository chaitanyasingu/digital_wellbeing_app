import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/context_rules_provider.dart';
import '../services/context_rules_service.dart';
import '../services/wifi_service.dart';
import '../services/location_service.dart';

class ContextRulesScreen extends ConsumerWidget {
  const ContextRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Context Rules'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
              Tab(icon: Icon(Icons.location_on), text: 'Location'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Re-evaluate rules now',
              onPressed: () => ref.read(contextRulesProvider.notifier).refresh(),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _WifiRulesTab(),
            _LocationRulesTab(),
          ],
        ),
      ),
    );
  }
}

// ── WiFi rules tab ─────────────────────────────────────────────────────────

class _WifiRulesTab extends ConsumerWidget {
  const _WifiRulesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contextRulesProvider);

    return Column(
      children: [
        _ContextStatusCard(
          label: 'WiFi Relaxed',
          active: state.wifiRelaxedActive,
          detail: state.currentSsid != null
              ? 'Current SSID: ${state.currentSsid}'
              : 'No WiFi detected',
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.wifiRules.isEmpty
                  ? _EmptyHint(
                      icon: Icons.wifi,
                      message:
                          'No WiFi rules yet.\nAdd your home or office network to relax blocking while connected.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.wifiRules.length,
                      itemBuilder: (ctx, i) =>
                          _WifiRuleTile(rule: state.wifiRules[i]),
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add WiFi Rule'),
            onPressed: () => _showAddWifiDialog(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddWifiDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final ssidCtrl = TextEditingController();
    bool isRelaxed = true;

    // Pre-fill with current SSID if available
    final ssid = await WifiService().getCurrentSsid();
    if (ssid != null) ssidCtrl.text = ssid;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add WiFi Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rule name',
                  hintText: 'e.g. Home Network',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ssidCtrl,
                decoration: const InputDecoration(
                  labelText: 'WiFi SSID',
                  hintText: 'Exact network name',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                dense: true,
                title: const Text('Relax blocking on this network'),
                subtitle: Text(isRelaxed
                    ? 'Apps will NOT be blocked on this WiFi'
                    : 'Apps will be blocked on this WiFi'),
                value: isRelaxed,
                onChanged: (v) => setState(() => isRelaxed = v),
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
                if (nameCtrl.text.isEmpty || ssidCtrl.text.isEmpty) return;
                ref.read(contextRulesProvider.notifier).addWifiRule(
                      WifiRule(
                        name: nameCtrl.text.trim(),
                        ssid: ssidCtrl.text.trim(),
                        isRelaxed: isRelaxed,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WifiRuleTile extends ConsumerWidget {
  final WifiRule rule;
  const _WifiRuleTile({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contextRulesProvider.notifier);
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.wifi,
          color: rule.isActive
              ? (rule.isRelaxed ? Colors.green : Colors.orange)
              : Colors.grey,
        ),
        title: Text(rule.name),
        subtitle: Text(
          '${rule.ssid} · ${rule.isRelaxed ? 'Relax blocking' : 'Enforce blocking'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: rule.isActive,
              onChanged: (v) => notifier.toggleWifiRule(rule.id!, v),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => notifier.deleteWifiRule(rule.id!),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location rules tab ─────────────────────────────────────────────────────

class _LocationRulesTab extends ConsumerWidget {
  const _LocationRulesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contextRulesProvider);

    return Column(
      children: [
        _ContextStatusCard(
          label: 'Location Strict',
          active: state.locationStrictActive,
          detail: state.currentLocation != null
              ? 'GPS: ${state.currentLocation!.lat.toStringAsFixed(4)}, ${state.currentLocation!.lng.toStringAsFixed(4)}'
              : 'Location not available',
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.locationRules.isEmpty
                  ? _EmptyHint(
                      icon: Icons.location_off,
                      message:
                          'No location rules yet.\nAdd a place like "Work" to enforce stricter blocking when you arrive.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.locationRules.length,
                      itemBuilder: (ctx, i) =>
                          _LocationRuleTile(rule: state.locationRules[i]),
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.add_location),
            label: const Text('Add Location Rule'),
            onPressed: () => _showAddLocationDialog(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddLocationDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '200');
    bool isStrict = true;

    // Pre-fill with current location if available
    final loc = await LocationService().getLastKnownLocation();
    if (loc != null) {
      latCtrl.text = loc.lat.toStringAsFixed(6);
      lngCtrl.text = loc.lng.toStringAsFixed(6);
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Location Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Place name',
                    hintText: 'e.g. Work Office',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: radiusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Radius (metres)',
                    hintText: '200',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  dense: true,
                  title: const Text('Enforce strict blocking at this location'),
                  value: isStrict,
                  onChanged: (v) => setState(() => isStrict = v),
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
                final lat = double.tryParse(latCtrl.text);
                final lng = double.tryParse(lngCtrl.text);
                final radius = int.tryParse(radiusCtrl.text) ?? 200;
                if (nameCtrl.text.isEmpty || lat == null || lng == null) return;
                ref.read(contextRulesProvider.notifier).addLocationRule(
                      LocationRule(
                        name: nameCtrl.text.trim(),
                        lat: lat,
                        lng: lng,
                        radiusMeters: radius,
                        isStrict: isStrict,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRuleTile extends ConsumerWidget {
  final LocationRule rule;
  const _LocationRuleTile({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contextRulesProvider.notifier);
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: rule.isActive
              ? (rule.isStrict ? Colors.red : Colors.green)
              : Colors.grey,
        ),
        title: Text(rule.name),
        subtitle: Text(
          '${rule.lat.toStringAsFixed(4)}, ${rule.lng.toStringAsFixed(4)} · ${rule.radiusMeters}m · '
          '${rule.isStrict ? 'Strict' : 'Relaxed'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: rule.isActive,
              onChanged: (v) => notifier.toggleLocationRule(rule.id!, v),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => notifier.deleteLocationRule(rule.id!),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _ContextStatusCard extends StatelessWidget {
  final String label;
  final bool active;
  final String detail;

  const _ContextStatusCard({
    required this.label,
    required this.active,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.orange : Colors.grey;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.flash_on : Icons.flash_off,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ${active ? "ACTIVE" : "inactive"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  detail,
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

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
