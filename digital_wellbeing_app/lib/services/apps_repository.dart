import '../models/app_info.dart';
import '../services/database_service.dart';
import '../services/app_service.dart';

/// Repository that manages app data from both local database and device
/// Follows the Repository pattern for clean architecture
class AppsRepository {
  final DatabaseService _databaseService;
  final AppService _appService;

  AppsRepository({DatabaseService? databaseService, AppService? appService})
    : _databaseService = databaseService ?? DatabaseService.instance,
      _appService = appService ?? AppService();

  /// Initialize repository - seeds database if empty
  Future<void> initialize() async {
    final hasApps = await _databaseService.hasApps();
    if (!hasApps) {
      // Seed with common apps on first launch
      await _databaseService.seedCommonApps();
    }
  }

  /// Get apps with pagination - reads from local database (fast)
  Future<List<AppInfo>> getApps({int limit = 15, int offset = 0}) async {
    return await _databaseService.getApps(limit: limit, offset: offset);
  }

  /// Get total count of apps in database
  Future<int> getAppCount() async {
    return await _databaseService.getAppCount();
  }

  /// Search apps by name - uses database index for fast search
  Future<List<AppInfo>> searchApps(String query) async {
    if (query.isEmpty) {
      return await getApps();
    }
    return await _databaseService.searchApps(query);
  }

  /// Sync installed apps from device to database
  /// This is called in background job - updates database with real installed apps
  Future<SyncResult> syncInstalledApps() async {
    try {
      // Get apps from device via Android API
      final installedApps = await _appService.getInstalledApps();

      // Get current apps in database
      final dbApps = await _databaseService.getApps(
        limit: 10000, // Get all
        installedOnly: false,
      );

      // Create set of installed package names for fast lookup
      final installedPackages = installedApps
          .map((app) => app.packageName)
          .toSet();
      final dbPackages = dbApps.map((app) => app.packageName).toSet();

      // Find new apps (in device but not in database)
      final newApps = installedApps
          .where((app) => !dbPackages.contains(app.packageName))
          .toList();

      // Find uninstalled apps (in database but not on device)
      final uninstalledPackages = dbPackages
          .where((pkg) => !installedPackages.contains(pkg))
          .toList();

      // Update database
      if (newApps.isNotEmpty) {
        await _databaseService.upsertApps(newApps);
      }

      if (uninstalledPackages.isNotEmpty) {
        await _databaseService.markAppsAsUninstalled(uninstalledPackages);
      }

      // Also update existing apps to ensure data is fresh
      final existingApps = installedApps
          .where((app) => dbPackages.contains(app.packageName))
          .toList();
      if (existingApps.isNotEmpty) {
        await _databaseService.upsertApps(existingApps);
      }

      return SyncResult(
        success: true,
        newAppsCount: newApps.length,
        removedAppsCount: uninstalledPackages.length,
        updatedAppsCount: existingApps.length,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Force refresh - clears database and re-syncs
  Future<void> forceRefresh() async {
    await _databaseService.clearAllApps();
    await _databaseService.seedCommonApps();
    await syncInstalledApps();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int newAppsCount;
  final int removedAppsCount;
  final int updatedAppsCount;
  final String? error;

  SyncResult({
    required this.success,
    this.newAppsCount = 0,
    this.removedAppsCount = 0,
    this.updatedAppsCount = 0,
    this.error,
  });

  @override
  String toString() {
    if (!success) return 'Sync failed: $error';
    return 'Sync completed: +$newAppsCount new, ~$updatedAppsCount updated, -$removedAppsCount removed';
  }
}
