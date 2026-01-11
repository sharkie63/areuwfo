
import 'package:flutter/material.dart';
import 'package:myapp/loading_page.dart';
import 'package:myapp/main.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myapp/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  void _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('remindersEnabled') ?? false;
      final reminderHour = prefs.getInt('reminderHour') ?? 17;
      final reminderMinute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
    });
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', _remindersEnabled);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }

  void _onRemindersChanged(bool value) {
    setState(() {
      _remindersEnabled = value;
    });
    if (value) {
      NotificationService().requestPermissions();
      NotificationService().scheduleDailyReminder(_reminderTime);
    } else {
      NotificationService().cancelAllNotifications();
    }
    _saveReminderSettings();
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      if (_remindersEnabled) {
        NotificationService().scheduleDailyReminder(_reminderTime);
      }
      _saveReminderSettings();
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final workLog = Provider.of<WorkLog>(context, listen: false);
    final List<List<dynamic>> rows = [];
    rows.add(['Date', 'Status']);
    workLog.log.forEach((date, status) {
      rows.add([date.toIso8601String(), status.toString().split('.').last]);
    });

    final String csv = const ListToCsvConverter().convert(rows);
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/work_log.csv';
    final File file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Work Log Data');
  }

  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Data?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to reset all your work log data?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () {
                _resetData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetData() {
    final workLog = Provider.of<WorkLog>(context, listen: false);
    workLog.clearLog();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoadingPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const Divider(),
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Daily Reminders'),
              subtitle: const Text('Remind you to log your work.'),
              value: _remindersEnabled,
              onChanged: _onRemindersChanged,
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(_reminderTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _selectReminderTime(context),
              enabled: _remindersEnabled,
            ),
            const Divider(),
            Text(
              'Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Export your work log as a CSV file.'),
              trailing: const Icon(Icons.download),
              onTap: () => _exportData(context),
            ),
            ListTile(
              title: const Text('Reset Data'),
              subtitle: const Text('Deletes all your work log data.'),
              trailing: const Icon(Icons.delete_forever),
              onTap: _showResetConfirmationDialog,
            ),
            const Divider(),
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Enable subtle vibrations on tap.'),
                  value: themeProvider.hapticFeedbackEnabled,
                  onChanged: (bool value) {
                    themeProvider.setHapticFeedback(value);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
