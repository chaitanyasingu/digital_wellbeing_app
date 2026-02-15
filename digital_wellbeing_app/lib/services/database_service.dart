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
      version: 1,
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
  }

  /// Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations will go here
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

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
