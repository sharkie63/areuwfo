# AreUWFO — Architectural Blueprint

> **⚠️ This file is the single source of truth for the app's architecture.**
> Every AI model or developer working on this codebase MUST read this file before making changes.
> After every major change, this file MUST be updated. See the [Change Protocol](#change-protocol) section.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Identity](#project-identity)
3. [Tech Stack & Dependencies](#tech-stack--dependencies)
4. [Project Structure](#project-structure)
5. [Architecture](#architecture)
6. [Navigation & Routing](#navigation--routing)
7. [State Management](#state-management)
8. [Theming & Design System](#theming--design-system)
9. [Services](#services)
10. [Data Layer](#data-layer)
11. [UI Components](#ui-components)
12. [Conventions & Rules](#conventions--rules)
13. [Known Gotchas](#known-gotchas)
14. [Change Protocol](#change-protocol)
15. [Current Version](#current-version)

---

## Overview

AreUWFO is a Flutter mobile app that helps users track their daily work location — Office, Home, or Leave. It provides a calendar view, monthly attendance percentage with a configurable goal, and data export. The app runs on both Android and iOS with Firebase backend services and AdMob monetization.

---

## Project Identity

| Field | Value |
|-------|-------|
| **Package name (Dart)** | `myapp` |
| **Android app ID** | `com.areuwfo.tracker` |
| **iOS bundle ID** | `com.areuwfo.tracker` |
| **Display name** | `AreUWFO` |
| **Min Android SDK** | 23 (Android 6.0) |
| **Min iOS version** | 14.0 |
| **Flutter SDK** | `>=3.4.1 <4.0.0` |
| **Material Design** | Material 3 (`useMaterial3: true`) |

---

## Tech Stack & Dependencies

### Core
| Package | Purpose | Pinned? |
|---------|---------|---------|
| `provider` | State management (ChangeNotifier) | No |
| `go_router` | Declarative routing with StatefulShellRoute | No |
| `google_fonts` | Typography (`Inter` font family) | No |
| `shared_preferences` | Local data persistence | No |
| `intl` | Date formatting | No |

### Firebase
| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_analytics` | Usage analytics |
| `firebase_crashlytics` | Crash reporting |
| `firebase_auth` | Auth (declared but not actively used) |
| `cloud_firestore` | Firestore (declared but not actively used) |

### Monetization
| Package | Purpose |
|---------|---------|
| `google_mobile_ads` | AdMob (banner, interstitial, rewarded) |

### Notifications
| Package | Purpose | Pinned? |
|---------|---------|---------|
| `flutter_local_notifications` | Daily reminder scheduling | **YES — 19.5.0** |
| `flutter_timezone` | Device timezone for scheduling | No |
| `timezone` | Timezone database (`^0.10.0`) | No |

> **⚠️ CRITICAL**: `flutter_local_notifications` is pinned to `19.5.0` exactly. Do NOT use `^` or upgrade to v21+ (prerelease with breaking API changes). The `timezone` package is pinned to `^0.10.0` to match.

### Utilities
| Package | Purpose |
|---------|---------|
| `path_provider` | Temp directory for CSV export |
| `share_plus` | Share sheet for CSV export |
| `package_info_plus` | App version display |
| `url_launcher` | Open privacy policy URL |
| `lottie` | Splash screen animation |
| `csv` | CSV generation (declared) |

---

## Project Structure

```
lib/
├── main.dart                      # Entry point, routing, theming, WorkLog model, CalendarPage, ScaffoldWithNavBar
├── theme_provider.dart            # ThemeProvider (ChangeNotifier) — theme mode, haptic, attendance goal
├── settings_page_new.dart         # Settings UI — all user preferences, export, notifications toggle
├── attendance_card.dart           # Circular progress ring + legend widget
├── status_summary.dart            # Monthly day counts (Office/Home/Leave)
├── loading_page.dart              # Splash/loading screen with Lottie animation
├── ad_helper.dart                 # Platform-aware ad unit ID resolver (debug vs release)
├── ad_secrets.dart                # ⚠️ SENSITIVE — Production AdMob IDs (gitignored)
├── firebase_options.dart          # Auto-generated Firebase config
└── services/
    ├── ad_service.dart            # Singleton — ad loading, showing, retry, analytics logging
    └── notification_service.dart  # Singleton — daily notification scheduling
```

### Native Files of Note
```
android/app/src/main/AndroidManifest.xml  # Permissions, AdMob app ID, boot receiver
ios/Runner/Info.plist                      # Privacy keys, AdMob app ID, SKAdNetwork
ios/Runner/PrivacyInfo.xcprivacy           # iOS 17+ privacy manifest
```

---

## Architecture

### Initialization Flow
```
main() → AppShell (StatefulWidget)
  └── _initializeApp() via FutureBuilder
      ├── Firebase.initializeApp()
      ├── AdService().initialize()            # Consent + ad loading
      ├── NotificationService().initialize()  # Timezone + local notification setup (try-catch, non-blocking)
      ├── WorkLog.loadLog()                   # Load persisted data from SharedPreferences
      └── Setup Crashlytics error handlers
  └── On success → MultiProvider → WorkTrackerApp
  └── On loading → LoadingPage (Lottie splash)
  └── On error → Error screen
```

### Widget Tree
```
MultiProvider
├── ChangeNotifierProvider<WorkLog>
├── ChangeNotifierProvider<ThemeProvider>
└── WorkTrackerApp (StatefulWidget — owns GoRouter)
    └── MaterialApp.router
        └── StatefulShellRoute.indexedStack
            └── ScaffoldWithNavBar (PopScope + BottomNavigationBar)
                ├── Branch 0: CalendarPage (AutomaticKeepAliveClientMixin)
                │   ├── AttendanceCard
                │   ├── CalendarGrid
                │   └── StatusSummary
                └── Branch 1: SettingsPageNew (AutomaticKeepAliveClientMixin)
                    └── BannerAdWidget
```

### Design Principles
1. **Singleton services** — `AdService` and `NotificationService` use factory constructors with private static instances.
2. **Non-blocking service init** — Notification init is wrapped in try-catch. Ad init failure is logged but doesn't crash.
3. **FutureBuilder for async init** — `AppShell` uses a `FutureBuilder` to show loading/error/ready states.
4. **State preservation** — Both tab pages use `AutomaticKeepAliveClientMixin` to survive tab switches.
5. **Stable router** — `GoRouter` is created in `initState`, not `build`, to survive rebuilds.

---

## Navigation & Routing

| Route | Page | Tab Index |
|-------|------|-----------|
| `/` | `CalendarPage` | 0 |
| `/settings` | `SettingsPageNew` | 1 |

### Back Button Behavior
- Handled by `PopScope` on `ScaffoldWithNavBar` (NOT on individual pages).
- If on Calendar (index 0): Android back exits app normally (`canPop: true`).
- If on Settings (index 1): Android back switches to Calendar tab (`canPop: false`, `goBranch(0)`).
- **⚠️ DO NOT** add `PopScope`/`WillPopScope` to individual tab pages — it won't work because `StatefulShellRoute` manages the stack.

### Interstitial Ad on Navigation
- An interstitial ad is shown **only** when navigating **to** the Settings tab (index 1) from another tab.
- The ad is triggered in `ScaffoldWithNavBar.onTap`, NOT in the `SettingsPageNew` widget.

---

## State Management

### Pattern: `ChangeNotifier` + `Provider`

| Provider | Class | Scope | Persists? |
|----------|-------|-------|-----------|
| `WorkLog` | `ChangeNotifier` | App-wide | Yes (SharedPreferences) |
| `ThemeProvider` | `ChangeNotifier` | App-wide | Yes (SharedPreferences) |

### WorkLog
- **Location**: `lib/main.dart` (class `WorkLog`)
- **Storage**: `SharedPreferences` via `WorkLogStorage` helper class
- **Serialization**: JSON-encoded `Map<String, int>` (ISO date string → WorkStatus index)
- **Heavy parsing**: Uses `compute()` (isolate) for JSON decode to avoid jank
- **Status cycle**: `none → office → home → leave → none`

### ThemeProvider
- **Location**: `lib/theme_provider.dart`
- **Manages**: `ThemeMode`, `hapticFeedbackEnabled`, `attendanceGoal`
- **Data migration**: If `attendanceGoal > 1.0`, auto-corrects to decimal (legacy %)

### SharedPreferences Keys
| Key | Type | Default | Owner |
|-----|------|---------|-------|
| `workLog` | `String` (JSON) | `null` | `WorkLogStorage` |
| `themeMode` | `int` (ThemeMode index) | `ThemeMode.system.index` | `ThemeProvider` |
| `hapticFeedback` | `bool` | `true` | `ThemeProvider` |
| `attendanceGoal` | `double` | `0.75` | `ThemeProvider` |
| `daily_reminder_enabled` | `bool` | `false` | `SettingsPageNew` |

> **⚠️ DO NOT** reuse or rename these keys without migrating existing user data.

---

## Theming & Design System

### Color Palette
| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| **Primary (seed)** | `#10b981` (emerald green) | `#238636` (GitHub green) |
| **Background** | `#f8fafc` (off-white) | `#0D1117` (GitHub dark) |
| **Surface** | `#FFFFFF` | `#161B22` |
| **Text** | System default | `#C9D1D9` |
| **Office status** | `#10b981` | `Colors.greenAccent` |
| **Home status** | `Colors.blue` | `Colors.lightBlueAccent` |
| **Leave status** | `Colors.amber.shade700` | `Colors.yellowAccent` |

### Typography
- **Font**: `Inter` via `google_fonts`
- **Base theme**: Created ONCE from `GoogleFonts.interTextTheme(ThemeData.light().textTheme)` and shared
- **Dark mode**: Same base theme with `.apply(bodyColor: darkTextColor, displayColor: darkTextColor)`
- **⚠️ DO NOT** call `GoogleFonts.interTextTheme()` separately for light and dark — it produces different font sizes

### Rules
1. Use `Theme.of(context)` to access colors and text styles — never hardcode colors in widgets.
2. For conditional dark mode checks: `Theme.of(context).brightness == Brightness.dark` (NOT `themeProvider.themeMode`).
3. Status colors ARE hardcoded in widgets (not in theme) because they represent data semantics, not UI chrome.

---

## Services

### AdService (`lib/services/ad_service.dart`)
- **Pattern**: Singleton (factory constructor)
- **Ad Types**: Interstitial, Rewarded, Banner
- **Frequency cap**: Interstitial — 2 minute cooldown between shows
- **Retry**: All ad types retry after 30-second delay on load failure
- **Rewarded fallback**: If ad doesn't load within 3 seconds, reward is granted anyway
- **Analytics**: Logs only 3 events to Firebase: `ad_init`, `ad_consent`, `ad_load_fail`
- **Ad IDs**: Resolved via `AdHelper` (debug = test IDs, release = `AdSecrets`)
- **⚠️** `ad_secrets.dart` contains production keys and MUST be gitignored

### NotificationService (`lib/services/notification_service.dart`)
- **Pattern**: Singleton (factory constructor)
- **Schedule mode**: `AndroidScheduleMode.inexactAllowWhileIdle` — no `SCHEDULE_EXACT_ALARM` permission needed
- **Repeat**: `matchDateTimeComponents: DateTimeComponents.time` — fires daily at 10:00 AM
- **Timezone**: Uses `flutter_timezone` v5 `TimezoneInfo.identifier` (NOT `.toString()`)
- **Channel**: `daily_reminder_channel` / ID `888`
- **Boot persistence**: `ScheduledNotificationBootReceiver` in `AndroidManifest.xml`
- **⚠️ DO NOT** add `SCHEDULE_EXACT_ALARM` permission — Play Store will reject without justification

---

## Data Layer

### Local Storage Only
This app uses **SharedPreferences** exclusively. There is no remote database for user data.

| Data | Storage | Serialization |
|------|---------|---------------|
| Work log | SharedPreferences (`workLog` key) | JSON `Map<String, int>` |
| Theme preference | SharedPreferences (`themeMode` key) | `int` (ThemeMode index) |
| Attendance goal | SharedPreferences (`attendanceGoal` key) | `double` (0.0–1.0) |
| Notification toggle | SharedPreferences (`daily_reminder_enabled` key) | `bool` |

### Computation
- Work log JSON parsing uses `compute()` (Dart isolate) to avoid blocking the UI thread.
- Attendance percentage is calculated on-the-fly in `WorkLog.officeAttendancePercentage()`.
- Leave days are excluded from the denominator (working days = weekdays − leave days).

---

## UI Components

| Widget | File | Purpose |
|--------|------|---------|
| `CalendarPage` | `main.dart` | Monthly calendar with status tap, swipe navigation, header |
| `CalendarGrid` | `main.dart` | Grid of day cells with color-coded status indicators |
| `AttendanceCard` | `attendance_card.dart` | Circular progress ring showing % vs goal, with legend |
| `StatusSummary` | `status_summary.dart` | Three cards showing Office/Home/Leave day counts |
| `SettingsPageNew` | `settings_page_new.dart` | All settings: goal slider, export, theme, notifications, about |
| `ScaffoldWithNavBar` | `main.dart` | Shell with BottomNavigationBar + PopScope back handling |
| `BannerAdWidget` | `services/ad_service.dart` | Self-contained banner ad at bottom of settings |
| `LoadingPage` | `loading_page.dart` | Lottie animation splash screen |

### Overflow Safety
All text labels that can vary in length use one of:
- `Flexible` + `TextOverflow.ellipsis`
- `Expanded` + `TextOverflow.ellipsis`
- `Wrap` (for legend items)

---

## Conventions & Rules

### DO ✅
1. **Read this blueprint** before making ANY architectural change.
2. **Update this blueprint** and `CHANGELOG.md` after every significant change.
3. Use `Theme.of(context)` for colors and text styles.
4. Use `debugPrint()` for development logging (stripped in release).
5. Use `developer.log()` for structured diagnostic logging.
6. Wrap new service initializations in try-catch in `main.dart`.
7. Use `const` constructors wherever possible.
8. Test on both Android emulator AND iOS simulator before merging.
9. Pin unstable/breaking dependencies to exact versions.
10. Use `AutomaticKeepAliveClientMixin` for any new tab pages.

### DON'T ❌
1. **Don't add new state management solutions** (no Riverpod, Bloc, GetX) — stick to Provider.
2. **Don't move the GoRouter** out of `_WorkTrackerAppState.initState` — it breaks state preservation.
3. **Don't add PopScope to individual tab pages** — back handling is at `ScaffoldWithNavBar` level.
4. **Don't use `^` prefix for `flutter_local_notifications`** — v21+ has breaking changes.
5. **Don't hardcode colors** — use theme tokens except for semantic status colors.
6. **Don't call `GoogleFonts.interTextTheme()` more than once** — use the shared `baseTextTheme`.
7. **Don't add `SCHEDULE_EXACT_ALARM` permission** — violates Play Store policy for this use case.
8. **Don't put business logic in `build()` methods** — extract to methods or providers.
9. **Don't create new SharedPreferences keys** without documenting them in this blueprint.
10. **Don't use `Navigator.push`** — all navigation goes through `go_router` (`context.go()`, `context.push()`).

---

## Known Gotchas

| Issue | Cause | Resolution |
|-------|-------|------------|
| `flutter_local_notifications` v21+ breaks | Prerelease with all-named-params API | Pinned to `19.5.0` |
| `FlutterTimezone.getLocalTimezone()` returns `TimezoneInfo` | v5 API change | Use `.identifier`, NOT `.toString()` |
| Dark mode text invisible | Separate `GoogleFonts.interTextTheme()` calls produce different sizes | Single shared `baseTextTheme` with `.apply()` |
| Back button exits from Settings | Individual `PopScope` doesn't work in `StatefulShellRoute` | `PopScope` on `ScaffoldWithNavBar` |
| Settings dark mode toggle wrong on first launch | Checking `themeProvider.themeMode` before provider loads | Use `Theme.of(context).brightness` |
| `attendanceGoal` stored as 75.0 instead of 0.75 | Legacy bug | Data migration in `ThemeProvider._loadAttendanceGoal()` |
| Ad not ready when Settings opens | Race condition — ad may still be loading | Retry logic + frequency cap in `AdService` |

---

## Change Protocol

### Before Making Changes
1. Read `blueprint.md` (this file) completely.
2. Read `CHANGELOG.md` for recent change history.
3. Identify which architectural layer your change touches.
4. Check the [Conventions & Rules](#conventions--rules) section for constraints.

### While Making Changes
1. Follow existing patterns — look at how similar features are implemented.
2. Run `flutter analyze lib/` — fix all errors before committing.
3. Test on the Android emulator at minimum.

### After Making Changes
1. Update `CHANGELOG.md` with a dated entry describing what changed.
2. Update this `blueprint.md` if you:
   - Added/removed a dependency
   - Added/changed a SharedPreferences key
   - Changed navigation routes or back-button behavior
   - Added a new service or provider
   - Changed the initialization flow
   - Modified the theming system
   - Added new UI components
3. Increment `version` in `pubspec.yaml` and `versionCode` in `build.gradle.kts`.
4. Commit with a clear, descriptive message.

---

## Current Version

| Field | Value |
|-------|-------|
| **Version** | `1.0.1+7` |
| **Branch** | `ticket-ui-redesign` (branched from `feature/ads`) |
| **Last updated** | 2026-02-20 |
| **Last blueprint update** | 2026-02-20 |
