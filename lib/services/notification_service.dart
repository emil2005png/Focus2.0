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
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // Also request exact alarm permission if needed for zonedSchedule
      await androidImplementation.requestExactAlarmsPermission();
    }
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

  Future<void> scheduleHydrationReminders() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'water_channel',
      'Water Reminders',
      channelDescription: 'Hydration reminders every 2 hours',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final hours = [8, 10, 12, 14, 16, 18, 20, 22];
    for (int i = 0; i < hours.length; i++) {
       final now = tz.TZDateTime.now(tz.local);
       var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hours[i]);
       
       if (scheduledDate.isBefore(now)) {
         scheduledDate = scheduledDate.add(const Duration(days: 1));
       }

       await flutterLocalNotificationsPlugin.zonedSchedule(
         100 + i, // Unique IDs for each time slot
         'Hydration Check 💧',
         'Stay refreshed! Time for some water.',
         scheduledDate,
         platformChannelSpecifics,
         androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
         matchDateTimeComponents: DateTimeComponents.time,
       );
    }
  }

  Future<void> cancelHydrationReminders() async {
    for (int i = 0; i < 8; i++) {
      await flutterLocalNotificationsPlugin.cancel(100 + i);
    }
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
