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
- **Dynamic `StatusSummary` Widget:** This new widget displays a summary of the total "Office," "Home," and "Leave" days for the currently displayed month. It is integrated with the `WorkLog` provider to update dynamically as the user logs their work status.
- **Layout Adjustments:** The vertical spacing on the `CalendarPage` has been optimized to ensure that all key components, including the `StatusSummary`, are visible on most screen sizes without requiring the user to scroll.
- **Dark Mode Enhancement:** Updated the application's dark theme to a new, modern color scheme based on user-provided designs. The new theme improves visibility and aesthetics, particularly on the calendar page. The color palette includes a deep navy background (`#0D1117`), slightly lighter cards (`#161B22`), and a vibrant green accent (`#238636`), with improved text colors (`#C9D1D9`) for better readability. The `DayCard` widget was also updated to ensure calendar dates are clearly visible against their status-colored backgrounds in dark mode.

### Notifications
- **Daily Reminders:** Users can enable daily reminders to log their work status.
- **Customizable Notification Time:** The time for the daily reminder can be set from the settings page.
- **Notification Actions:** The notification includes quick actions ("Office", "Home", "Leave") to log the work status directly from the notification.
- **Permission Handling:** The app requests notification permissions when it's launched for the first time. The "exact alarm" permission is requested only when the user enables daily reminders.

### Error Handling & Firebase
- **Crashlytics Integration:** The app is integrated with Firebase Crashlytics to report crashes and errors.
- **Zoned Error Handling:** The app uses `runZonedGuarded` to catch and report errors that occur in the Flutter framework.
- **Build Context Safety:** Implemented checks to ensure `BuildContext` is not used in `async` gaps to prevent runtime crashes.

## Current Plan: New UI/UX Redesign

The application is undergoing a significant UI/UX redesign to create a more modern, intuitive, and visually appealing experience. This redesign is based on a new design mockup that introduces a cleaner layout, improved typography, and a fresh color scheme.

### New Design Implementation Plan:

1.  **Theme Update:**
    *   The color scheme has been updated to use a new primary color (`#10b981`).
    *   The "Inter" font has been integrated using the `google_fonts` package to enhance typography.

2.  **Home Page Refactor:**
    *   The existing `AppBar` has been removed and replaced with a custom header that includes the current month and year, along with navigation controls.
    *   The layout has been restructured to accommodate the new UI components.

3.  **New Widget Creation:**
    *   **`AttendanceCard`:** A new widget has been built to display the circular progress indicator for "in-office" attendance, the monthly attendance goal, and a legend for the different work statuses.
    *   **`StatusSummary`:** A set of cards has been created to provide a quick summary of the total number of "Office," "Home," and "Leave" days for the current month.

4.  **Calendar Styling:**
    *   The `CalendarGrid` widget has been restyled to match the new design, including rounded date cells, updated typography, and new color-coded indicators for each work status.

5.  **Bottom Navigation:**
    *   A new bottom navigation bar has been implemented to provide clear and easy access to the main sections of the app, such as "Calendar" and "Settings."
