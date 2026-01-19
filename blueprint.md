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
- **Build Context Safety:** Implemented checks to ensure `BuildContext` is not used in `async` gaps to prevent runtime crashes.

## Current Plan: Fixing Android Build & Firebase Integration

A critical issue was identified where the Android application would crash on launch due to a misconfiguration with Firebase. The following steps were taken to diagnose and resolve the problem:

1.  **Initial Diagnosis:** The app was crashing immediately upon startup. The initial investigation pointed towards an issue with Firebase initialization, as the crash occurred after integrating Firebase services like Crashlytics and Notifications.

2.  **Google Services Plugin:** The root cause was traced back to the `com.google.gms.google-services` Gradle plugin not being correctly applied. This was resolved by:
    *   Adding `classpath 'com.google.gms:google-services:4.4.2'` to the `dependencies` block in `android/build.gradle.kts`.
    *   Applying the plugin `id("com.google.gms.google-services")` in the `android/app/build.gradle.kts` file.

3.  **Package Name Mismatch:** After applying the plugin, a new, more informative error emerged: `No matching client found for package name 'com.example.myapp'`. This indicated that the `applicationId` in the app's build configuration did not match the package name registered in the `google-services.json` file from Firebase.

4.  **Correcting Package Name:** The fix involved:
    *   Reading the correct package name (`com.areuwfo.tracker`) from `android/app/google-services.json`.
    *   Updating the `applicationId` and `namespace` in `android/app/build.gradle.kts` from the placeholder `com.example.myapp` to the correct `com.areuwfo.tracker`.

5.  **Build Versioning:** For better tracking in Firebase Crashlytics, the `versionCode` in `android/app/build.gradle.kts` was incremented to `2` and `versionName` to `1.0.1`.

6.  **Verification:** The package name was verified across all relevant Android configuration files, including `MainActivity.kt` and the various `AndroidManifest.xml` files, to ensure consistency.

7.  **Final Resolution:** After a `flutter clean`, the app was successfully built and launched on the Android emulator without crashing, confirming that the Firebase integration is now correctly configured.
