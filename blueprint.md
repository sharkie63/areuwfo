# App Blueprint

## Overview

A simple and intuitive Flutter application to track daily work locations (Office, Home, or Off). This app will provide a clear and easy-to-use interface for users to log and view their work status for each day.

## Style, Design, and Features

### Initial Version (v1.0)

*   **Theme:** A clean and modern theme using Material 3, with a clear and readable font. The app will support both light and dark modes.
*   **Typography:** The app will use the `google_fonts` package to apply the 'Roboto' font for body text and 'Montserrat' for titles, giving it a professional and modern look.
*   **Layout:** The main screen will feature a calendar-like view to display the days of the month. Each day will be represented as a card with the date and the current work status.
*   **State Management:** The app will use the `provider` package for state management to handle theme changes and data updates efficiently.
*   **Interactivity:** Users can tap on a day to cycle through the work statuses (Office, Home, Off).

## Current Plan

### Create the Work Tracker App

1.  **Add Dependencies:** Add `provider` and `google_fonts` to `pubspec.yaml`.
2.  **Create Data Model:** Define a `WorkStatus` enum to represent the different work locations.
3.  **Implement State Management:**
    *   Create a `WorkLog` class to store the work status for each day.
    *   Create a `ThemeProvider` to manage the app's theme (light/dark mode).
4.  **Develop the UI:**
    *   Modify `lib/main.dart`.
    *   Set up `ChangeNotifierProvider` for both `WorkLog` and `ThemeProvider`.
    *   Create a main screen with an `AppBar` that includes a theme toggle button.
    *   Display a grid of days for the current month.
    *   Each day will be a clickable card that shows the date and status.
    .
5.  **Add Functionality:**
    *   Implement the logic to update the work status when a day card is tapped.
    *   The status will cycle through 'Work from Home', 'Work from Office', and 'Off'.
