# App Blueprint

## Overview

A Flutter application that helps users track their work status (in-office or remote) for each day. The app provides a calendar view to visualize the work log and allows users to manage their preferences.

## Style and Design

*   **Theme:** Modern, clean, and visually balanced with Material Design 3 components.
*   **Color Palette:** A vibrant and energetic look and feel with a wide range of color concentrations and hues.
*   **Typography:** Expressive and relevant typography with an emphasis on font sizes to ease understanding.
*   **Layout:** Mobile-responsive design that adapts to different screen sizes.
*   **Interactivity:** Modern, interactive iconography and UI components with elegant use of color and shadow to create a "glow" effect.

## Features

*   **Work Log:**
    *   Users can mark each day as "in-office," "remote," or "off."
    *   A calendar view displays the work status for each day.
*   **Settings:**
    *   **Theme:** Users can switch between light, dark, and system theme.
    *   **Notifications:** Users can enable or disable daily reminders to log their work.
    *   **Data:**
        *   Users can export their work log as a CSV file.
        *   Users can reset all their application data.
    *   **Preferences:** Users can enable or disable haptic feedback.

## Current Task: Add Data Reset Functionality

*   **User Story:** As a user, I want to be able to reset all my data in the application so that I can start over from scratch.
*   **Plan:**
    1.  Add a "Reset Data" button to the settings page.
    2.  Implement a confirmation dialog to prevent accidental data deletion.
    3.  Upon confirmation, clear all the stored data.
    4.  Restart the application or navigate to the loading screen to reload the initial state.
