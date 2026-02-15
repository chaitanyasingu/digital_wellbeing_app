import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'screens/home_screen.dart';
import 'services/background_job_service.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Wellbeing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
