import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          ],
        ),
      ),
    );
  }
}
