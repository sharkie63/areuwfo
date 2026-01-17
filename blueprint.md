# Project Blueprint

## Overview

This document outlines the style, design, and features of the AreUWFO work tracker application.

## Current State

### Style and Design

*   **Theme:** Material 3 with a deep purple seed color.
*   **Color Scheme:** Light and dark themes are supported.
*   **Typography:** Default TextTheme with placeholder styles.

### Features

*   **Work Log:** Users can log their work status (office, home, leave) for each day.
*   **Calendar View:** A grid-based calendar displays the work log for the selected month.
*   **Attendance Tracking:** A progress bar shows the in-office attendance percentage for the current month.
*   **Monthly Indicators:** A visual indicator shows the attendance percentage for the last six months.
*   **Settings:** A settings page is available but not yet implemented.

## Current Task: Add Firebase Integration

### Plan

1.  **Add Firebase Dependencies:** Add `firebase_core` to `pubspec.yaml`.
2.  **Initialize Firebase:** Add Firebase initialization code to `lib/main.dart`.
3.  **Configure Firebase:** Run `flutterfire configure` to generate `firebase_options.dart`.
4.  **Create Blueprint:** Create a `blueprint.md` file to document the project.