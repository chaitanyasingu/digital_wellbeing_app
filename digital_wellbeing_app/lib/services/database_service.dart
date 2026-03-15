import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_info.dart';
import '../models/activity_idea.dart';

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
      version: 3,
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

    await _createActivitiesTable(db);
    await _seedActivities(db);
  }

  Future<void> _createActivitiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        emoji TEXT NOT NULL,
        category TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 10,
        steps TEXT NOT NULL DEFAULT '',
        benefits TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createActivitiesTable(db);
      await _seedActivities(db);
    }
    if (oldVersion < 3) {
      // Add steps & benefits columns if upgrading from v2
      try {
        await db.execute(
            "ALTER TABLE activities ADD COLUMN steps TEXT NOT NULL DEFAULT ''");
        await db.execute(
            "ALTER TABLE activities ADD COLUMN benefits TEXT NOT NULL DEFAULT ''");
      } catch (_) {}
      // Wipe stale rows and re-seed with full enriched data
      await db.delete('activities');
      await _seedActivities(db);
    }
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

  // ── Activity Ideas ──────────────────────────────────────────────────────────

  /// Insert default self-improvement activities (called once on DB creation).
  Future<void> _seedActivities(Database db) async {
    final activities = _getDefaultActivities();
    final batch = db.batch();
    for (final a in activities) {
      batch.insert('activities', a.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Drops and recreates the activities table, then seeds it fresh.
  Future<void> _rebuildActivitiesTable(Database db) async {
    await db.execute('DROP TABLE IF EXISTS activities');
    await _createActivitiesTable(db);
    await _seedActivities(db);
  }

  /// Returns true only when the activities table exists AND has the steps column.
  Future<bool> _activitiesTableReady(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='activities'",
    );
    if (tables.isEmpty) return false;
    final cols = await db.rawQuery("PRAGMA table_info(activities)");
    return cols.any((c) => c['name'] == 'steps');
  }

  /// Returns all activities in a random order, limited to [count].
  Future<List<ActivityIdea>> getRandomActivities({int count = 5}) async {
    final db = await database;
    if (!await _activitiesTableReady(db)) {
      await _rebuildActivitiesTable(db);
    }
    final maps = await db.rawQuery(
      'SELECT * FROM activities ORDER BY RANDOM() LIMIT ?',
      [count],
    );
    if (maps.isEmpty) {
      await _seedActivities(db);
      return (await db.rawQuery(
        'SELECT * FROM activities ORDER BY RANDOM() LIMIT ?',
        [count],
      )).map(ActivityIdea.fromMap).toList();
    }
    return maps.map(ActivityIdea.fromMap).toList();
  }

  /// Returns all activities.
  Future<List<ActivityIdea>> getAllActivities() async {
    final db = await database;
    try {
      final maps =
          await db.query('activities', orderBy: 'category ASC, title ASC');
      return maps.map(ActivityIdea.fromMap).toList();
    } catch (_) {
      await _createActivitiesTable(db);
      await _seedActivities(db);
      final maps =
          await db.query('activities', orderBy: 'category ASC, title ASC');
      return maps.map(ActivityIdea.fromMap).toList();
    }
  }

  List<ActivityIdea> _getDefaultActivities() {
    return const [
      ActivityIdea(
        title: 'Box Breathing',
        description:
            'Inhale for 4 s, hold for 4 s, exhale for 4 s, hold for 4 s. Repeat 4 rounds to calm your nervous system.',
        emoji: '🫁',
        category: 'Mindfulness',
        durationMinutes: 5,
        stepsRaw:
            'Sit upright in a chair or on the floor with your spine straight\n'
            'Exhale fully through your mouth to empty your lungs\n'
            'Inhale slowly through your nose for exactly 4 counts\n'
            'Hold your breath for 4 counts — keep your chest still\n'
            'Exhale smoothly through your nose or mouth for 4 counts\n'
            'Hold empty for 4 counts before the next inhale\n'
            'Repeat the full cycle at least 4 times\n'
            'After the last round, breathe normally and notice how you feel',
        benefitsRaw:
            'Activates the parasympathetic nervous system, reducing stress hormones instantly\n'
            'Lowers heart rate and blood pressure within minutes\n'
            'Improves focus and mental clarity by increasing oxygen to the brain\n'
            'Reduces anxiety and panic — used by Navy SEALs before high-pressure situations\n'
            'Builds long-term emotional regulation and resilience with daily practice',
      ),
      ActivityIdea(
        title: 'Cold Shower',
        description:
            'Finish your shower with 60 seconds of cold water to boost alertness, mood and circulation.',
        emoji: '🚿',
        category: 'Fitness',
        durationMinutes: 10,
        stepsRaw:
            'Take your normal warm shower first\n'
            'Before turning off, slowly reduce the temperature to cool\n'
            'Then turn it fully cold — breathe slowly and do not fight it\n'
            'Direct the cold water to your head, neck, chest and back\n'
            'Stay under for at least 30–60 seconds while breathing calmly\n'
            'Focus on your breath, not the discomfort — it fades in 10–15 seconds\n'
            'Turn off the water and towel dry vigorously to warm up',
        benefitsRaw:
            'Triggers release of norepinephrine — a potent mood and focus booster\n'
            'Increases alertness and energy for up to 2–3 hours afterward\n'
            'Improves blood circulation and lymphatic drainage\n'
            'Builds mental toughness and willpower by doing something uncomfortable intentionally\n'
            'Reduces muscle soreness and speeds up recovery after exercise\n'
            'Linked to reduced symptoms of depression in clinical studies',
      ),
      ActivityIdea(
        title: 'Meditate',
        description:
            'Sit comfortably, close your eyes and focus only on your breath for 10 minutes.',
        emoji: '🧘',
        category: 'Mindfulness',
        durationMinutes: 10,
        stepsRaw:
            'Find a quiet spot — sit on a chair, cushion or floor with your back straight\n'
            'Set a gentle timer for 10 minutes so you are not watching the clock\n'
            'Close your eyes and let your hands rest comfortably on your knees\n'
            'Take 3 deep breaths to settle in, then let your breathing become natural\n'
            'Place your full attention on the sensation of breath at your nostrils or belly\n'
            'When your mind wanders (it will), gently notice it and return to the breath — no judgment\n'
            'Each return to the breath is a mental rep — the practice is in the returning\n'
            'When the timer sounds, open your eyes slowly and sit still for 30 seconds',
        benefitsRaw:
            'Reduces cortisol (stress hormone) levels measurably after just 8 weeks\n'
            'Thickens the prefrontal cortex — the part of the brain responsible for decision-making\n'
            'Improves attention span and ability to focus deeply\n'
            'Reduces rumination and negative self-talk over time\n'
            'Improves sleep quality, especially when practiced in the evening\n'
            'Lowers anxiety and symptoms of depression, comparable to medication in some studies',
      ),
      ActivityIdea(
        title: 'Walk the Hallway',
        description:
            'Take a brisk walk around the passage, lobby or outside to stretch your legs and clear your mind.',
        emoji: '🚶',
        category: 'Fitness',
        durationMinutes: 10,
        stepsRaw:
            'Stand up from where you have been sitting and take a few slow breaths\n'
            'Start walking at a pace slightly faster than casual — you should be able to talk but feel the effort\n'
            'Let your arms swing naturally to engage your upper body\n'
            'Keep your posture upright — head up, shoulders back, core lightly engaged\n'
            'Walk continuously for at least 8–10 minutes without stopping to check your phone\n'
            'If outside, try to notice your surroundings — trees, sky, sounds — rather than thinking about worries\n'
            'Finish with 1–2 minutes of slower walking to cool down',
        benefitsRaw:
            'Breaks sedentary time — even 10 minutes reverses blood pooling in the legs\n'
            'Boosts BDNF (brain-derived neurotrophic factor), fueling memory and learning\n'
            'Reduces blood sugar spikes after sitting for long periods\n'
            'Elevates mood through a mild endorphin release\n'
            'A 10-minute walk can improve creative thinking by up to 81% (Stanford study)\n'
            'Reduces feelings of restlessness and screen-craving over time',
      ),
      ActivityIdea(
        title: 'Drink Water',
        description:
            'Grab a full glass of water. Staying hydrated improves focus, energy and mood.',
        emoji: '💧',
        category: 'Health',
        durationMinutes: 2,
        stepsRaw:
            'Go to your kitchen or nearest water source\n'
            'Fill a large glass (at least 300 ml / 10 oz) with cool water\n'
            'Drink it slowly — sip by sip rather than gulping\n'
            'While drinking, sit down, breathe and be present — no screen\n'
            'If plain water feels boring, add a slice of lemon or a pinch of salt for electrolytes\n'
            'Aim to finish the full glass within 2–3 minutes',
        benefitsRaw:
            'Even mild dehydration (1–2% of body weight) reduces concentration by up to 13%\n'
            'Rehydrating improves short-term memory and reaction time within 20 minutes\n'
            'Supports kidney function and removes metabolic waste products\n'
            'Reduces headaches — the most common cause of mid-day headaches is dehydration\n'
            'Promotes healthy skin, digestion and joint lubrication',
      ),
      ActivityIdea(
        title: 'Write 3 Gratitudes',
        description:
            'Jot down 3 specific things you are grateful for today. Shifts your mindset to positivity.',
        emoji: '📝',
        category: 'Mindfulness',
        durationMinutes: 5,
        stepsRaw:
            'Grab a notebook or open a notes app — write by hand if possible\n'
            'At the top, write today\'s date\n'
            'Think of 3 things that happened today (or recently) that you are genuinely thankful for\n'
            'Be specific — not just "family" but "my sister texted to check on me today"\n'
            'For each item, write 1–2 sentences about why it matters to you\n'
            'Take a moment to actually feel the gratitude — put the pen down and breathe it in\n'
            'You can keep the same journal to look back on in hard times',
        benefitsRaw:
            'Regular gratitude journaling rewires the brain\'s negativity bias over 3–4 weeks\n'
            'Linked to measurable increases in long-term happiness and life satisfaction\n'
            'Reduces envy, resentment and frustration by shifting focus to abundance\n'
            'Improves sleep quality when practiced at night\n'
            'Strengthens social relationships as you become more appreciative of others\n'
            'Proven to reduce symptoms of anxiety and mild depression (positive psychology research)',
      ),
      ActivityIdea(
        title: 'Full-Body Stretch',
        description:
            'Slowly stretch your neck, shoulders, back and legs to release built-up tension.',
        emoji: '🤸',
        category: 'Fitness',
        durationMinutes: 5,
        stepsRaw:
            'Stand or sit tall and take 3 deep breaths to begin\n'
            'Neck: slowly tilt your right ear to your right shoulder, hold 20 s, repeat left\n'
            'Shoulders: cross one arm across your chest, hold it with the opposite hand, hold 20 s each side\n'
            'Chest: interlace your fingers behind your back, push your chest forward and hold 20 s\n'
            'Back: sit on a chair and twist your upper body gently to each side, hold 20 s each\n'
            'Hamstrings: stand and hinge forward at the hips with a slight bend in the knees, hold 30 s\n'
            'Hip flexors: step one foot forward into a lunge, keep the back knee down, hold 30 s each side\n'
            'Never push into sharp pain — stretches should feel like gentle tension, not pain',
        benefitsRaw:
            'Relieves muscle tightness caused by prolonged sitting at a desk or screen\n'
            'Improves posture by lengthening the muscles that get shortened by hunching\n'
            'Increases blood flow to muscles and connective tissue\n'
            'Reduces risk of injury during physical activity\n'
            'Signals the nervous system to shift from stress mode to rest mode\n'
            'Consistent stretching improves joint range of motion over weeks',
      ),
      ActivityIdea(
        title: 'Read a Book Chapter',
        description:
            'Pick up a non-fiction or personal-growth book and read at least one chapter.',
        emoji: '📖',
        category: 'Learning',
        durationMinutes: 15,
        stepsRaw:
            'Choose a physical book or e-reader — avoid reading on your main phone to prevent distraction\n'
            'Find a quiet, well-lit spot and sit comfortably\n'
            'Before you start, recall what happened in the last chapter you read\n'
            'Read at a comfortable pace — comprehension matters more than speed\n'
            'Underline or highlight sentences that resonate with you\n'
            'After finishing the chapter, close the book and spend 60 seconds recalling the key ideas\n'
            'Write a one-line insight in a notebook or sticky note to reinforce the memory',
        benefitsRaw:
            'Reading 15–30 minutes a day reduces stress by up to 68% (University of Sussex study)\n'
            'Builds vocabulary and verbal intelligence continuously\n'
            'Non-fiction reading compounds knowledge — readers gain the equivalent of years of experience in hours\n'
            'Improves deep focus and the ability to sustain attention for long periods\n'
            'Stimulates the imagination and analytical thinking\n'
            'People who read regularly are on average more empathetic and socially perceptive',
      ),
      ActivityIdea(
        title: '10 Push-Ups',
        description:
            'Drop and do 10 push-ups. A quick burst of exercise boosts energy and mental clarity.',
        emoji: '💪',
        category: 'Fitness',
        durationMinutes: 3,
        stepsRaw:
            'Place your hands on the floor slightly wider than shoulder-width\n'
            'Extend your legs behind you — balance on hands and toes (or knees for a modified version)\n'
            'Keep your body in a straight line from head to heels — tighten your core\n'
            'Lower your chest towards the floor by bending your elbows to about 90 degrees\n'
            'Pause for 1 second at the bottom — do not let your chest touch the floor\n'
            'Push powerfully back up to the starting position, fully extending your arms\n'
            'Breathe in on the way down, breathe out on the way up\n'
            'Complete 10 reps — rest 60 seconds and try a second set if you feel up to it',
        benefitsRaw:
            'Activates chest, shoulders, triceps and core simultaneously — maximum muscles in minimal time\n'
            'Releases endorphins immediately, reducing stress and boosting mood\n'
            'Increases heart rate, sending more oxygen to the brain for sharper thinking\n'
            'Builds upper-body strength with zero equipment needed\n'
            'Counteracts the forward-slouch posture from screen time\n'
            'Daily push-ups are linked to reduced cardiovascular disease risk over time',
      ),
      ActivityIdea(
        title: 'Tidy Your Space',
        description:
            'Spend a few minutes organising your desk or room. A clean environment fosters a clear mind.',
        emoji: '🏠',
        category: 'Productivity',
        durationMinutes: 10,
        stepsRaw:
            'Set a 10-minute timer so you stay focused and do not get overwhelmed\n'
            'Start with flat surfaces — desk, table, bed — remove everything that does not belong\n'
            'Group similar items together (books, cables, stationery)\n'
            'Throw away any rubbish or items you no longer need\n'
            'Wipe down surfaces quickly with a cloth if available\n'
            'Put items back intentionally — give everything a defined home\n'
            'Take one final look around the room and appreciate the difference\n'
            'Stop when the timer rings — do not extend into a full deep-clean session',
        benefitsRaw:
            'Visual clutter competes for your attention, reducing cognitive bandwidth by up to 20%\n'
            'A tidy environment signals to the brain that things are under control, reducing anxiety\n'
            'Increases productivity immediately — known as the "broken window" effect in reverse\n'
            'Makes it easier to start working or studying because there is less friction\n'
            'Creates a sense of accomplishment and self-respect\n'
            'Reduces the time wasted searching for misplaced items daily',
      ),
      ActivityIdea(
        title: 'Prepare a Healthy Snack',
        description:
            'Slice some fruit, make a handful of nuts, or blend a quick smoothie to fuel your body.',
        emoji: '🥗',
        category: 'Health',
        durationMinutes: 10,
        stepsRaw:
            'Pick one of: a piece of whole fruit, a handful of nuts, Greek yogurt, sliced vegetables with hummus, or a banana\n'
            'Wash and prepare your food with care — take your time rather than rushing\n'
            'Eat at a table, away from screens\n'
            'Chew slowly — aim for 20–30 chews per bite to aid digestion\n'
            'Notice the taste, texture and smell of the food without distraction\n'
            'Drink a glass of water alongside the snack\n'
            'Clean up before you sit down again',
        benefitsRaw:
            'Eating nutritious whole foods stabilises blood sugar, preventing energy crashes and mood dips\n'
            'Nuts and seeds provide healthy fats essential for brain function and hormone production\n'
            'Fruit provides natural sugars alongside fibre, antioxidants and vitamins\n'
            'Mindful eating reduces overeating and improves your relationship with food\n'
            'Preparing your own food builds healthy habits and reduces reliance on ultra-processed snacks\n'
            'Taking a proper break increases afternoon productivity versus eating at your desk',
      ),
      ActivityIdea(
        title: 'Call a Friend or Family',
        description:
            'Reconnect with someone you care about. Real conversations strengthen relationships.',
        emoji: '📞',
        category: 'Social',
        durationMinutes: 15,
        stepsRaw:
            'Think of one person you have not spoken to in a while — not just texted\n'
            'Step somewhere quiet and private before calling\n'
            'When the call connects, ask genuinely "How are you really doing?" and listen fully\n'
            'Do not fill silences immediately — let the other person speak without rushing to respond\n'
            'Share something real about your own life, not just surface updates\n'
            'Before hanging up, make a plan to speak again or meet if possible\n'
            'After the call, notice how you feel compared to before',
        benefitsRaw:
            'Strong social connections are the single biggest predictor of long-term happiness (Harvard Study of Adult Development)\n'
            'A warm phone call lowers cortisol at the same level as a physical hug\n'
            'Reduces feelings of loneliness and isolation which are linked to chronic illness\n'
            'Strengthens the bond — relationships need regular investment, not just crisis contact\n'
            'Practicing deep listening builds emotional intelligence\n'
            'Helps you gain perspective on your own problems by hearing others\' lives',
      ),
      ActivityIdea(
        title: 'Plan Tomorrow',
        description:
            'Write your top 3 priorities for tomorrow so you start the next day with clarity and purpose.',
        emoji: '📋',
        category: 'Productivity',
        durationMinutes: 5,
        stepsRaw:
            'Grab a notebook, planner or notes app\n'
            'Review what you did today in 30 seconds — what got done, what did not\n'
            'Ask yourself: "What are the 3 most important things I must do tomorrow?"\n'
            'Write down these 3 tasks in order of importance — no more than 3\n'
            'For each task, write the very first action you need to take (e.g. "open the report file")\n'
            'Set out anything you will need tomorrow (notebook, clothes, keys, etc.)\n'
            'Close the planner — you are done thinking about work for today',
        benefitsRaw:
            'Reduces the cognitive load of "what do I do next?" which drains willpower in the morning\n'
            'Starting the day with a clear intention increases the chance of completing meaningful work\n'
            'Writing down tasks offloads them from working memory, reducing evening anxiety\n'
            'Creates a closing ritual that signals the brain to transition from work mode to rest\n'
            'The 3-priority rule prevents overwhelm and ensures the most important work gets done\n'
            'Regular evening planning improves sleep by reducing unresolved mental loops',
      ),
      ActivityIdea(
        title: '5-Minute Yoga',
        description:
            'Flow through a few simple poses — child pose, cat-cow, downward dog — to improve flexibility.',
        emoji: '🧘',
        category: 'Fitness',
        durationMinutes: 5,
        stepsRaw:
            'Stand barefoot on a mat or carpet and take 5 deep breaths\n'
            'Cat-Cow (1 min): on hands and knees, inhale to arch your back (cow), exhale to round it (cat), repeat 8x\n'
            'Child\'s Pose (1 min): sit back onto your heels, stretch arms forward on the floor, breathe deeply\n'
            'Downward Dog (1 min): push up onto hands and feet in an inverted V shape, hold and press heels toward the floor\n'
            'Low Lunge (30 s each side): step one foot forward between hands, lower the back knee, reach arms overhead\n'
            'Seated Forward Fold (1 min): sit with legs straight, hinge forward from the hips and reach for your feet\n'
            'Finish in Corpse Pose: lie flat, arms by your sides, close your eyes, breathe naturally for 30 seconds',
        benefitsRaw:
            'Improves spinal mobility and counteracts compression from sitting for hours\n'
            'Activates the parasympathetic nervous system within 3–5 minutes of practice\n'
            'Increases body awareness, helping you catch tension before it becomes pain\n'
            'Improves flexibility progressively — even 5 minutes a day creates change within 2 weeks\n'
            'Reduces lower-back pain, one of the most common complaints from desk workers\n'
            'Combines movement, breath and presence — a trifecta for mental calm',
      ),
      ActivityIdea(
        title: 'Sketch or Doodle',
        description:
            'Grab pen and paper and draw freely. Creative expression reduces stress and sparks creativity.',
        emoji: '✏️',
        category: 'Creativity',
        durationMinutes: 10,
        stepsRaw:
            'Get a plain sheet of paper and a pen or pencil — no special tools needed\n'
            'Start without a plan — begin with a single shape, line or word\n'
            'Let your hand move freely without judging what appears on the page\n'
            'Try a simple technique: zentangle (repeating patterns), blind contour (draw without looking at the paper), or just fill the page with anything that comes to mind\n'
            'Do not erase — imperfections are part of the process\n'
            'Keep going for the full 10 minutes even if you feel stuck — boredom often precedes a burst of ideas\n'
            'At the end, look at what you made without judging it',
        benefitsRaw:
            'Activates the right hemisphere of the brain, shifting you out of analytical overthinking\n'
            'Reduces cortisol levels comparably to other mindfulness activities\n'
            'Strengthens hand-eye coordination and fine motor control\n'
            'Boosts divergent thinking — the type of creativity that generates multiple solutions\n'
            'Gives the verbal mind a rest, which often leads to unexpected insights\n'
            'Builds confidence to take action without needing perfection first — a skill that transfers to life',
      ),
      ActivityIdea(
        title: 'Learn 5 New Words',
        description:
            'Open a dictionary or language app and learn 5 new words in any language you want to improve.',
        emoji: '📚',
        category: 'Learning',
        durationMinutes: 10,
        stepsRaw:
            'Choose a language you are learning or want to improve — including your own\n'
            'Open a dictionary, flashcard app (Anki, Duolingo) or simply Google "interesting English words"\n'
            'Pick 5 words that are genuinely unfamiliar and interesting to you\n'
            'For each word: read the definition, read it aloud once, then read the example sentence\n'
            'Write each word and its meaning by hand in a vocabulary notebook\n'
            'Try to use each word in a sentence of your own — write it down\n'
            'Revisit these 5 words again tomorrow to move them from short-term to long-term memory',
        benefitsRaw:
            'Vocabulary is one of the strongest predictors of overall cognitive ability and career success\n'
            'Learning new words builds new neural pathways and keeps the brain plastic as you age\n'
            'A richer vocabulary allows you to express thoughts more precisely, improving communication\n'
            'Spaced repetition (reviewing words over time) is the most efficient form of learning\n'
            'Learning any language improves executive function and multitasking ability\n'
            '5 words a day = 1,825 words a year — fluency in a new language within 2–3 years',
      ),
      ActivityIdea(
        title: '30 Jumping Jacks',
        description:
            'Do 30 jumping jacks to rapidly raise your heart rate and shake off mental fatigue.',
        emoji: '🏃',
        category: 'Fitness',
        durationMinutes: 3,
        stepsRaw:
            'Stand with feet together and arms at your sides\n'
            'Jump and simultaneously spread your feet wider than shoulder-width\n'
            'At the same time, raise both arms out and overhead so your hands nearly meet\n'
            'Jump back to the starting position with feet together and arms down — that is one rep\n'
            'Keep a steady rhythm — aim for one jump per second\n'
            'Breathe continuously — do not hold your breath\n'
            'Complete 30 reps in 2–3 minutes; rest and repeat if you want more intensity',
        benefitsRaw:
            'Raises heart rate within 30 seconds, delivering more oxygen to the brain\n'
            'Triggers a rapid endorphin release that lifts mood within 2–3 minutes\n'
            'Burns roughly 8–10 calories per minute — a quick metabolic boost\n'
            'Improves coordination by engaging multiple muscle groups simultaneously\n'
            'Acts as a pattern interrupt — immediately breaks the trance of passive screen use\n'
            'No equipment, no space required — doable anywhere',
      ),
      ActivityIdea(
        title: 'Brew Herbal Tea',
        description:
            'Make a calming cup of chamomile, peppermint or green tea. A ritual that soothes the mind.',
        emoji: '🍵',
        category: 'Health',
        durationMinutes: 5,
        stepsRaw:
            'Choose your tea: chamomile (calming), peppermint (focus + digestion), green tea (gentle energy), ginger (warming)\n'
            'Boil fresh water and let it cool slightly — green tea brews best at 70–80°C, herbal at 95°C\n'
            'Place the tea bag or loose leaves in your cup or a teapot\n'
            'Pour the water and let it steep for the correct time: green tea 2–3 min, herbal 5–7 min\n'
            'While it steeps, stand without your phone and just be present\n'
            'Wrap both hands around the warm cup and take 5 slow breaths\n'
            'Sip slowly — taste each sip rather than drinking it absent-mindedly',
        benefitsRaw:
            'Chamomile contains apigenin, a compound that binds to brain receptors to promote calm and sleep\n'
            'Green tea provides L-theanine, which produces alert relaxation without the jitters of coffee\n'
            'Peppermint tea increases alertness and has been shown to improve memory in studies\n'
            'The ritual of making tea is itself a mindfulness practice that signals a healthy pause\n'
            'Warm liquids soothe the digestive system and support the gut-brain axis\n'
            'Staying hydrated with warm fluids is gentler on the kidneys than cold water for many people',
      ),
      ActivityIdea(
        title: 'Mindful Listening',
        description:
            'Close your eyes and spend 5 minutes paying close attention to the sounds around you.',
        emoji: '👂',
        category: 'Mindfulness',
        durationMinutes: 5,
        stepsRaw:
            'Sit or lie down comfortably in whatever space you are in\n'
            'Set a timer for 5 minutes\n'
            'Close your eyes and take 3 slow breaths to arrive in the present\n'
            'Begin listening — do not try to block anything out\n'
            'Notice the nearest sounds first, then gradually expand your attention to distant sounds\n'
            'Label each sound neutrally in your mind: "traffic", "fan humming", "bird", "voice"\n'
            'When your mind wanders to thoughts, gently return focus to the sounds\n'
            'Notice the silence between sounds — sit with it without filling it',
        benefitsRaw:
            'Trains the nervous system to process sensory input without reactivity — reduces startle response\n'
            'Quickly anchors attention to the present moment, interrupting rumination about past or future\n'
            'Improves active listening skills in conversations by building the habit of truly hearing\n'
            'Reduces sensory overwhelm in noisy environments over time\n'
            'Requires zero technique — accessible to anyone at any moment\n'
            'Studies show 5 minutes of sensory mindfulness reduces reported anxiety as effectively as 15 minutes of breathing exercises',
      ),
      ActivityIdea(
        title: 'Journal Your Feelings',
        description:
            'Write freely about how you feel right now. Putting emotions into words reduces stress.',
        emoji: '✍️',
        category: 'Mindfulness',
        durationMinutes: 10,
        stepsRaw:
            'Get a private notebook or open a secure notes app\n'
            'Set a timer for 10 minutes and write continuously — do not stop even if it feels pointless\n'
            'Start with: "Right now I feel..." and let the words come without editing or judging\n'
            'Write whatever is true — anger, confusion, numbness, joy — all of it is valid\n'
            'If you get stuck, write "I don\'t know what to write" until something surfaces\n'
            'Do not re-read what you have written until the timer ends\n'
            'When the timer rings, close the journal without immediately analysing — just breathe',
        benefitsRaw:
            'Expressive writing for 15–20 minutes over 4 days has been shown to improve immune function\n'
            'Naming emotions (affect labelling) reduces activity in the amygdala — the brain\'s alarm centre\n'
            'Helps untangle complex or conflicting feelings by externalising them\n'
            'Reveals patterns in your emotional life over weeks of practice\n'
            'Creates a private, safe space to process difficult experiences without judgment\n'
            'Regular journallers report lower levels of anxiety, anger and physical symptoms of stress',
      ),
      ActivityIdea(
        title: 'Do 20 Squats',
        description:
            'Stand up and do 20 body-weight squats to strengthen your legs and get blood flowing.',
        emoji: '🏋️',
        category: 'Fitness',
        durationMinutes: 3,
        stepsRaw:
            'Stand with feet shoulder-width apart, toes turned out slightly (10–30 degrees)\n'
            'Hold your arms straight out in front or cross them at your chest for balance\n'
            'Inhale and push your hips back and down as if sitting into a chair behind you\n'
            'Lower until your thighs are at least parallel to the floor — or as low as is comfortable\n'
            'Keep your chest up and your knees tracking over your toes — do not let them cave inward\n'
            'Exhale and push through your heels to stand back up — squeeze your glutes at the top\n'
            'Pause fully upright before starting the next rep\n'
            'Complete 20 reps — rest 60 seconds and do a second set if possible',
        benefitsRaw:
            'Engages the largest muscle groups in the body — quads, glutes, hamstrings — maximising calorie burn\n'
            'Counteracts the hip tightness and posterior chain weakness caused by prolonged sitting\n'
            'Triggers growth hormone release, supporting muscle maintenance and fat metabolism\n'
            'Improves mobility and functional strength for everyday movement\n'
            'Squatting regularly has been linked to reduced lower-back pain\n'
            'The brief intense effort produces an immediate mood lift through endorphin release',
      ),
      ActivityIdea(
        title: 'Recall Three Wins',
        description:
            'Think of three things you did well today, however small. Builds confidence and self-awareness.',
        emoji: '🌟',
        category: 'Mindfulness',
        durationMinutes: 5,
        stepsRaw:
            'Sit quietly and take 3 slow breaths to shift out of autopilot\n'
            'Ask yourself: "What went well today?" — give yourself 60 seconds to scan the day\n'
            'Pick 3 moments, however small: "I stuck to my morning routine", "I was patient in a difficult conversation", "I drank 8 glasses of water"\n'
            'For each win, write or say it aloud: "I did [X] and it mattered because [Y]"\n'
            'Let yourself genuinely feel good about each one — do not rush past the feeling\n'
            'If you struggle to find 3, lower the bar — completing this exercise is itself a win\n'
            'Optionally: close your eyes and mentally replay the moment as if watching a short video',
        benefitsRaw:
            'Trains the brain to actively notice positive events, gradually overriding the negativity bias\n'
            'Builds genuine self-confidence grounded in evidence, not affirmations\n'
            'Strengthens self-awareness — you cannot improve what you do not notice\n'
            'Provides emotional momentum that makes starting tomorrow\'s challenges easier\n'
            'Develops the identity of someone who takes action and follows through\n'
            'Consistently used by elite athletes and high performers as part of their daily review practice',
      ),
    ];
  }

  // ── Close ────────────────────────────────────────────────────────────────────

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
