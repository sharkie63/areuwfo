import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/loading_page.dart';
import 'package:myapp/settings_page.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// Main function
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkLog().._loadLog()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const WorkTrackerApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePageWrapper()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

// Work Status Enum
enum WorkStatus { none, office, home, leave }

// WorkLog Provider
class WorkLog with ChangeNotifier {
  final Map<DateTime, WorkStatus> _log = {};
  bool _isLoading = true;

  Map<DateTime, WorkStatus> get log => _log;
  bool get isLoading => _isLoading;

  void updateStatus(DateTime day, WorkStatus status) {
    _log[day] = status;
    _saveLog();
    notifyListeners();
  }

  WorkStatus getStatus(DateTime day) {
    return _log[day] ?? WorkStatus.none;
  }

  Future<void> _saveLog() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> encodedLog = _log.map(
      (key, value) => MapEntry(key.toIso8601String(), value.index),
    );
    await prefs.setString('workLog', json.encode(encodedLog));
  }

  Future<void> _loadLog() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final String? logString = prefs.getString('workLog');
    if (logString != null) {
      final Map<String, dynamic> decodedLog = json.decode(logString);
      _log.clear();
      decodedLog.forEach((key, value) {
        _log[DateTime.parse(key)] = WorkStatus.values[value];
      });
    } else {
      // Generate dummy data if no log exists
      _generateDummyData();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _generateDummyData() {
    final random = Random();
    final today = DateUtils.dateOnly(DateTime.now());

    for (int monthIndex = 0; monthIndex <= 6; monthIndex++) {
      final month = DateTime(today.year, today.month - monthIndex, 1);
      final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

      for (int dayIndex = 1; dayIndex <= daysInMonth; dayIndex++) {
        final day = DateTime(month.year, month.month, dayIndex);

        // Skip future dates and weekends
        if (day.isAfter(today) ||
            day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          continue;
        }

        // Generate a random status (excluding 'none')
        final status = WorkStatus.values[random.nextInt(3) + 1];
        _log[day] = status;
      }
    }
    _saveLog();
  }

  // Calculate the in-office attendance percentage for a given month
  double officeAttendancePercentage(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    int officeDays = 0;
    int leaveDays = 0;
    int totalWeekdays = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(month.year, month.month, i);
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
        totalWeekdays++;
        final status = getStatus(day);
        if (status == WorkStatus.office) {
          officeDays++;
        } else if (status == WorkStatus.leave) {
          leaveDays++;
        }
      }
    }

    final totalWorkingDays = totalWeekdays - leaveDays;
    return totalWorkingDays > 0 ? (officeDays / totalWorkingDays) * 100 : 0;
  }
}

// Main App Widget
class WorkTrackerApp extends StatelessWidget {
  const WorkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.deepPurple;
    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Work Tracker',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

class HomePageWrapper extends StatelessWidget {
  const HomePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkLog>(
      builder: (context, workLog, child) {
        return workLog.isLoading ? const LoadingPage() : const MyHomePage();
      },
    );
  }
}

// Home Page Widget
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateUtils.dateOnly(DateTime.now());
  }

  void _changeMonth(int monthIncrement) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + monthIncrement,
        1,
      );
    });
  }

  void _setMonth(DateTime month) {
    setState(() {
      _displayedMonth = month;
    });
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Color Legend'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendItem(status: WorkStatus.office),
              SizedBox(height: 8),
              LegendItem(status: WorkStatus.home),
              SizedBox(height: 8),
              LegendItem(status: WorkStatus.leave),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate navigation limits
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
    final sixMonthsHence = DateTime(now.year, now.month + 6, 1);
    final canGoBack = _displayedMonth.isAfter(sixMonthsAgo);
    final canGoForward = _displayedMonth.isBefore(sixMonthsHence);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: canGoBack ? () => _changeMonth(-1) : null,
            ),
            Text(
              DateFormat.yMMMM().format(_displayedMonth),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: canGoForward ? () => _changeMonth(1) : null,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLegendDialog,
            tooltip: 'Show Legend',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CalendarGrid(displayedMonth: _displayedMonth),
            const SizedBox(height: 24),
            AttendanceTracker(displayedMonth: _displayedMonth),
            const SizedBox(height: 16),
            MonthlyAttendanceIndicator(onMonthSelected: _setMonth),
          ],
        ),
      ),
    );
  }
}

// Calendar Grid Widget
class CalendarGrid extends StatelessWidget {
  final DateTime displayedMonth;
  const CalendarGrid({super.key, required this.displayedMonth});

  @override
  Widget build(BuildContext context) {
    final workLog = Provider.of<WorkLog>(context);
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      displayedMonth.year,
      displayedMonth.month,
    );
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        const WeekdayHeader(),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: daysInMonth + firstWeekday - 1,
          itemBuilder: (context, index) {
            if (index < firstWeekday - 1) {
              return const SizedBox.shrink(); // Empty space before the 1st day
            }
            final dayNumber = index - (firstWeekday - 1) + 1;
            final date = DateTime(
              displayedMonth.year,
              displayedMonth.month,
              dayNumber,
            );
            final status = workLog.getStatus(date);
            final isWeekend =
                date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday;

            return DayCard(
              date: date,
              status: status,
              isWeekend: isWeekend,
              onTap: () {
                if (!isWeekend) {
                  final nextStatus = WorkStatus
                      .values[(status.index + 1) % WorkStatus.values.length];
                  workLog.updateStatus(date, nextStatus);
                }
              },
            );
          },
        ),
      ],
    );
  }
}

// Weekday Header Widget
class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final shortWeekdays = DateFormat.E().dateSymbols.SHORTWEEKDAYS;
    // Reorder to start with Monday
    final orderedWeekdays = [...shortWeekdays.sublist(1), shortWeekdays[0]];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: orderedWeekdays.map((day) {
        return Text(day, style: const TextStyle(fontWeight: FontWeight.bold));
      }).toList(),
    );
  }
}

// Day Card Widget
class DayCard extends StatelessWidget {
  final DateTime date;
  final WorkStatus status;
  final bool isWeekend;
  final VoidCallback? onTap;

  const DayCard({
    super.key,
    required this.date,
    required this.status,
    required this.isWeekend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? cardColor;
    if (!isWeekend) {
      switch (status) {
        case WorkStatus.office:
          cardColor = Colors.green.shade400;
          break;
        case WorkStatus.home:
          cardColor = Colors.red.shade400;
          break;
        case WorkStatus.leave:
          cardColor = Colors.yellow.shade600;
          break;
        case WorkStatus.none:
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWeekend ? Colors.grey.shade400 : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status != WorkStatus.none ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}

// Attendance Tracker Widget
class AttendanceTracker extends StatelessWidget {
  final DateTime displayedMonth;
  const AttendanceTracker({super.key, required this.displayedMonth});

  @override
  Widget build(BuildContext context) {
    final workLog = Provider.of<WorkLog>(context);
    final percentage = workLog.officeAttendancePercentage(displayedMonth);
    final progressColor = percentage < 60 ? Colors.red : Colors.green;

    return Column(
      children: [
        Text(
          'In-Office Attendance: ${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      ],
    );
  }
}

// Monthly Attendance Indicator Widget
class MonthlyAttendanceIndicator extends StatelessWidget {
  final Function(DateTime) onMonthSelected;
  const MonthlyAttendanceIndicator({super.key, required this.onMonthSelected});

  @override
  Widget build(BuildContext context) {
    final workLog = Provider.of<WorkLog>(context);
    final today = DateUtils.dateOnly(DateTime.now());

    // Generate the list of the previous 6 months and reverse it for chronological order
    final pastMonths = List.generate(6, (index) {
      return DateTime(today.year, today.month - (index + 1), 1);
    }).reversed.toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: pastMonths.map((month) {
            final percentage = workLog.officeAttendancePercentage(month);
            final color = percentage < 60 ? Colors.red : Colors.green;
            return _buildIndicator(month, color, false);
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildIndicator(
          today,
          workLog.officeAttendancePercentage(today) < 60
              ? Colors.red
              : Colors.green,
          true,
        ),
      ],
    );
  }

  Widget _buildIndicator(DateTime month, Color color, bool isCurrent) {
    return GestureDetector(
      onTap: () => onMonthSelected(month),
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat.MMM().format(month),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if (isCurrent)
            const Text('(Current Month)', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

// Legend Item Widget
class LegendItem extends StatelessWidget {
  final WorkStatus status;
  const LegendItem({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case WorkStatus.office:
        color = Colors.green.shade400;
        text = 'Office';
        break;
      case WorkStatus.home:
        color = Colors.red.shade400;
        text = 'Home';
        break;
      case WorkStatus.leave:
        color = Colors.yellow.shade600;
        text = 'Leave';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
