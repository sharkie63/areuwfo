# AreUWFO - Work Tracker App Blueprint

## Overview

AreUWFO is a Flutter-based mobile application designed to help users track their work status, whether they are working from the office, from home, or are on leave. The app provides a calendar view to log daily work statuses, calculates in-office attendance percentages, and allows users to set up daily reminders. The application features a modern, clean UI with both light and dark themes, and it ensures a stable user experience by preserving navigation and page state correctly.

## Implemented Features

### Core Functionality
- **Work Status Logging:** Users can tap on a date in the calendar to cycle through different work statuses (Office, Home, Leave).
- **Calendar View:** A monthly calendar grid that visually displays the work status for each day.
- **Swipe Navigation:** Users can swipe left or right on the calendar to navigate between months.
- **Attendance Tracking:** The app calculates and displays the in-office attendance percentage for the current month against a user-configurable goal.
- **Data Persistence:** The work log and user settings are saved locally on the device using `shared_preferences`.

### UI/UX & Theming
- **Modern Redesign:** A complete UI/UX overhaul based on a modern design mockup, featuring a cleaner layout, improved typography (`Inter` font via `google_fonts`), and a fresh color scheme.
- **Light/Dark Mode:** The app supports both light and dark themes, with a toggle in the settings. The dark mode uses a new, high-contrast color palette for improved readability.
- **Haptic Feedback:** Haptic feedback is provided for interactions and can be toggled in the settings.
- **Custom Widgets:** The home page includes custom-built widgets like `AttendanceCard` (for the circular progress indicator) and `StatusSummary` (for a monthly breakdown of work statuses).
- **Lottie Animation Splash Screen:** The app displays a smooth `.lottie` animation while initial data is being loaded.
- **Custom App Icon:** The app's launcher icon has been updated to a custom design.
- **Refined Settings Page:** A completely redesigned settings page with a clean, card-based layout, and intuitive controls for all user-configurable options.

### Notifications
- **Daily Reminders:** Users can enable daily reminders to log their work status.
- **Customizable Notification Time:** The time for the daily reminder can be set from the settings page.
- **Notification Actions:** The notification includes quick actions ("Office", "Home", "Leave") to log the work status directly from the notification shade.
- **Robust Permission Handling:** The app correctly requests notification permissions and handles the `SCHEDULE_EXACT_ALARM` permission on Android when daily reminders are enabled.

### Firebase Integration
- **Crashlytics:** The app is integrated with Firebase Crashlytics to automatically report crashes and errors for improved stability.
- **Analytics:** Firebase Analytics is used to gather basic usage data and navigation events.
- **Zoned Error Handling:** The app uses `runZonedGuarded` to catch and report errors that occur anywhere in the Flutter framework, ensuring they are logged to Crashlytics.

## Final Architecture & Navigation

To address navigation state preservation issues, the application's architecture was significantly refactored to be robust and efficient. The final implementation ensures that the user's tab selection and the state of each page (like scroll position or the month displayed in the calendar) are correctly maintained, even when the theme is changed or the app is rebuilt.

### Key Architectural Components:

1.  **Stateful Router (`go_router`):**
    *   The main application widget (`WorkTrackerApp`) is a `StatefulWidget`.
    *   The `GoRouter` instance is created and stored in the `initState` method, ensuring that a single, stable router instance persists throughout the app's lifecycle. This prevents the navigation state from being lost during widget rebuilds (e.g., on theme change).

2.  **Stateful Shell Route (`StatefulShellRoute`):**
    *   Tab-based navigation is managed by a `StatefulShellRoute`, which is the standard, modern approach for handling bottom navigation bars with `go_router`.
    *   It manages two separate navigation branches: one for the `CalendarPage` and one for the `SettingsPageNew`.

3.  **State Preservation with `AutomaticKeepAliveClientMixin`:**
    *   Both the `CalendarPage` and `SettingsPageNew` are implemented as `StatefulWidget`s.
    *   They both use the `AutomaticKeepAliveClientMixin` to ensure their state is not discarded when the user switches between tabs.

4.  **Transitionless Navigation (`NoTransitionPage`):**
    *   To ensure a smooth and native-feeling tab switching experience, the routes within the `StatefulShellRoute` are wrapped in a `NoTransitionPage`. This disables the default page transition animation, making the tab switch instant, as expected in a bottom navigation bar layout.
