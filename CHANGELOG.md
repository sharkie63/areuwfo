# AreUWFO — Changelog

## [1.0.1+7] — 2026-02-20

### New Features
- **Daily Reminder Notification**: Added a daily notification at 10:00 AM to remind users to log attendance. Toggle available in Settings under PREFERENCES. Uses `inexactAllowWhileIdle` scheduling (no `SCHEDULE_EXACT_ALARM` permission — Play Store compliant).
- **Ad Analytics**: Integrated lean Firebase Analytics logging for ad events — only tracks `ad_init`, `ad_consent`, and `ad_load_fail` to avoid overwhelming the dashboard.

### Bug Fixes
- **Settings back button exits app**: Fixed — pressing the Android back button on the Settings tab now returns to the Calendar tab instead of closing the app. Implemented via `PopScope` on the `ScaffoldWithNavBar` widget.
- **Dark mode text visibility**: All text styles now correctly inherit light colors in dark mode using `baseTextTheme.apply(bodyColor, displayColor)`.
- **Dark mode toggle incorrect on first launch**: Fixed by checking `Theme.of(context).brightness` instead of `themeProvider.themeMode`.
- **Font size inconsistency between themes**: Created a single shared `baseTextTheme` used by both light and dark themes.
- **Text overflow in AttendanceCard legend**: Legend items use `Wrap` widget; target badge uses `Flexible` + `TextOverflow.ellipsis`.
- **Text overflow in StatusSummary**: Summary card labels wrapped in `Flexible` with `TextOverflow.ellipsis`.
- **Text overflow in Settings page**: "Office Attendance Goal" label made `Flexible`.
- **Calendar month name overflow**: Wrapped in `Flexible` widget.
- **Weekday header overflow**: Uses `Expanded` + `Center` + `TextOverflow.ellipsis`.

### Ad Improvements
- **Interstitial retry logic**: Auto-retries after 30 seconds on load failure.
- **Interstitial frequency cap**: Reduced from 5 minutes to 2 minutes.
- **Rewarded ad fallback**: If ad doesn't load within 3 seconds, reward is granted anyway to ensure export always works.
- **Banner ad retry**: Retries loading after 30-second delay on failure.

### iOS Submission Readiness
- **Privacy Manifest**: Added `PrivacyInfo.xcprivacy` declaring tracking (AdMob Device ID), crash data (Crashlytics), analytics (Firebase), and accessed APIs (UserDefaults, FileTimestamp). Added to Xcode project via `xcodeproj` gem.
- **App Icon alpha channel**: Removed alpha from 1024x1024 iOS icon (Apple rejects icons with transparency).

### Technical Changes
- **Dependencies added**: `flutter_local_notifications: 19.5.0`, `flutter_timezone: ^5.0.1`, `timezone: ^0.10.0`.
- **Notification service**: `lib/services/notification_service.dart` — handles init, permission request, schedule, and cancel. Uses `flutter_timezone` v5 `TimezoneInfo.identifier` for timezone name.
- **Non-blocking notification init**: Wrapped in try-catch in `main.dart` so failures don't prevent app launch.
- **Boot receiver**: Added `ScheduledNotificationBootReceiver` to `AndroidManifest.xml` for notification persistence across reboots.
- **Android permissions**: `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, `VIBRATE`, `INTERNET` (no `SCHEDULE_EXACT_ALARM`).
- **Pinned `flutter_local_notifications`** to stable v19.5.0 — the auto-resolved v21.0.0-dev.1 (prerelease) had breaking API changes.

### Files Modified
| File | Change |
|------|--------|
| `lib/main.dart` | NotificationService init, PopScope on ScaffoldWithNavBar, shared text theme |
| `lib/settings_page_new.dart` | Daily Reminder toggle, removed redundant PopScope, dark mode toggle fix |
| `lib/services/ad_service.dart` | Lean analytics logging, retry logic, frequency cap |
| `lib/services/notification_service.dart` | **NEW** — daily notification scheduling |
| `lib/attendance_card.dart` | Text overflow fixes in legend |
| `lib/status_summary.dart` | Text overflow fixes in summary cards |
| `android/app/src/main/AndroidManifest.xml` | Boot receiver, VIBRATE permission |
| `android/app/build.gradle.kts` | versionCode 7 |
| `ios/Runner/PrivacyInfo.xcprivacy` | **NEW** — iOS privacy manifest |
| `ios/Runner.xcodeproj/project.pbxproj` | PrivacyInfo added to build |
| `pubspec.yaml` | Version 1.0.1+7, new notification deps |
| `.gitignore` | Added `*_logs.txt` |

---

## [1.0.0] — 2026-01-24

### Initial Release
- Calendar-based attendance tracker (Office / Home / Leave)
- Monthly attendance percentage with progress ring
- Configurable attendance goal slider
- Dark/Light mode with system default
- CSV export with rewarded ad gate
- AdMob integration (banner, interstitial, rewarded)
- Firebase Analytics, Crashlytics
- Privacy policy at `https://areuwfo-tracker.web.app/privacy.html`
