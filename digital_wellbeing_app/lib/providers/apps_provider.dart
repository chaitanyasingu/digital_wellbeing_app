import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_info.dart';
import '../services/apps_repository.dart';

// Repository provider - single instance
final appsRepositoryProvider = Provider((ref) => AppsRepository());

// State for paginated apps loading
class AppsState {
  final List<AppInfo> apps;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final bool isInitialized;
  final int totalCount;

  AppsState({
    this.apps = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.isInitialized = false,
    this.totalCount = 0,
  });

  AppsState copyWith({
    List<AppInfo>? apps,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool? isInitialized,
    int? totalCount,
  }) {
    return AppsState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      isInitialized: isInitialized ?? this.isInitialized,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class PaginatedAppsNotifier extends StateNotifier<AppsState> {
  final AppsRepository _repository;
  static const int pageSize = 15; // Load 15 apps at a time

  PaginatedAppsNotifier(this._repository) : super(AppsState()) {
    // Auto-load first page on initialization
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize repository (seeds database if empty)
      await _repository.initialize();

      // Get total count
      final count = await _repository.getAppCount();

      state = state.copyWith(totalCount: count, hasMore: count > 0);

      // Load first page automatically
      if (count > 0) {
        await loadApps();
      }
    } catch (e) {
      print('Initialization error: $e');
      state = state.copyWith(
        error: 'Failed to initialize: $e',
        isInitialized: true,
      );
    }
  }

  /// Load next page of apps from database
  Future<void> loadApps({bool reset = false}) async {
    if (state.isLoading) return;

    if (reset) {
      state = AppsState(isLoading: true, totalCount: state.totalCount);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final offset = reset ? 0 : state.currentPage * pageSize;

      // Fetch from database (fast, local query)
      final newApps = await _repository.getApps(
        limit: pageSize,
        offset: offset,
      );

      print('Loaded ${newApps.length} apps from database (offset: $offset)');

      final updatedApps = reset ? newApps : [...state.apps, ...newApps];

      final hasMore =
          newApps.length == pageSize && updatedApps.length < state.totalCount;

      state = state.copyWith(
        apps: updatedApps,
        isLoading: false,
        hasMore: hasMore,
        currentPage: reset ? 1 : state.currentPage + 1,
        isInitialized: true,
      );

      print(
        'Showing ${updatedApps.length} of ${state.totalCount} apps, hasMore: $hasMore',
      );
    } catch (e) {
      print('Error loading apps: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  /// Search apps by name
  Future<void> searchApps(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _repository.searchApps(query);

      state = state.copyWith(
        apps: results,
        isLoading: false,
        hasMore: false, // Search shows all results
        isInitialized: true,
      );
    } catch (e) {
      print('Search error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sync with device (fetch real installed apps)
  Future<SyncResult> syncWithDevice() async {
    try {
      print('Starting device sync...');
      final result = await _repository.syncInstalledApps();
      print('Sync result: $result');

      // Refresh the list after sync
      if (result.success) {
        final newCount = await _repository.getAppCount();
        print('Updated app count: $newCount');
        state = state.copyWith(totalCount: newCount);
        await loadApps(reset: true);
        print('Reloaded app list after sync');
      } else {
        print('Sync failed: ${result.error}');
      }

      return result;
    } catch (e) {
      print('Sync error: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Reset to initial state
  void reset() {
    state = AppsState(totalCount: state.totalCount);
    loadApps();
  }
}

final paginatedAppsProvider =
    StateNotifierProvider<PaginatedAppsNotifier, AppsState>((ref) {
      return PaginatedAppsNotifier(ref.read(appsRepositoryProvider));
    });
