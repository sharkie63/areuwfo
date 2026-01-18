# AreUWFO - Work Tracker App Blueprint

## Overview

AreUWFO is a Flutter-based mobile application designed to help users track their work status, whether they are working from the office, from home, or are on leave. The app provides a calendar view to log daily work statuses, calculates in-office attendance percentages, and allows users to set up daily reminders.

## Implemented Features

### Core Functionality
- **Work Status Logging:** Users can tap on a date in the calendar to cycle through different work statuses (Office, Home, Leave).
- **Calendar View:** A monthly calendar grid that visually displays the work status for each day.
- **Swipe Navigation:** Users can swipe left or right on the calendar to navigate between months.
- **Attendance Tracking:** The app calculates and displays the in-office attendance percentage for the current month.
- **Monthly Attendance Indicator:** A visual indicator showing the attendance percentage for the past six months.
- **Data Persistence:** The work log is saved locally on the device using `shared_preferences`.
- **Loading State:** The app displays a loading screen while the work log data is being loaded.
- **Settings:** A dedicated settings page to manage app preferences.

### Theming & UI
- **Light/Dark Mode:** The app supports both light and dark themes, with a toggle in the settings.
- **Haptic Feedback:** Haptic feedback is provided for interactions, and it can be enabled or disabled in the settings.
- **Customizable Theme:** The app uses a `ThemeProvider` to manage theme-related settings.

### Notifications
- **Daily Reminders:** Users can enable daily reminders to log their work status.
- **Customizable Notification Time:** The time for the daily reminder can be set from the settings page.
- **Notification Actions:** The notification includes quick actions ("Office", "Home", "Leave") to log the work status directly from the notification.
- **Permission Handling:** The app requests notification permissions when it's launched for the first time. The "exact alarm" permission is requested only when the user enables daily reminders.

### Error Handling & Firebase
- **Crashlytics Integration:** The app is integrated with Firebase Crashlytics to report crashes and errors.
- **Zoned Error Handling:** The app uses `runZonedGuarded` to catch and report errors that occur in the Flutter framework.
- **Firebase Configuration:** The app has been configured to use the correct Firebase project and app IDs, resolving an issue with conflicting configurations.

## Current Plan: Create Release Build

The following steps are being taken to create a release build of the application:

1.  **Fix Firebase Configuration:** The `google-services.json`, `firebase.json`, and `lib/firebase_options.dart` files were updated to use the correct Firebase app ID for the `com.areuwfo.tracker` package.
2.  **Confirm Build Strategy:** It was confirmed that a dedicated release keystore has not been created. The build will proceed using the default debug signing key for testing purposes.
3.  **Build App Bundle:** An Android App Bundle (.aab) was successfully built for potential Play Store distribution.
4.  **Build APK:** A universal APK file will now be built for direct installation and testing.
