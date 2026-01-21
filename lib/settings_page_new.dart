
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/main.dart';
import 'package:myapp/notifications.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPageNew extends StatefulWidget {
  const SettingsPageNew({super.key});

  @override
  State<SettingsPageNew> createState() => _SettingsPageNewState();
}

class _SettingsPageNewState extends State<SettingsPageNew> {
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notificationsEnabled = false;
  double _attendanceGoal = 60.0;
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPackageInfo();
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
    _attendanceGoal = prefs.getDouble('attendanceGoal') ?? 60.0;
    final notificationsEnabled = await NotificationService.instance.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
    });
  }

  void _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _buildNumber = packageInfo.buildNumber;
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
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SettingsHeader(title: 'GOAL'),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: isDarkMode ? Colors.greenAccent : const Color(0xFF10b981)),
                          const SizedBox(width: 8),
                          const Text('Office Attendance Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${_attendanceGoal.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.greenAccent : const Color(0xFF10b981))),
                        ],
                      ),
                      Slider(
                        value: _attendanceGoal,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: isDarkMode ? Colors.greenAccent : const Color(0xFF10b981),
                        inactiveColor: Colors.grey.shade300,
                        onChanged: (value) {
                          setState(() {
                            _attendanceGoal = value;
                          });
                        },
                        onChangeEnd: (value) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setDouble('attendanceGoal', value);
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0%', style: TextStyle(color: Colors.grey)),
                          Text('100%', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
            const _SettingsHeader(title: 'DATA'),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.upload_file,
                  iconColor: Colors.green,
                  title: 'Export to CSV',
                  onTap: () async {
                    final workLog = Provider.of<WorkLog>(context, listen: false);
                    String csv = 'Date,Status\n';
                    workLog.log.forEach((date, status) {
                      csv += '${date.toIso8601String().substring(0, 10)},${status.name}\n';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV content printed to debug console.')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.delete_forever,
                  iconColor: Colors.red,
                  title: 'Clear Work Log',
                  onTap: _showClearLogDialog,
                ),
              ],
            ),
            const _SettingsHeader(title: 'PREFERENCES'),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: Colors.purple,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                    activeThumbColor: Colors.purple,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.vibration,
                  iconColor: Colors.orange,
                  title: 'Haptic Feedback',
                  trailing: Switch(
                    value: themeProvider.hapticFeedbackEnabled,
                    onChanged: (value) {
                      themeProvider.setHapticFeedback(value);
                    },
                    activeThumbColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const _SettingsHeader(title: 'NOTIFICATIONS'),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_active_outlined,
                  iconColor: Colors.deepPurple,
                  title: 'Daily Reminders',
                  trailing: Switch(
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
                     activeThumbColor: Colors.deepPurple,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.access_time,
                  iconColor: Colors.blue,
                  title: 'Notification Time',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_notificationTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 16),
                    ],
                  ),
                  onTap: () => _selectNotificationTime(context),
                ),
                _SettingsTile(
                  icon: Icons.send,
                  iconColor: Colors.teal,
                  title: 'Test Notification',
                  onTap: () {
                    NotificationService.instance.showTestNotification();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(child: Text('BUILD 1.0.$_buildNumber', style: const TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? const Color(0xFF161B22) : Colors.white,
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
    );
  }
}
