# App Blueprint

## Overview

A simple and intuitive Flutter application to track daily work locations (Office, Home, or Leave). This app will provide a clear and easy-to-use interface for users to log and view their work status for each day.

## Style, Design, and Features

### Initial Version (v1.0)

*   **Theme:** A clean and modern theme using Material 3, with a clear and readable font. The app will support both light and dark modes.
*   **Typography:** The app will use the `google_fonts` package to apply the 'Roboto' font for body text and 'Montserrat' for titles, giving it a professional and modern look.
*   **Layout:** The main screen will feature a calendar-like view to display the days of the month. Each day will be represented as a card with the date and the current work status.
*   **State Management:** The app will use the `provider` package for state management to handle theme changes and data updates efficiently.
*   **Interactivity:** Users can tap on a day to cycle through the work statuses (Office, Home, Leave).

### Second Version (v2.0)

*   **Work Statuses:** The work statuses will be updated to: 'Home', 'Office', and 'Leave'.
*   **Work Week:** The app will recognize that the work week is Monday to Friday.
*   **Weekends:** Saturdays and Sundays will be visually distinct and disabled, as they are non-working days.

### Third Version (v3.0)

*   **Display Day and Week:** Each day card will display the day of the week (e.g., 'Mon') and the calendar week number.

### Fourth Version (v4.0)

*   **Color-Coded Statuses:** The day cards will be color-coded based on the work status:
    *   **Home:** Red
    *   **Office:** Green
    *   **Leave/Holiday:** Yellow
*   **Future Dates:** Days that are in the future will not have a color fill.
*   **Simplified UI:** The calendar view was simplified to show only the day number with the corresponding color fill.

### Fifth Version (v5.0)

*   **Attendance Percentage:** A new section was added below the calendar to display the percentage of in-office attendance for the current month, calculated based on the days up to the current date.

### Sixth Version (v6.0)

*   **Revised Attendance Calculation:** The attendance formula has been updated:
    *   The calculation now considers the **entire month**.
    *   The **Total Working Days** are now calculated as (Total Weekdays in the month) - (Days marked as 'Leave').
*   **Dynamic Progress Bar Color:** The color of the attendance progress bar is now dynamic:
    *   **Red** if the attendance is less than 60%.
    *   **Green** if the attendance is 60% or greater.

### Seventh Version (v7.0)
*   **Color Legend:** A legend has been added below the attendance tracker to explain the color-coding for each work status.

### Eighth Version (v8.0)
*   **Data Persistence:** The app now saves the work log data to the device's local storage using `shared_preferences`. The data is loaded when the app starts and saved whenever a change is made, ensuring that the user's log is not lost between sessions.

### Ninth Version (v9.0)
*   **Month-to-Month Navigation:** The user can now navigate between months within a six-month window (past and future).

### Tenth Version (v10.0)
*   **Weekday Headers:** Added short-form day of the week headers (e.g., 'Mon', 'Tue') to the calendar view.

### Eleventh Version (v11.0)
*   **UI Refinements:**
    *   Defaulted the app theme to the system's theme.
    *   Removed the manual theme-toggle button.
    *   Centered the app bar title and navigation controls.

### Twelfth Version (v12.0)
*   **Monthly Attendance Indicators:** Added a row of six tappable dots below the attendance tracker to show the attendance for the previous six months and allow for quick navigation.

### Thirteenth Version (v13.0)
*   **Relocated Color Legend:**
    *   Moved the color legend into a popup dialog, triggered by an info button in the app bar.
    *   Arranged the legend items vertically and left-aligned the text for a cleaner look.

### Fourteenth Version (v14.0)
*   **Improved Monthly Indicators Logic:**
    *   The indicators now correctly show the six months *prior* to the current month.
    *   The dots are arranged chronologically, from oldest to most recent.

### Fifteenth Version (v15.0)
*   **Settings Page:** A new settings page has been added to the app, accessible via a cog icon in the top-left corner of the home screen.
*   **Theme Selection:** The settings page includes options to switch between light, dark, and system default themes. The selected theme is persisted across app launches.
*   **Routing:** The app now uses the `go_router` package for navigation, providing a more robust and scalable routing solution.

## Current Plan

### Implement Settings Page and Theme Selection

1.  **Create `lib/settings_page.dart`**: Create a new file to define the UI for the settings page. This will include the radio buttons for selecting "Light," "Dark," and "System" themes.
2.  **Create `lib/theme_provider.dart`**: Create a dedicated file for a `ThemeProvider` class using `ChangeNotifier` to manage the application's theme state.
3.  **Update `pubspec.yaml`**: Add the `go_router` package for navigation.
4.  **Update `lib/main.dart`**:
    *   Wrap the main `WorkTrackerApp` with the new `ChangeNotifierProvider` for the `ThemeProvider`.
    *   Modify the `MaterialApp` to be a `MaterialApp.router` to handle the navigation.
    *   In the `MyHomePage` `AppBar`, add an `IconButton` with a settings (cog) icon that, when pressed, will navigate to our new `SettingsPage`.
