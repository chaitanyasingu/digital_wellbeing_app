import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/apps_provider.dart';
import '../providers/rules_provider.dart';
import '../models/restriction_rules.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  Set<String> selectedApps = {};
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load currently selected apps
    final rules = ref.read(rulesProvider);
    selectedApps = Set.from(rules.alwaysAllowedApps);

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      final appsState = ref.read(paginatedAppsProvider);
      if (!appsState.isLoading && appsState.hasMore) {
        ref.read(paginatedAppsProvider.notifier).loadApps();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appsState = ref.watch(paginatedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allowed Apps'),
        actions: [
          // Sync button to fetch apps from device
          IconButton(
            onPressed: appsState.isLoading
                ? null
                : () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing apps...')),
                      );
                      final result = await ref
                          .read(paginatedAppsProvider.notifier)
                          .syncWithDevice();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.toString())),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e')),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.sync),
            tooltip: 'Sync with device',
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(rulesProvider.notifier)
                    .updateAllowedApps(selectedApps.toList());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apps updated successfully')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Database info banner
          if (appsState.isInitialized && appsState.totalCount > 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${appsState.totalCount} apps in database. Tap sync button to update from device.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${selectedApps.length} apps selected',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildAppsList(appsState)),
        ],
      ),
    );
  }

  Widget _buildAppsList(AppsState appsState) {
    // Show loading on initial load
    if (!appsState.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading apps from database...'),
          ],
        ),
      );
    }

    // Show error state
    if (appsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${appsState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(paginatedAppsProvider.notifier)
                  .loadApps(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter apps based on search
    final filteredApps = appsState.apps.where((app) {
      if (searchQuery.isEmpty) return true;
      return app.appName.toLowerCase().contains(searchQuery) ||
          app.packageName.toLowerCase().contains(searchQuery);
    }).toList();

    filteredApps.sort((a, b) => a.appName.compareTo(b.appName));

    if (filteredApps.isEmpty && searchQuery.isNotEmpty) {
      return const Center(child: Text('No apps found matching search'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredApps.length + (appsState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the bottom
        if (index == filteredApps.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: appsState.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () =>
                          ref.read(paginatedAppsProvider.notifier).loadApps(),
                      child: const Text('Load More Apps'),
                    ),
            ),
          );
        }

        final app = filteredApps[index];
        final isSelected = selectedApps.contains(app.packageName);
        final isDefault = defaultEssentialApps.contains(app.packageName);

        return ListTile(
          leading: Icon(
            isDefault ? Icons.phone_android : Icons.android,
            color: isDefault ? Colors.blue : null,
          ),
          title: Row(
            children: [
              Expanded(child: Text(app.appName)),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Essential',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12)),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  selectedApps.add(app.packageName);
                } else {
                  selectedApps.remove(app.packageName);
                }
              });
            },
          ),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedApps.remove(app.packageName);
              } else {
                selectedApps.add(app.packageName);
              }
            });
          },
        );
      },
    );
  }
}
