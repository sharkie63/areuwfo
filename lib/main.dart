import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/attendance_card.dart';
import 'package:myapp/loading_page.dart';
import 'package:myapp/notifications.dart';
import 'package:myapp/settings_page_new.dart';
import 'package:myapp/status_summary.dart';
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
import 'package:flutter/foundation.dart';

void main() {
  // Ensure Flutter bindings are initialized first.
  WidgetsFlutterBinding.ensureInitialized();

  // Run the root widget that handles initialization.
  runApp(const AppShell());
}

// This is the new root widget. It handles the app's initialization phase.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final Future<void> _initializationFuture;
  final WorkLog _workLog = WorkLog();

  @override
  void initState() {
    super.initState();
    // Start the asynchronous initialization.
    _initializationFuture = _initializeApp();
  }

  // This function contains all the asynchronous startup logic.
  Future<void> _initializeApp() async {
    try {
      // Use a guarded zone to catch all errors during initialization.
      await runZonedGuarded(() async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Initialize notifications.
        await NotificationService.instance.init(
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );

        // Load the persisted work log data.
        await _workLog.loadLog();

        // Set up global error handlers now that Firebase is initialized.
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }, (error, stack) {
        // Catch errors from within the guarded zone (e.g., Firebase init fails).
        developer.log(
          'Error during initialization phase',
          error: error,
          stackTrace: stack,
          name: 'com.example.myapp.initialization',
        );
        // Re-throw the error to be caught by the FutureBuilder.
        throw error;
      });
    } catch (e, stack) {
      developer.log(
        'Caught an error during _initializeApp',
        error: e,
        stackTrace: stack,
        name: 'com.example.myapp.initialization',
      );
      // Ensure the FutureBuilder knows about the error.
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a FutureBuilder to show a loading screen during initialization.
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // While loading, show the splash screen.
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: LoadingPage(),
            debugShowCheckedModeBanner: false,
          );
        }

        // If an error occurred, show a simple error screen.
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Initialization Failed: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        // Once initialization is complete, build the main app.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _workLog),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const WorkTrackerApp(),
        );
      },
    );
  }
}

// The main application widget, built only after initialization is complete.
class WorkTrackerApp extends StatefulWidget {
  const WorkTrackerApp({super.key});

  @override
  State<WorkTrackerApp> createState() => _WorkTrackerAppState();
}

class _WorkTrackerAppState extends State<WorkTrackerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final analytics = FirebaseAnalytics.instance;
    final observer = FirebaseAnalyticsObserver(analytics: analytics);

    _router = GoRouter(
      initialLocation: '/',
      observers: [observer],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/', pageBuilder: (context, state) => const NoTransitionPage(child: CalendarPage()))],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/settings', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPageNew()))],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10b981),
        brightness: Brightness.light,
        primary: const Color(0xFF10b981),
        onPrimary: Colors.white,
        background: const Color(0xFFf8fafc),
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600),
        headlineSmall: const TextStyle(fontWeight: FontWeight.bold),
      ),
      scaffoldBackgroundColor: const Color(0xFFf8fafc),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF10b981),
        unselectedItemColor: Colors.grey.shade600,
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF238636),
        brightness: Brightness.dark,
        background: const Color(0xFF0D1117),
        surface: const Color(0xFF161B22),
        onSurface: const Color(0xFFC9D1D9),
        primary: const Color(0xFF238636),
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC9D1D9)),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFC9D1D9)),
        headlineSmall: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC9D1D9)),
        bodyMedium: const TextStyle(color: Color(0xFFC9D1D9)),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
       bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF238636),
        unselectedItemColor: Colors.grey.shade600,
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'AreUWFO',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
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

Future<void> updateStatusInBackground(WorkStatus status) async {
  try {
    developer.log('Background update started for status: $status', name: 'com.example.myapp.background');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final workLog = await WorkLogStorage.readWorkLog();
    final today = DateUtils.dateOnly(DateTime.now());
    workLog[today] = status;
    await WorkLogStorage.writeWorkLog(workLog);
    developer.log('Background update successful.', name: 'com.example.myapp.background');
  } catch (e, s) {
    developer.log('FATAL ERROR in updateStatusInBackground: $e', name: 'com.example.myapp.background', error: e, stackTrace: s, level: 1200);
  }
}

enum WorkStatus { none, office, home, leave }

class WorkLogStorage {
  static const _workLogKey = 'workLog';

  static Future<Map<DateTime, WorkStatus>> readWorkLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logString = prefs.getString(_workLogKey);
      if (logString == null) return {};
      return await compute(_parseAndDecodeWorkLog, logString);
    } catch (e) {
      developer.log('Error reading work log: $e', name: 'com.example.myapp.storage');
      return {};
    }
  }

  static Future<void> writeWorkLog(Map<DateTime, WorkStatus> log) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> encodedLog = log.map(
      (key, value) => MapEntry(key.toIso8601String(), value.index),
    );
    await prefs.setString(_workLogKey, json.encode(encodedLog));
  }
}

Map<DateTime, WorkStatus> _parseAndDecodeWorkLog(String logString) {
  final Map<String, dynamic> decodedLog = json.decode(logString);
  return decodedLog.map((key, value) {
    return MapEntry(DateTime.parse(key), WorkStatus.values[value as int]);
  });
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
      // Don't record to crashlytics if it's not initialized
      // FirebaseCrashlytics.instance.recordError(e, stack);
      _log.clear();
      await _saveLog();
    } finally {
      developer.log("WorkLog: Notifying listeners of final state.", name: "com.example.myapp.worklog");
      // No need to notify here, FutureBuilder handles the UI transition
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

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          HapticFeedback.vibrate();
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  late DateTime _displayedMonth;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateUtils.dateOnly(DateTime.now());
  }

  void _changeMonth(int monthIncrement) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + monthIncrement, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildHeader(context),
          const SizedBox(height: 16),
          AttendanceCard(displayedMonth: _displayedMonth),
          const SizedBox(height: 16),
          CalendarGrid(displayedMonth: _displayedMonth, onMonthSwiped: _changeMonth),
          const SizedBox(height: 16),
          StatusSummary(displayedMonth: _displayedMonth),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMM().format(_displayedMonth),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
          ],
        ),
      ],
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: daysInMonth + firstWeekday -1,
              itemBuilder: (context, index) {
                final dayIndex = index - (firstWeekday -1);
                if (dayIndex < 0) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(
                  widget.displayedMonth.year,
                  widget.displayedMonth.month,
                  dayIndex + 1,
                );
                final status = workLog.getStatus(date);
                final isWeekend =
                    date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                final isCurrentDay =
                    DateUtils.dateOnly(date) == DateUtils.dateOnly(DateTime.now());

                return DayCard(
                  date: date,
                  status: status,
                  isWeekend: isWeekend,
                  isCurrentDay: isCurrentDay,
                  onTap: () async {
                    if (!isWeekend) {
                      HapticFeedback.vibrate();
                      final nextStatus = WorkStatus
                          .values[(status.index + 1) % WorkStatus.values.length];
                      await workLog.updateStatus(date, nextStatus);
                    }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color? bgColor;
    Color? textColor;
    BoxBorder? border;

    if (isCurrentDay) {
      border = Border.all(color: Colors.blue, width: 2);
    }

    if (!isWeekend) {
      if (isDarkMode) {
        switch (status) {
          case WorkStatus.office:
            bgColor = const Color(0xFF238636);
            textColor = Colors.white;
            break;
          case WorkStatus.home:
            bgColor = const Color(0xFFB94545);
            textColor = Colors.white;
            break;
          case WorkStatus.leave:
            bgColor = const Color(0xFFfbbf24);
            textColor = Colors.white;
            break;
          case WorkStatus.none:
            bgColor = const Color(0xFF22272E);
            break;
        }
      } else {
        switch (status) {
          case WorkStatus.office:
            bgColor = const Color(0xFFd1fae5);
            textColor = const Color(0xFF065f46);
            break;
          case WorkStatus.home:
            bgColor = const Color(0xFFfee2e2);
            textColor = const Color(0xFF991b1b);
            break;
          case WorkStatus.leave:
            bgColor = const Color(0xFFfef3c7);
            textColor = const Color(0xFF92400e);
            break;
          case WorkStatus.none:
            break;
        }
      }
    } else {
       border = Border.all(color: Colors.transparent);
       if (isDarkMode) {
        bgColor = const Color(0xFF0D1117);
       }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(100),
          border: border,
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor ?? (isWeekend ? Colors.grey.shade600 : (isDarkMode ? Colors.grey.shade400 : null)),
            ),
          ),
        ),
      ),
    );
  }
}
