import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticFeedbackEnabled = true;
  double _attendanceGoal = 0.75;

  ThemeMode get themeMode => _themeMode;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  double get attendanceGoal => _attendanceGoal;

  ThemeProvider() {
    _loadThemeMode();
    _loadHapticFeedback();
    _loadAttendanceGoal();
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

  void _loadAttendanceGoal() async {
    final prefs = await SharedPreferences.getInstance();
    double goal = prefs.getDouble('attendanceGoal') ?? 0.75;

    // Data migration: If the goal is stored as a percentage (e.g., 60.0), convert it to a decimal (0.60).
    if (goal > 1.0) {
      goal = goal / 100.0;
      // Save the corrected value back to preferences.
      await prefs.setDouble('attendanceGoal', goal);
    }

    _attendanceGoal = goal;
    notifyListeners();
  }

  void setAttendanceGoal(double goal) async {
    _attendanceGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('attendanceGoal', goal);
    notifyListeners();
  }
}
