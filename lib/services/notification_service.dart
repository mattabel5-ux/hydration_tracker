import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize the notification settings
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );

    // Request permission explicitly for modern Android devices
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Clear all active alerts
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Schedule a smart nudge notification at the top of the hour (minimum 1-hour buffer)
  static Future<void> scheduleNudge(String message) async {
    // Clear any previously scheduled nudge so they don't stack up infinitely
    await cancelAllNotifications();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_reminders',
      'Hydration Reminders',
      channelDescription: 'Smart alerts to keep you tracking towards your goal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final now = tz.TZDateTime.now(tz.local);

    // Calculate the absolute next top-of-the-hour
    var nextHour = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour + 1,
      0,
    );

    // Ensure a full hour has passed. If the next hour is less than 60 minutes away,
    // we push it by one more hour.
    if (nextHour.difference(now).inMinutes < 60) {
      nextHour = nextHour.add(const Duration(hours: 1));
    }

    // Schedule the notification to hit exactly at the calculated top-of-the-hour
    await _notificationsPlugin.zonedSchedule(
      0,
      'Hydration Check! 💧',
      message,
      nextHour,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}