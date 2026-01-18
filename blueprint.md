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

### Theming & UI
- **Light/Dark Mode:** The app supports both light and dark themes, with a toggle in the settings.
- **Haptic Feedback:** Haptic feedback is provided for interactions, and it can be enabled or disabled in the settings.
- **Customizable Theme:** The app uses a `ThemeProvider` to manage theme-related settings.
- **Lottie Animation Splash Screen:** The app now displays a smooth `.lottie` animation while initial data is being loaded, replacing the previous static loading indicator.
- **Custom App Icon:** The app's launcher icon has been updated by replacing the source image and running the `flutter_launcher_icons` package to generate all necessary icon sizes.

### Notifications
- **Daily Reminders:** Users can enable daily reminders to log their work status.
- **Customizable Notification Time:** The time for the daily reminder can be set from the settings page.
- **Notification Actions:** The notification includes quick actions ("Office", "Home", "Leave") to log the work status directly from the notification.
- **Permission Handling:** The app requests notification permissions when it's launched for the first time. The "exact alarm" permission is requested only when the user enables daily reminders.

### Error Handling & Firebase
- **Crashlytics Integration:** The app is integrated with Firebase Crashlytics to report crashes and errors.
- **Zoned Error Handling:** The app uses `runZonedGuarded` to catch and report errors that occur in the Flutter framework.
- **Firebase Configuration:** The app has been configured to use the correct Firebase project and app IDs.
- **Build Context Safety:** Implemented checks to ensure `BuildContext` is not used in `async` gaps to prevent runtime crashes.

## Current Plan: Implement Splash Screen & App Icon

The following steps were taken to enhance the application's startup experience and branding:

1.  **Add Lottie Package:** The `lottie` package was added to the project to enable support for Lottie animations.
2.  **Add Lottie Asset:** An `assets/lottie` directory was created, and the `loading.lottie` animation file was added.
3.  **Update `pubspec.yaml`:** The `assets/lottie/` directory was declared in the `pubspec.yaml` file to make the asset accessible.
4.  **Create Loading Page:** A new `LoadingPage` widget was created to display the Lottie animation.
5.  **Implement Smart Loading:** The app's entry point (`lib/main.dart`) was refactored to use a `FutureBuilder`. This displays the `LoadingPage` while the `workLog.loadLog()` operation completes in the background, ensuring a smooth transition to the fully-loaded `HomePage`.
6.  **Update App Icon:** The `flutter_launcher_icons` package was executed to generate and apply the new app icon from the user-provided `assets/icon/icon.png` file.
