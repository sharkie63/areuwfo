import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init(
      {Function(NotificationResponse)?
          onDidReceiveBackgroundNotificationResponse}) async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }

  Future<bool> requestPermissions() async {
    bool? result;
    if (Platform.isIOS) {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? notificationPermission = await androidPlugin?.requestNotificationsPermission();
      final bool? exactAlarmPermission = await androidPlugin?.requestExactAlarmsPermission();
      result = (notificationPermission ?? false) && (exactAlarmPermission ?? false);
    }
    return result ?? false;
  }

  Future<bool> isNotificationAllowed() async {
    bool? isAllowed;
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      isAllowed = await androidPlugin?.areNotificationsEnabled();
    } else if (Platform.isIOS) {
      // On iOS, we can't check without asking.
      // We will assume true and let the request flow in the settings page handle denial.
      return true;
    }
    return isAllowed ?? false;
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Log Your Work Status',
      'Don\'t forget to update your work status for today. A quick tap is all it takes!',
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminders to log your work status.',
          actions: [
            AndroidNotificationAction('office', 'Office'),
            AndroidNotificationAction('home', 'Home'),
            AndroidNotificationAction('leave', 'Leave'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Removed uiLocalNotificationDateInterpretation as it's no longer a direct parameter or its usage has changed
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'Work_log_notification',
    );
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('office', 'Office'),
        AndroidNotificationAction('home', 'Home'),
        AndroidNotificationAction('leave', 'Leave'),
      ],
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      1,
      'Log Your Work Status',
      'Don\'t forget to update your work status for today. A quick tap is all it takes!',
      platformChannelSpecifics,
      payload: 'Test_notification',
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}