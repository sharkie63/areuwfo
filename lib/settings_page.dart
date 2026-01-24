
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/main.dart';
import 'package:myapp/notifications.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('notificationTime');
    if (timeString != null) {
      final timeParts = timeString.split(':');
      _notificationTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    final notificationsEnabled = await NotificationService.instance.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
    });
  }

  Future<void> _selectNotificationTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked == null || picked == _notificationTime) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationTime', '${picked.hour}:${picked.minute}');

    if (!mounted) return;

    setState(() {
      _notificationTime = picked;
    });
    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(_notificationTime);
    }
  }

  void _showClearLogDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Work Log?'),
          content: const Text(
              'Are you sure you want to delete all your work log data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                Provider.of<WorkLog>(context, listen: false).clearLog();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Export to CSV'),
            leading: const Icon(Icons.share),
            onTap: () async {
              final workLog = Provider.of<WorkLog>(context, listen: false);
              String csv = 'Date,Status\n';
              workLog.log.forEach((date, status) {
                csv += '${date.toIso8601String().substring(0, 10)},${status.name}\n';
              });

              debugPrint("--- CSV EXPORT ---");
              debugPrint(csv);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV content printed to debug console.')),
              );
            },
          ),
          ListTile(
            title: const Text('Clear Work Log'),
            leading: const Icon(Icons.delete_forever),
            onTap: _showClearLogDialog,
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            value: themeProvider.hapticFeedbackEnabled,
            onChanged: (value) {
              themeProvider.setHapticFeedback(value);
            },
            secondary: const Icon(Icons.vibration),
          ),
          SwitchListTile(
            title: const Text('Enable Daily Reminders'),
            value: _notificationsEnabled,
            onChanged: (bool value) async {
              if (value) {
                bool standardGranted = await NotificationService.instance.requestStandardPermissions();
                if (!mounted) return;
                if (standardGranted) {
                  bool exactAlarmGranted = await NotificationService.instance.requestExactAlarmPermission();
                  if (!mounted) return;
                  if (exactAlarmGranted) {
                    await NotificationService.instance.scheduleDailyReminder(_notificationTime);
                    if (!mounted) return;
                    setState(() {
                      _notificationsEnabled = true;
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Notification permissions are required for reminders.')),
                  );
                }
              } else {
                await NotificationService.instance.cancelAllNotifications();
                if (!mounted) return;
                setState(() {
                  _notificationsEnabled = false;
                });
              }
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(_notificationTime.format(context)),
            leading: const Icon(Icons.notifications),
            onTap: () => _selectNotificationTime(context),
            enabled: _notificationsEnabled,
          ),
          ListTile(
            title: const Text('Test Notification'),
            subtitle: const Text('Send a notification immediately'),
            leading: const Icon(Icons.notification_important),
            onTap: () {
              NotificationService.instance.showTestNotification();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Office attendance must be at least 60% to meet your goal.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
