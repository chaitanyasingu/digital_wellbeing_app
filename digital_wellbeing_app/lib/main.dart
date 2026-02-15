import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'screens/home_screen.dart';
import 'services/background_job_service.dart';
import 'services/tamper_detection_service.dart';
import 'providers/tamper_detection_provider.dart';

void main() async {
  // Initialize Flutter binding - required for plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background job service with error handling
  // Never let background service errors crash the app
  try {
    await BackgroundJobService.initialize();
    await BackgroundJobService.scheduleDailySync();
  } catch (e, stackTrace) {
    developer.log(
      'Background service initialization failed (app continues)',
      name: 'MainApp',
      error: e,
      stackTrace: stackTrace,
    );
    // App continues normally even if background service fails
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final _tamperService = TamperDetectionService();
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
      print('[Lifecycle] App went to background');
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      print('[Lifecycle] App resumed from background');

      // Track potential force-close if app was killed and restarted
      _checkForForceClose();
    }
  }

  Future<void> _checkForForceClose() async {
    try {
      final isSuspicious = await _tamperService.trackForceClose();
      if (isSuspicious) {
        print('[Lifecycle] ⚠️ Suspicious force-close pattern detected');
        // Refresh tamper detection state
        ref.read(tamperDetectionProvider.notifier).refresh();
      }
    } catch (e) {
      print('[Lifecycle] Error tracking force-close: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Mindfulness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4FA0),
          primary: const Color(0xFF6B4FA0),
          secondary: const Color(0xFF8B75B8),
          surface: const Color(0xFFF5F3F7),
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B4FA0),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
