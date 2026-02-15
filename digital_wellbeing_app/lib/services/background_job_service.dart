// TODO: Re-enable when workmanager compatibility issue is fixed
// import 'package:workmanager/workmanager.dart';
import 'dart:developer' as developer;
// import '../services/apps_repository.dart';

/// Background job service using WorkManager for periodic app syncing
/// NOTE: Currently disabled due to workmanager compatibility issues
class BackgroundJobService {
  static const String syncTaskName = 'app_sync_task';
  static const String syncTaskTag = 'daily_app_sync';

  /// Initialize WorkManager - must be called at app startup
  static Future<void> initialize() async {
    // TODO: Re-enable when workmanager is fixed
    developer.log(
      'Background job service disabled (workmanager compatibility issue)',
      name: 'BackgroundJobService',
    );
    /*
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
    */
  }

  /// Schedule daily app sync job
  static Future<void> scheduleDailySync() async {
    // TODO: Re-enable when workmanager is fixed
    developer.log(
      'Daily sync scheduling disabled (workmanager compatibility issue)',
      name: 'BackgroundJobService',
    );
    /*
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      tag: syncTaskTag,
      frequency: const Duration(hours: 24), // Run once per day
      constraints: Constraints(
        networkType: NetworkType.not_required, // Works offline
        requiresBatteryNotLow: true, // Respect battery
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.keep, // Don't duplicate
    );

    developer.log('Daily app sync scheduled', name: 'BackgroundJobService');
    */
  }

  /// Schedule one-time immediate sync (for force refresh)
  static Future<void> scheduleImmediateSync() async {
    // TODO: Re-enable when workmanager is fixed
    developer.log(
      'Immediate sync disabled (workmanager compatibility issue)',
      name: 'BackgroundJobService',
    );
    /*
    await Workmanager().registerOneOffTask(
      '${syncTaskName}_immediate',
      syncTaskName,
      tag: '${syncTaskTag}_immediate',
      constraints: Constraints(networkType: NetworkType.not_required),
      backoffPolicy: BackoffPolicy.exponential,
    );

    developer.log('Immediate app sync scheduled', name: 'BackgroundJobService');
    */
  }

  /// Cancel all pending sync jobs
  static Future<void> cancelAllSyncs() async {
    // TODO: Re-enable when workmanager is fixed
    /*
    await Workmanager().cancelByTag(syncTaskTag);
    developer.log('All app syncs cancelled', name: 'BackgroundJobService');
    */
  }

  /// Check if sync job is scheduled
  static Future<bool> isSyncScheduled() async {
    // Note: WorkManager doesn't provide a direct way to check this
    // This is a placeholder for future implementation
    return false; // Disabled
  }
}

/*
/// Top-level callback function for WorkManager
/// This runs in a separate isolate, so it can't access app state directly
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      developer.log('Background task started: $taskName', name: 'WorkManager');

      if (taskName == BackgroundJobService.syncTaskName) {
        // Create repository instance (in background isolate)
        final repository = AppsRepository();

        // Perform sync
        final result = await repository.syncInstalledApps();

        developer.log(
          'Background sync completed: ${result.toString()}',
          name: 'WorkManager',
        );

        return result.success;
      }

      return false;
    } catch (e) {
      developer.log(
        'Background task failed: $e',
        name: 'WorkManager',
        error: e,
      );
      return false;
    }
  });
}
*/
