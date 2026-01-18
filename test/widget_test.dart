import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Cycle work status on tap', (WidgetTester tester) async {
    // Setup the app with the necessary providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          // Initialize WorkLog without loading from shared_preferences for a clean test
          ChangeNotifierProvider(create: (context) => WorkLog()),
        ],
        child: const WorkTrackerApp(),
      ),
    );

    // Let the widget tree build
    await tester.pumpAndSettle();

    // Define a finder for tappable day cards
    final tappableDayFinder = find.byWidgetPredicate(
      (widget) =>
          widget is DayCard && widget.onTap != null && !widget.isWeekend,
      description: 'a tappable, non-weekend day card',
    );

    // Verify that we found at least one such day
    expect(tappableDayFinder, findsWidgets);

    // Get a finder that specifically targets the *first* tappable day
    final firstTappableDay = tappableDayFinder.first;

    // --- First Tap: None -> Office ---
    await tester.tap(firstTappableDay);
    await tester.pump(); // Rebuild the widget with the new state

    // Find the DayCard again and verify its state
    DayCard dayCard = tester.widget(firstTappableDay);
    expect(dayCard.status, WorkStatus.office);

    // --- Second Tap: Office -> Home ---
    await tester.tap(firstTappableDay);
    await tester.pump();

    dayCard = tester.widget(firstTappableDay);
    expect(dayCard.status, WorkStatus.home);

    // --- Third Tap: Home -> Leave ---
    await tester.tap(firstTappableDay);
    await tester.pump();

    dayCard = tester.widget(firstTappableDay);
    expect(dayCard.status, WorkStatus.leave);

    // --- Fourth Tap: Leave -> None ---
    await tester.tap(firstTappableDay);
    await tester.pump();

    dayCard = tester.widget(firstTappableDay);
    expect(dayCard.status, WorkStatus.none);
  });
}
