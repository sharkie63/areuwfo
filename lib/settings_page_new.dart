import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/main.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myapp/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';


class SettingsPageNew extends StatefulWidget {
  const SettingsPageNew({super.key});

  @override
  State<SettingsPageNew> createState() => _SettingsPageNewState();
}

class _SettingsPageNewState extends State<SettingsPageNew> with AutomaticKeepAliveClientMixin {
  String _version = '';
  String _buildNumber = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }



  void _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
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

  Future<void> _exportToCsv() async {
    // Show confirmation dialog for Ad
    final shouldWatchAd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Watch a short ad to support the app and export your data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Watch Ad & Export'),
          ),
        ],
      ),
    );

    if (shouldWatchAd == true) {
      await AdService().showRewardedAd(onRewardEarned: () async {
        await _performExport();
      });
    }
  }

  Future<void> _performExport() async {
    final workLog = Provider.of<WorkLog>(context, listen: false);
    String csv = 'Date,Status\n';
    workLog.log.forEach((date, status) {
      csv += '${date.toIso8601String().substring(0, 10)},${status.name}\n';
    });

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/work_log.csv';
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Work Log CSV');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 24.0, bottom: 16.0),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
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
                          Text('${(themeProvider.attendanceGoal * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.greenAccent : const Color(0xFF10b981))),
                        ],
                      ),
                      Slider(
                        value: themeProvider.attendanceGoal,
                        min: 0,
                        max: 1,
                        divisions: 100,
                        activeColor: isDarkMode ? Colors.greenAccent : const Color(0xFF10b981),
                        inactiveColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        onChanged: (value) {
                          themeProvider.setAttendanceGoal(value);
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
                  icon: Icons.ios_share,
                  iconColor: Colors.blue,
                  title: 'Export to CSV',
                  onTap: _exportToCsv,
                ),
                _SettingsTile(
                  icon: Icons.delete_outline,
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
                    activeColor: Colors.white,
                    activeTrackColor: Colors.purple,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
            const _SettingsHeader(title: 'ABOUT'),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.indigo,
                  title: 'Privacy Policy',
                  onTap: () async {
                    final url = Uri.parse('https://areuwfo-tracker.web.app/privacy.html');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch privacy policy.')),
                      );
                    }
                  },

                ),
                _SettingsTile(
                  icon: Icons.email_outlined,
                  iconColor: Colors.teal,
                  title: 'Contact Support',
                  onTap: () {
                    // Platform-specific email
                    final email = Theme.of(context).platform == TargetPlatform.iOS
                        ? 'studio.boredapps@icloud.com'
                        : 'studio.boredapps@gmail.com';
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Contact Support'),
                        content: Text(
                          'For support or feedback:\n\n'
                          'Email: $email',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_version.isNotEmpty)
              Center(
                child: Text(
                  'Version $_version+$_buildNumber',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
      const BannerAdWidget(),
      ],
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
        side: isDarkMode ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
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
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = enabled ? iconColor : Colors.grey;
    final Color? effectiveTitleColor = enabled ? null : Colors.grey;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: effectiveIconColor),
      ),
      title: Text(title, style: TextStyle(color: effectiveTitleColor)),
      trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios, size: 16, color: effectiveTitleColor) : null),
      onTap: enabled && onTap != null ? () {
        HapticFeedback.mediumImpact();
        onTap!();
      } : null,
      enabled: enabled,
    );
  }
}
