import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensures native components are fully wired up before calling services
  WidgetsFlutterBinding.ensureInitialized();

  // Fire up the notification configuration
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme mode (Dark or Light)
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Hydration Tracker',
      debugShowCheckedModeBanner: false,

      // Define explicit light and dark themes
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black, // Sleek true-black background option
      ),
      home: const HomeScreen(),
    );
  }
}