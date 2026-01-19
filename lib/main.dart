
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/loading_page.dart';
import 'package:myapp/notifications.dart';
import 'package:myapp/settings_page.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService()
      .init(onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

  final workLog = WorkLog();

  runZonedGuarded(() async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: workLog),
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: const WorkTrackerApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  developer.log(
    'Notification tapped with action: ${notificationResponse.actionId}',
    name: 'com.example.myapp.background',
    level: 800
  );

  final actionId = notificationResponse.actionId;
  if (actionId != null) {
    WorkStatus? status;

    if (actionId == 'office') {
      status = WorkStatus.office;
    } else if (actionId == 'home') {
      status = WorkStatus.home;
    } else if (actionId == 'leave') {
      status = WorkStatus.leave;
    }

    if (status != null) {
      developer.log(
        'Status determined: $status. Calling update function.',
        name: 'com.example.myapp.background',
        level: 800
      );
      updateStatusInBackground(status);
    }
  }
}

// REFACTORED: This function is now public and uses the single source of truth.
Future<void> updateStatusInBackground(WorkStatus status) async {
  try {
    developer.log('Background update started for status: $status', name: 'com.example.myapp.background');
    
    // 1. Read the log using the new centralized class
    final workLog = await WorkLogStorage.readWorkLog();
    final today = DateUtils.dateOnly(DateTime.now());
    
    // 2. Update the value
    workLog[today] = status;
    
    // 3. Write the entire log back
    await WorkLogStorage.writeWorkLog(workLog);

    developer.log('Background update successful.', name: 'com.example.myapp.background');
  } catch (e, s) {
    developer.log('FATAL ERROR in updateStatusInBackground: $e', name: 'com.example.myapp.background', error: e, stackTrace: s, level: 1200);
  }
}


final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePageWrapper()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  observers: [WorkTrackerApp.observer],
);

enum WorkStatus { none, office, home, leave }


// ADDED: This new class centralizes all data access.
class WorkLogStorage {
  static const _workLogKey = 'workLog';

  // Reads the entire log from disk and decodes it.
  static Future<Map<DateTime, WorkStatus>> readWorkLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logString = prefs.getString(_workLogKey);
      if (logString == null) return {};

      final Map<String, dynamic> decodedLog = json.decode(logString);
      return decodedLog.map((key, value) {
        return MapEntry(DateTime.parse(key), WorkStatus.values[value as int]);
      });
    } catch (e) {
      developer.log('Error reading work log: $e', name: 'com.example.myapp.storage');
      return {}; // Return empty map on error to prevent crash
    }
  }

  // Encodes the entire log and writes it to disk.
  static Future<void> writeWorkLog(Map<DateTime, WorkStatus> log) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> encodedLog = log.map(
      (key, value) => MapEntry(key.toIso8601String(), value.index),
    );
    await prefs.setString(_workLogKey, json.encode(encodedLog));
  }
}


class WorkLog with ChangeNotifier {
  final Map<DateTime, WorkStatus> _log = {};

  Map<DateTime, WorkStatus> get log => _log;

  Future<void> updateStatus(DateTime day, WorkStatus status) async {
    _log[day] = status;
    await _saveLog();
    notifyListeners();
  }

  WorkStatus getStatus(DateTime day) {
    return _log[day] ?? WorkStatus.none;
  }

  Future<void> _saveLog() async {
    await WorkLogStorage.writeWorkLog(_log);
  }

  Future<void> loadLog() async {
    try {
      developer.log("WorkLog: Starting to load log from disk.", name: "com.example.myapp.worklog");
      _log.clear();
      _log.addAll(await WorkLogStorage.readWorkLog());
       developer.log("WorkLog: Successfully loaded and parsed log.", name: "com.example.myapp.worklog");
    } catch (e, stack) {
       developer.log(
        "WorkLog: Error loading log, clearing data.",
        name: "com.example.myapp.worklog",
        error: e,
        stackTrace: stack,
        level: 1000,
      );
      FirebaseCrashlytics.instance.recordError(e, stack);
      _log.clear();
      await _saveLog();
    } finally {
      developer.log("WorkLog: Notifying listeners of final state.", name: "com.example.myapp.worklog");
      notifyListeners();
    }
  }

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

  void clearLog() {
    _log.clear();
    _saveLog();
    notifyListeners();
  }
}

class WorkTrackerApp extends StatelessWidget {
  const WorkTrackerApp({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.deepPurple;
    const TextTheme appTextTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 14),
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
          title: 'AreUWFO',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  late Future<void> _loadLogFuture;

  @override
  void initState() {
    super.initState();
    _loadLogFuture = Provider.of<WorkLog>(context, listen: false).loadLog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadLogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Optionally, return an error-specific widget
            return const Scaffold(
              body: Center(
                child: Text('Failed to load data. Please restart the app.'),
              ),
            );
          }
          return const MyHomePage();
        } else {
          return const LoadingPage();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late DateTime _displayedMonth;
  late AnimationController _swipeHintController;
  late Animation<double> _swipeHintOpacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _displayedMonth = DateUtils.dateOnly(DateTime.now());

    _swipeHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _swipeHintOpacityAnimation = CurvedAnimation(
      parent: _swipeHintController,
      curve: Curves.easeInOut,
    );

    _triggerSwipeHint();
    _requestPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      developer.log(
        "[LIFECYCLE] App resumed, reloading work log.",
        name: "com.example.myapp.lifecycle"
      );
      Provider.of<WorkLog>(context, listen: false).loadLog();
    }
  }

  void _requestPermissions() async {
    final notificationService = NotificationService();
    final isAllowed = await notificationService.areNotificationsEnabled();
    if (!isAllowed) {
      await notificationService.requestStandardPermissions();
    }
  }

  @override
  void dispose() {
    _swipeHintController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _triggerSwipeHint() async {
    if (_swipeHintController.isAnimating) return;
    _swipeHintController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    _swipeHintController.reverse();
  }

  void _changeMonth(int monthIncrement) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + monthIncrement,
        1,
      );
    });
    _triggerSwipeHint();
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
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
    final sixMonthsHence = DateTime(now.year, now.month + 6, 1);
    final canGoBack = _displayedMonth.isAfter(sixMonthsAgo);
    final canGoForward = _displayedMonth.isBefore(sixMonthsHence);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          DateFormat.yMMMM().format(_displayedMonth),
          style: Theme.of(context).textTheme.titleLarge,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: CalendarGrid(
                    displayedMonth: _displayedMonth,
                    onMonthSwiped: _changeMonth,
                  ),
                ),
                const SizedBox(height: 24),
                AttendanceTracker(displayedMonth: _displayedMonth),
                const SizedBox(height: 16),
                MonthlyAttendanceIndicator(onMonthSelected: _setMonth),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.25,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: FadeTransition(
              opacity: _swipeHintOpacityAnimation,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 30),
                onPressed: canGoBack ? () => _changeMonth(-1) : null,
                color: Theme.of(context).colorScheme.onSurface,
                disabledColor: Theme.of(context).colorScheme.onSurface.withAlpha(77),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.25,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: FadeTransition(
              opacity: _swipeHintOpacityAnimation,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 30),
                onPressed: canGoForward ? () => _changeMonth(1) : null,
                color: Theme.of(context).colorScheme.onSurface,
                disabledColor: Theme.of(context).colorScheme.onSurface.withAlpha(77),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarGrid extends StatefulWidget {
  final DateTime displayedMonth;
  final Function(int) onMonthSwiped;

  const CalendarGrid({
    super.key,
    required this.displayedMonth,
    required this.onMonthSwiped,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayedMonth != oldWidget.displayedMonth) {
      final int monthDifference = widget.displayedMonth.month - oldWidget.displayedMonth.month +
          (widget.displayedMonth.year - oldWidget.displayedMonth.year) * 12;

      _animationController.reset();

      if (monthDifference > 0) {
        _offsetAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        );
      } else {
        _offsetAnimation = Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        );
      }
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workLog = Provider.of<WorkLog>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final firstDayOfMonth = DateTime(
      widget.displayedMonth.year,
      widget.displayedMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.displayedMonth.year,
      widget.displayedMonth.month,
    );
    final firstWeekday = firstDayOfMonth.weekday;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          widget.onMonthSwiped(-1);
        } else if (details.primaryVelocity! < 0) {
          widget.onMonthSwiped(1);
        }
      },
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _offsetAnimation.value * MediaQuery.of(context).size.width,
            child: child,
          );
        },
        child: Column(
          children: [
            const WeekdayHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
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
                    return const SizedBox.shrink();
                  }
                  final dayNumber = index - (firstWeekday - 1) + 1;
                  final date = DateTime(
                    widget.displayedMonth.year,
                    widget.displayedMonth.month,
                    dayNumber,
                  );
                  final status = workLog.getStatus(date);
                  final isWeekend =
                      date.weekday == DateTime.saturday ||
                      date.weekday == DateTime.sunday;
                  final isCurrentDay =
                      DateUtils.dateOnly(date) == DateUtils.dateOnly(DateTime.now());

                  return DayCard(
                    date: date,
                    status: status,
                    isWeekend: isWeekend,
                    isCurrentDay: isCurrentDay,
                    onTap: () async {
                      if (!isWeekend) {
                        if (themeProvider.hapticFeedbackEnabled) {
                          HapticFeedback.mediumImpact();
                        }
                        final nextStatus = WorkStatus
                            .values[(status.index + 1) % WorkStatus.values.length];
                        await workLog.updateStatus(date, nextStatus);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final shortWeekdays = DateFormat.E().dateSymbols.SHORTWEEKDAYS;
    final orderedWeekdays = [...shortWeekdays.sublist(1), shortWeekdays[0]];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: orderedWeekdays.map((day) {
        return Text(day, style: const TextStyle(fontWeight: FontWeight.bold));
      }).toList(),
    );
  }
}

class DayCard extends StatelessWidget {
  final DateTime date;
  final WorkStatus status;
  final bool isWeekend;
  final bool isCurrentDay;
  final VoidCallback? onTap;

  const DayCard({
    super.key,
    required this.date,
    required this.status,
    required this.isWeekend,
    required this.isCurrentDay,
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
          borderRadius:
              isCurrentDay ? BorderRadius.circular(12) : BorderRadius.circular(8),
          border: isCurrentDay
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2.0)
              : Border.all(
                  color: isWeekend ? Colors.grey.shade400 : Colors.transparent,
                ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status != WorkStatus.none
                  ? Colors.white
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

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

class MonthlyAttendanceIndicator extends StatelessWidget {
  final Function(DateTime) onMonthSelected;
  const MonthlyAttendanceIndicator({super.key, required this.onMonthSelected});

  @override
  Widget build(BuildContext context) {
    final workLog = Provider.of<WorkLog>(context);
    final today = DateUtils.dateOnly(DateTime.now());

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
          if (_isSameMonth(month, DateTime.now()))
            const Text('(Current Month)', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

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
