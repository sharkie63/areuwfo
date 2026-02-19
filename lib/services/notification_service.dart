import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const int _notificationId = 888;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // Android init — positional defaultIcon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS init — don't request permission on init; we do it explicitly later
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NotificationService] Tapped: ${response.payload}');
      },
    );

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// Request notification permissions. Returns true if granted.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted =
          await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// Schedule a daily notification at 10:00 AM local time.
  /// Uses inexact scheduling to avoid SCHEDULE_EXACT_ALARM permission
  /// (Play Store safe). The notification will fire around 10 AM.
  Future<void> scheduleDailyTenAMNotification() async {
    const String channelId = 'daily_reminder_channel';
    const String channelName = 'Daily Reminder';
    const String channelDescription =
        'Reminds you to log your attendance daily.';

    await _plugin.zonedSchedule(
      _notificationId,
      'Are you WFO today?',
      'Don\'t forget to log your attendance!',
      _nextInstanceOfTenAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
    debugPrint('[NotificationService] Scheduled daily at 10:00 AM');
  }

  /// Cancel the daily reminder notification.
  Future<void> cancelDailyNotification() async {
    await _plugin.cancel(_notificationId);
    debugPrint('[NotificationService] Daily notification cancelled');
  }

  /// Calculates the next occurrence of 10:00 AM in the local timezone.
  tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
