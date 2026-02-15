import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
// import 'services/background_job_service.dart';  // TODO: Fix workmanager compatibility

void main() async {
  // Initialize Flutter binding - required for plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background job service
  // TODO: Re-enable after fixing workmanager compatibility issue
  // await BackgroundJobService.initialize();
  // await BackgroundJobService.scheduleDailySync();

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
