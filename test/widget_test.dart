import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

// Import the new mock setup and teardown functions
import './mock_firebase.dart';

void main() {
  // Use setUp and tearDown to manage the mock for each test.
  // This ensures a clean environment and that the mock is active.
  setUp(() {
    setupFirebaseCoreMocks();
  });

  tearDown(() {
    tearDownFirebaseCoreMocks();
  });

  testWidgets('Calendar interaction and state update', (WidgetTester tester) async {
    // Arrange: Initialize Firebase within the test body, AFTER the mock is set up.
    await Firebase.initializeApp();

    // Set up mock storage and the necessary providers.
    SharedPreferences.setMockInitialValues({});
    final workLog = WorkLog();
    final themeProvider = ThemeProvider();

    // Act: Build the app widget.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: workLog),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: MaterialApp(
          home: HomePageWrapper(), // Contains the FutureBuilder for loading.
        ),
      ),
    );

    // Wait for UI to settle after loading.
    await tester.pumpAndSettle();

    // Find a tappable weekday on the calendar.
    final dayToTapFinder = find.byWidgetPredicate((widget) {
      if (widget is DayCard) {
        return !widget.isWeekend;
      }
      return false;
    });

    // Assert: Ensure at least one such day exists.
    // Using `findsWidgets` which is the correct matcher.
    expect(dayToTapFinder, findsWidgets,
        reason: "Should find at least one weekday DayCard");

    // --- First Tap: Cycle to 'Office' ---
    await tester.tap(dayToTapFinder.first);
    await tester.pumpAndSettle();

    // Assert: Check widget state.
    DayCard dayCard = tester.widget(dayToTapFinder.first);
    expect(dayCard.status, WorkStatus.office,
        reason: "Status should be 'office' after first tap");

    // --- Second Tap: Cycle to 'Home' ---
    await tester.tap(dayToTapFinder.first);
    await tester.pumpAndSettle();

    // Assert: Check widget state.
    dayCard = tester.widget(dayToTapFinder.first);
    expect(dayCard.status, WorkStatus.home,
        reason: "Status should be 'home' after second tap");

        
    // --- Third Tap: Cycle to 'Leave' ---
    await tester.tap(dayToTapFinder.first);
    await tester.pumpAndSettle();

    // Assert: Check widget state.
    dayCard = tester.widget(dayToTapFinder.first);
    expect(dayCard.status, WorkStatus.leave,
        reason: "Status should be 'leave' after third tap");
  });
}
