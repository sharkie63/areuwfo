import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticFeedbackEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;

  ThemeProvider() {
    _loadThemeMode();
    _loadHapticFeedback();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  void _loadHapticFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticFeedbackEnabled = prefs.getBool('hapticFeedback') ?? true;
    notifyListeners();
  }

  void setHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticFeedback', enabled);
    notifyListeners();
  }
}
