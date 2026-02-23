import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize Timezones
    tz.initializeTimeZones();
    
    // Set default location (approximation or use 'local')
    // For simplicity, we can try to get local, or set UTC. 
    // In many Flutter apps without specific location permission, it's safer to rely on 'local' if supported,
    // or just initialization. 'timezone' package usually needs data.
    // 'tz.initializeTimeZones()' loads the database.
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'focus_channel',
      'Focus Notifications',
      channelDescription: 'Notifications for focus reminders and wellness',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleTaskReminder(int id, String title, DateTime deadline) async {
      // Schedule for 30 minutes before deadline
      final scheduledDate = deadline.subtract(const Duration(minutes: 30));
      
      // If the scheduled time is in the past (e.g. deadline is in 10 mins),
      // we could show immediately or skip. Let's skip if it's already passed.
      if (scheduledDate.isBefore(DateTime.now())) return;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_plan_channel',
      'Daily Plan Reminders',
      channelDescription: 'Reminders for your daily priorities',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Upcoming Deadline ⏰',
        '"$title" is due in 30 minutes!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    );
  }

  Future<void> scheduleHourlyWaterReminder() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'water_channel',
      'Water Reminders',
      channelDescription: 'Hourly reminders to drink water',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      'Hydration Check 💧',
      'Have you drunk enough water?',
      RepeatInterval.hourly,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleFocusReset() async {
     const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'focus_reset_channel',
      'Focus Reset',
      channelDescription: 'Reminders to take a break and reset focus',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.periodicallyShow(
      2,
      'Focus Reset 🧘',
      'Time for a focus reset? Take a deep breath.',
      RepeatInterval.hourly,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
