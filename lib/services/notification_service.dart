import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // --- TEMPORARY INSTANT TEST ---
  static Future<void> triggerInstantTest() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'instant_test_channel',
      'Instant Test Channel',
      channelDescription: 'Testing if Android will draw a banner',
      importance: Importance.max, // Max forces a drop-down banner
      priority: Priority.max,
      icon: '@mipmap/ic_launcher', // Explicitly defining the icon here
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      888,
      'Test Successful! 🎉',
      'If you can read this, banners are working.',
      details,
    );
  }

  // Clear all active alerts
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // --- 1. The Pre-Setup 8:00 AM Reminder ---
  static Future<void> scheduleSetupReminder() async {
    await cancelAllNotifications();

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'setup_reminders_v2',
        'Setup Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher', // Safety fallback
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);

    // If it's already past 8 AM today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      999, // Special ID for the setup reminder
      'Good Morning! 💧',
      'Time to set up your hydration goals for today.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Makes it repeat daily at 8 AM
    );
  }

  // --- 2. The Automated Post-Setup Intervals ---
  static Future<void> scheduleAutomatedNudges({
    required String message,
    required int intervalMinutes,
    required int bedtimeEpoch,
    required String type,
  }) async {
    await cancelAllNotifications(); // Clear old math

    final bool isFullScreen = type == 'fullscreen';

    // We are routing the scheduled alerts through the proven test channel
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'instant_test_channel', // Hijacking the proven channel ID
      'Instant Test Channel',
      importance: Importance.max, // Upgraded to MAX
      priority: Priority.max,     // Upgraded to MAX
      fullScreenIntent: isFullScreen,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    final bedtime = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, bedtimeEpoch);

    // If the day is over, don't schedule anything
    if (now.isAfter(bedtime)) return;

    // Schedule up to 64 future alerts (iOS maximum limit for local notifications)
    // spaced out by the interval she selected.
    int notificationId = 0;
    tz.TZDateTime nextAlert = now.add(Duration(minutes: intervalMinutes));

    while (nextAlert.isBefore(bedtime) && notificationId < 64) {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Hydration Check! 💧',
        message,
        nextAlert,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      notificationId++;
      nextAlert = nextAlert.add(Duration(minutes: intervalMinutes));
    }
  }
}