import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_info.dart';

/// SQLite database service for storing and managing installed apps
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'digital_wellbeing.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE apps (
        package_name TEXT PRIMARY KEY,
        app_name TEXT NOT NULL,
        is_system_app INTEGER NOT NULL DEFAULT 0,
        icon_data BLOB,
        added_date INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_installed INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create indices for faster queries
    await db.execute('CREATE INDEX idx_app_name ON apps(app_name)');
    await db.execute('CREATE INDEX idx_is_system ON apps(is_system_app)');
    await db.execute('CREATE INDEX idx_installed ON apps(is_installed)');

    await _createPhase5Tables(db);
    await _createPhase6Tables(db);
    await _createPhase7Tables(db);
    await _createPhase8Tables(db);
  }

  Future<void> _createPhase5Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_type TEXT NOT NULL,
        target_ms INTEGER NOT NULL DEFAULT 0,
        category TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS streaks (
        goal_id INTEGER PRIMARY KEY,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_success_date TEXT,
        freeze_used INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sleep_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        bedtime TEXT NOT NULL,
        wake_time TEXT NOT NULL,
        grace_period_mins INTEGER NOT NULL DEFAULT 0,
        blue_light_reminder INTEGER NOT NULL DEFAULT 0,
        blue_light_time TEXT NOT NULL DEFAULT '20:00',
        is_active INTEGER NOT NULL DEFAULT 0,
        days_of_week TEXT NOT NULL DEFAULT '1111111'
      )
    ''');
  }

  Future<void> _createPhase6Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        work_minutes INTEGER NOT NULL DEFAULT 25,
        break_minutes INTEGER NOT NULL DEFAULT 5,
        completed_rounds INTEGER NOT NULL DEFAULT 0,
        total_rounds INTEGER NOT NULL DEFAULT 4,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mood_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        mood_score INTEGER NOT NULL,
        note TEXT,
        screen_time_ms INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createPhase7Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS xp_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL DEFAULT 1,
        event_type TEXT NOT NULL,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements_unlocked (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        achievement_id TEXT NOT NULL,
        profile_id INTEGER NOT NULL DEFAULT 1,
        unlocked_at INTEGER NOT NULL,
        xp_awarded INTEGER NOT NULL DEFAULT 0,
        UNIQUE(achievement_id, profile_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS family_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        avatar_emoji TEXT NOT NULL DEFAULT '🧑',
        is_active INTEGER NOT NULL DEFAULT 0,
        is_child_mode INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_xp_profile ON xp_events(profile_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ach_profile ON achievements_unlocked(profile_id)');
  }

  /// Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPhase5Tables(db);
    }
    if (oldVersion < 3) {
      await _createPhase6Tables(db);
    }
    if (oldVersion < 4) {
      await _createPhase7Tables(db);
    }
    if (oldVersion < 5) {
      await _createPhase8Tables(db);
    }
  }

  Future<void> _createPhase8Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS context_wifi_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        ssid TEXT NOT NULL,
        effect TEXT NOT NULL DEFAULT 'relaxed',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS context_location_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        radius_meters INTEGER NOT NULL DEFAULT 200,
        effect TEXT NOT NULL DEFAULT 'strict',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS commitment_contracts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// Insert or update an app in the database
  Future<void> upsertApp(AppInfo app) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('apps', {
      'package_name': app.packageName,
      'app_name': app.appName,
      'is_system_app': app.isSystemApp ? 1 : 0,
      'added_date': now,
      'last_updated': now,
      'is_installed': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert multiple apps in a transaction (faster)
  Future<void> upsertApps(List<AppInfo> apps) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final app in apps) {
      batch.insert('apps', {
        'package_name': app.packageName,
        'app_name': app.appName,
        'is_system_app': app.isSystemApp ? 1 : 0,
        'added_date': now,
        'last_updated': now,
        'is_installed': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get all apps from database with pagination
  Future<List<AppInfo>> getApps({
    int limit = 15,
    int offset = 0,
    bool installedOnly = true,
  }) async {
    final db = await database;
    final maps = await db.query(
      'apps',
      where: installedOnly ? 'is_installed = ?' : null,
      whereArgs: installedOnly ? [1] : null,
      orderBy: 'app_name ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToAppInfo(map)).toList();
  }

  /// Get total count of apps
  Future<int> getAppCount({bool installedOnly = true}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM apps${installedOnly ? ' WHERE is_installed = 1' : ''}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Search apps by name
  Future<List<AppInfo>> searchApps(String query) async {
    final db = await database;
    final maps = await db.query(
      'apps',
      where: 'app_name LIKE ? AND is_installed = ?',
      whereArgs: ['%$query%', 1],
      orderBy: 'app_name ASC',
    );

    return maps.map((map) => _mapToAppInfo(map)).toList();
  }

  /// Mark apps as uninstalled (for apps no longer on device)
  Future<void> markAppsAsUninstalled(List<String> packageNames) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final packageName in packageNames) {
      batch.update(
        'apps',
        {'is_installed': 0, 'last_updated': now},
        where: 'package_name = ?',
        whereArgs: [packageName],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Delete all apps (use with caution)
  Future<void> clearAllApps() async {
    final db = await database;
    await db.delete('apps');
  }

  /// Check if database has any apps
  Future<bool> hasApps() async {
    final count = await getAppCount();
    return count > 0;
  }

  /// Seed database with common Android apps
  Future<void> seedCommonApps() async {
    final commonApps = _getCommonAndroidApps();
    await upsertApps(commonApps);
  }

  /// Convert database map to AppInfo object
  AppInfo _mapToAppInfo(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      isSystemApp: (map['is_system_app'] as int) == 1,
    );
  }

  /// List of common Android apps to seed the database
  List<AppInfo> _getCommonAndroidApps() {
    return [
      // Communication
      AppInfo(
        packageName: 'com.android.dialer',
        appName: 'Phone',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.android.contacts',
        appName: 'Contacts',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.android.mms',
        appName: 'Messages',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.google.android.gm',
        appName: 'Gmail',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.google.android.talk',
        appName: 'Google Chat',
        isSystemApp: false,
      ),

      // Media
      AppInfo(
        packageName: 'com.android.camera2',
        appName: 'Camera',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.android.gallery3d',
        appName: 'Gallery',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.photos',
        appName: 'Google Photos',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.google.android.music',
        appName: 'YouTube Music',
        isSystemApp: false,
      ),

      // Social Media
      AppInfo(
        packageName: 'com.facebook.katana',
        appName: 'Facebook',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.twitter.android',
        appName: 'Twitter',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.snapchat.android',
        appName: 'Snapchat',
        isSystemApp: false,
      ),

      // Browser
      AppInfo(
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.android.browser',
        appName: 'Browser',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'org.mozilla.firefox',
        appName: 'Firefox',
        isSystemApp: false,
      ),

      // Utilities
      AppInfo(
        packageName: 'com.android.settings',
        appName: 'Settings',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.android.calculator2',
        appName: 'Calculator',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.android.deskclock',
        appName: 'Clock',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.android.calendar',
        appName: 'Calendar',
        isSystemApp: true,
      ),
      AppInfo(
        packageName: 'com.google.android.calendar',
        appName: 'Google Calendar',
        isSystemApp: false,
      ),

      // Google Apps
      AppInfo(
        packageName: 'com.google.android.googlequicksearchbox',
        appName: 'Google',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.maps',
        appName: 'Google Maps',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.docs',
        appName: 'Google Drive',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.google.android.keep',
        appName: 'Google Keep',
        isSystemApp: false,
      ),

      // Shopping & Entertainment
      AppInfo(
        packageName: 'com.google.android.apps.walletnfcrel',
        appName: 'Google Wallet',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.amazon.mShop.android.shopping',
        appName: 'Amazon',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.netflix.mediaclient',
        appName: 'Netflix',
        isSystemApp: false,
      ),
      AppInfo(
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        isSystemApp: false,
      ),
    ];
  }

  // ── Focus Sessions ──────────────────────────────────────────────────────

  Future<int> insertFocusSession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert('focus_sessions', session);
  }

  Future<void> updateFocusSession(int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('focus_sessions', values,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFocusSessionsForDate(
      String dateYmd) async {
    final db = await database;
    final start =
        DateTime.parse('$dateYmd 00:00:00').millisecondsSinceEpoch;
    final end =
        DateTime.parse('$dateYmd 23:59:59').millisecondsSinceEpoch;
    return db.query('focus_sessions',
        where: 'start_time BETWEEN ? AND ?',
        whereArgs: [start, end],
        orderBy: 'start_time DESC');
  }

  // ── Mood Entries ────────────────────────────────────────────────────────

  Future<int> upsertMoodEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('mood_entries', entry,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getMoodEntryForDate(String dateYmd) async {
    final db = await database;
    final rows = await db.query('mood_entries',
        where: 'date = ?', whereArgs: [dateYmd]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getRecentMoodEntries(int days) async {
    final db = await database;
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final rows = await db.query('mood_entries',
          where: 'date = ?', whereArgs: [dateStr]);
      if (rows.isNotEmpty) results.add(rows.first);
    }
    return results;
  }

  /// Look up display names for a list of package names
  Future<Map<String, String>> getAppNames(List<String> packageNames) async {
    if (packageNames.isEmpty) return {};
    final db = await database;
    final placeholders = packageNames.map((_) => '?').join(',');
    final rows = await db.rawQuery(
      'SELECT package_name, app_name FROM apps WHERE package_name IN ($placeholders)',
      packageNames,
    );
    return Map.fromEntries(
      rows.map((r) => MapEntry(r['package_name'] as String, r['app_name'] as String)),
    );
  }

  // ── XP Events ───────────────────────────────────────────────────────────

  Future<int> insertXpEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.insert('xp_events', event);
  }

  Future<int> sumXpForProfile(int profileId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(xp_earned) as total FROM xp_events WHERE profile_id = ?',
        [profileId]);
    return (Sqflite.firstIntValue(result) ?? 0);
  }

  // ── Achievements ─────────────────────────────────────────────────────────

  Future<int> insertAchievementUnlock(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('achievements_unlocked', row,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getUnlockedAchievementIds(int profileId) async {
    final db = await database;
    final rows = await db.query('achievements_unlocked',
        columns: ['achievement_id'],
        where: 'profile_id = ?',
        whereArgs: [profileId]);
    return rows.map((r) => r['achievement_id'] as String).toList();
  }

  // ── Gamification Stats ───────────────────────────────────────────────────

  Future<int> countCompletedFocusSessions() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM focus_sessions WHERE end_time IS NOT NULL AND completed_rounds > 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> sumFocusMinutes() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(work_minutes * completed_rounds) as total FROM focus_sessions WHERE end_time IS NOT NULL');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countDistinctMoodDays() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(DISTINCT date) as cnt FROM mood_entries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getMaxCurrentStreak() async {
    final db = await database;
    final rows = await db.query('streaks',
        columns: ['current_streak'],
        orderBy: 'current_streak DESC',
        limit: 1);
    if (rows.isEmpty) return 0;
    return (rows.first['current_streak'] as int?) ?? 0;
  }

  // ── Family Profiles ──────────────────────────────────────────────────────

  Future<int> insertFamilyProfile(Map<String, dynamic> profile) async {
    final db = await database;
    return await db.insert('family_profiles', profile);
  }

  Future<void> updateFamilyProfile(int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('family_profiles', values,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFamilyProfile(int id) async {
    final db = await database;
    await db.delete('family_profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllFamilyProfiles() async {
    final db = await database;
    return db.query('family_profiles', orderBy: 'created_at ASC');
  }

  // ── Context WiFi Rules ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getContextWifiRules() async {
    final db = await database;
    return db.query('context_wifi_rules', orderBy: 'id ASC');
  }

  Future<int> insertContextWifiRule(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('context_wifi_rules', row);
  }

  Future<void> updateContextWifiRule(int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('context_wifi_rules', values,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteContextWifiRule(int id) async {
    final db = await database;
    await db.delete('context_wifi_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ── Context Location Rules ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getContextLocationRules() async {
    final db = await database;
    return db.query('context_location_rules', orderBy: 'id ASC');
  }

  Future<int> insertContextLocationRule(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('context_location_rules', row);
  }

  Future<void> updateContextLocationRule(
      int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('context_location_rules', values,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteContextLocationRule(int id) async {
    final db = await database;
    await db.delete('context_location_rules',
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Commitment Contracts ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCommitmentContracts() async {
    final db = await database;
    return db.query('commitment_contracts',
        where: 'is_active = 1', orderBy: 'start_time ASC');
  }

  Future<int> insertCommitmentContract(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('commitment_contracts', row);
  }

  Future<void> updateCommitmentContract(
      int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('commitment_contracts', values,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
