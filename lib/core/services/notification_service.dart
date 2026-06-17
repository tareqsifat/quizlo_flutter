import 'package:flutter/material.dart';

class NotificationService {
  // All notification logic has been commented out per user request.
  
  static Future<void> init() async {
    debugPrint('NotificationService: init bypassed (disabled)');
  }

  static Future<void> requestPermissions() async {
    debugPrint('NotificationService: requestPermissions bypassed (disabled)');
  }

  static Future<void> scheduleDailyReminders() async {
    debugPrint('NotificationService: scheduleDailyReminders bypassed (disabled)');
  }
}

/*
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize timezones, request permissions, set up click callbacks, and schedule reminders.
  static Future<void> init() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback if local timezone detection fails
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }

    // 2. Initialize settings (use app icon for status bar)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 3. Initialize plugin and set on-click callback
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    // 4. Request permissions on Android 13+
    await requestPermissions();

    // 5. Schedule/Reschedule the daily reminders
    await scheduleDailyReminders();

    // 6. Check if the app was launched by clicking a notification
    _checkAndNavigateOnLaunch();
  }

  /// Request runtime permissions on Android
  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  /// Schedule the three daily reminder notifications
  static Future<void> scheduleDailyReminders() async {
    // Check exact alarm permission first (Android 12+)
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      final bool? granted = 
          await androidImpl.requestExactAlarmsPermission();
      if (granted == false) {
        debugPrint('Exact alarm permission denied — skipping schedule');
        return; // Don't hang, just skip
      }
    }

    // Cancel existing scheduled notifications to avoid duplicates
    await _notificationsPlugin.cancelAll();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminders_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminders to practice quizzes on Quizlo',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // 7:30 AM Notification
    await _scheduleDailyNotification(
      id: 1,
      title: 'Quizlo',
      body: 'Practice to get ahead of everyone else',
      hour: 7,
      minute: 30,
      notificationDetails: platformChannelSpecifics,
    );

    // 10:00 AM Notification
    await _scheduleDailyNotification(
      id: 2,
      title: 'Quizlo',
      body: 'Practice to get ahead of everyone else',
      hour: 10,
      minute: 0,
      notificationDetails: platformChannelSpecifics,
    );

    // 6:00 PM Notification
    await _scheduleDailyNotification(
      id: 3,
      title: 'Quizlo',
      body: 'Practice to get ahead of everyone else',
      hour: 18,
      minute: 0,
      notificationDetails: platformChannelSpecifics,
    );
  }

  /// Helper to schedule a single daily recurring notification
  static Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails notificationDetails,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
      Fluttertoast.showToast(
        msg: 'Failed to schedule notification $id: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  /// Helper to calculate the next occurrence of a specific time in the local timezone
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Navigate to the 10-question demo quiz loading screen when a notification is clicked
  static void _handleNotificationClick(String? payload) {
    if (rootNavigatorKey.currentContext != null) {
      GoRouter.of(rootNavigatorKey.currentContext!).push(
        AppRoutes.quizLoading,
        extra: {'lesson_id': 0, 'title': 'Demo Quiz'},
      );
    }
  }

  /// Poll for navigator context and route if app was launched via notification click
  static Future<void> _checkAndNavigateOnLaunch() async {
    final NotificationAppLaunchDetails? details =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      for (int i = 0; i < 30; i++) {
        if (rootNavigatorKey.currentContext != null) {
          GoRouter.of(rootNavigatorKey.currentContext!).push(
            AppRoutes.quizLoading,
            extra: {'lesson_id': 0, 'title': 'Demo Quiz'},
          );
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
*/
