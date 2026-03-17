import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/screens/splash_screen.dart';

import 'package:provider/provider.dart';
import 'package:focus_app/providers/calendar_provider.dart';
import 'package:focus_app/providers/analytics_provider.dart';
import 'package:focus_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  
  // Schedule recurring notifications
  await notificationService.scheduleHydrationReminders();
  await notificationService.scheduleFocusReset();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: const FocusApp(),
    ),
  );
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

