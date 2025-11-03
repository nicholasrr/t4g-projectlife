# AI Agent Instructions for Project: Life (copilot guidance)

## Quick summary
Project: Life is a small, multi-platform Flutter app (starter counter currently at `lib/main.dart`) whose UI centers on a single home screen that shows tasks grouped by cadence (Day/Week/Month/Quarter/Year). This file documents the app-specific UX rules, data model, persistence, and developer workflows so an AI agent can be immediately productive.

## Where to start (key files)
- `lib/main.dart` — current app entry (simple stub). Real logic and widgets will live under `lib/` as features are added.
- `pubspec.yaml` — Flutter SDK constraint (^3.7.2) and dependencies.
- `test/` — widget tests (use `flutter test`).

## UI: vertical layout (bottom → top)
- Bottom: cadence selector (single-letter: D, W, M, Q, Y). Selecting a cadence shows tasks for that cadence and the selected time period.
- Above cadence: 3 icon buttons — Recurring (two arrows), Ad-hoc (checkmark), How-to (?). Tapping How-to expands short labels under icons; tapping cadence expands initials to full names.
- Middle: tasks list (scrollable). Fixed bottom FAB to add tasks. Tasks render as colored boxes (category color). Tapping expands the box for details, description and category selection/creation.
- Above tasks (top-middle): time-period navigator text (e.g. `Wk 1 — Jan 1 — Jan 7`). Weeks start on Sunday. Months start on the 1st. Quarters start 1/Jan, 1/Apr, 1/Jul, 1/Oct. Years start 1/Jan.
- Top-right: filter/sort button (persist chosen sorting mode).
- Top-left: engine + settings button (feature flags).

## Gesture & animation rules
- Swipe left/right on a task reveals actions (like email apps): trash (red) and complete (green). Confirm delete with a dialog before removing.
- Completion animation: when marked complete, the task animates toward the bottom of the visible list while remaining in the same list (other items animate upward). There is a setting to flip left/right meanings.
- Tasks are draggable between cadences and into future time-periods (drag-to target cadence/time period). Dropping updates storage immediately.

## Persistence & Hive schema (recommended)
Use Hive for local storage. Suggested box names and shapes:
- Box `timePeriods` — stores metadata about time periods and which periods were backfilled. Key = timePeriodId (see format below); value = { backfilled: bool, createdAt: DateTime }
- Box `tasks` — key = generated id (UUID or int); value = {
    id, title, description, categoryId, completed: bool, cadence: 'D'|'W'|'M'|'Q'|'Y', timePeriodId
  }
- Box `categories` — key = categoryId; value = { id, title, colorHex }
- Box `settings` — key-value for feature flags (dragFlip, sortMode, selectedTimePeriodId, ...)

Example timePeriodId formats (canonical):
- Day: `D#YYYY-MM-DD` (e.g. `D#2025-10-25`)
- Week: `W#YYYY-MM-DD` where date is the Sunday starting that week (e.g. `W#2025-10-19`)
- Month: `M#YYYY-MM`
- Quarter: `Q#YYYY-Q` where Q is 1..4 (e.g. `Q#2025-4` for Oct–Dec)
- Year: `Y#YYYY`

## Backfill algorithm (critical, deterministic rules)
When opening the app for cadence C and selected period P_current: if stored last-opened period P_last < P_current, run backfill for each intermediate period P_i = P_last+1 .. P_current:
1. For each recurring task in P_i-1: copy/port to P_i as incomplete.
2. For each ad-hoc task in P_i-1 that is incomplete: port to P_i as incomplete.
3. Completed ad-hoc tasks remain in the period where they were completed (do not port).
4. Mark P_i as backfilled in `timePeriods` box to avoid duplicate work.

Notes: When user explicitly changes cadence (e.g., D → W), run the same backfill flow in the selected cadence domain.

## Data model notes / UX expectations
- Task minimal shape: { title (string), description (string, optional), categoryId (nullable), completed (bool), cadence, timePeriodId }
- Category: { id, title, colorHex } — category colors are used as the background for task boxes; completed tasks render with opacity and a top-right checkmark.
- Creating a task: inline editor on the home screen — typing should create the task immediately in the visible period (optimistic update) and persist to Hive.

## Feature flags / settings
- `dragFlip` — flip left/right action meanings.
- `sortMode` — persist sorting choice (e.g. manual order, alphabetical, by category).
- `selectedTimePeriodId` — persist last selected time period for quick resume.

## Developer commands and testing
Use the Flutter toolchain in this repo:
```powershell
flutter pub get
flutter run   # debug on attached device or emulator
flutter test
flutter build apk   # build for Android
```

## Conventions specific to this repo
- UI is single-screen first: prefer implementing features inside `home` widgets rather than multiple routes unless necessary.
- Favor simple `setState` for local widget state. Persisted state (tasks/categories/settings) must go through Hive boxes.
- Keep time calculations timezone-aware and deterministic: weeks start Sunday, use local date for period boundaries.

## Key places to edit / extend
- Add domain code under `lib/` (e.g. `lib/models/`, `lib/db/`, `lib/widgets/`, `lib/screens/home.dart`).
- Implement Hive adapters under `lib/db/` and register them at app startup before `runApp()`.

## Questions for reviewers (when ambiguous)
- Should dragging to future time periods create a copy or move the task? (Spec assumes move.)
- Preferred ID format for tasks (UUID vs incremental int)?

Add or update this file when app behavior changes. After edits, run `flutter test` to validate widget logic you change.
```````instructions
# AI Agent Instructions for Project: Life (copilot guidance)

## Quick summary
Project: Life is a small, multi-platform Flutter app (starter counter currently at `lib/main.dart`) whose UI centers on a single home screen that shows tasks grouped by cadence (Day/Week/Month/Quarter/Year). This file documents the app-specific UX rules, data model, persistence, and developer workflows so an AI agent can be immediately productive.

## Where to start (key files)
- `lib/main.dart` — current app entry (simple stub). Real logic and widgets will live under `lib/` as features are added.
- `pubspec.yaml` — Flutter SDK constraint (^3.7.2) and dependencies.
- `test/` — widget tests (use `flutter test`).

## UI: vertical layout (bottom → top)
- Bottom: cadence selector (single-letter: D, W, M, Q, Y). Selecting a cadence shows tasks for that cadence and the selected time period.
- Above cadence: 3 icon buttons — Recurring (two arrows), Ad-hoc (checkmark), How-to (?). Tapping How-to expands short labels under icons; tapping cadence expands initials to full names.
- Middle: tasks list (scrollable). Fixed bottom FAB to add tasks. Tasks render as colored boxes (category color). Tapping expands the box for details, description and category selection/creation.
- Above tasks (top-middle): time-period navigator text (e.g. `Wk 1 — Jan 1 — Jan 7`). Weeks start on Sunday. Months start on the 1st. Quarters start 1/Jan, 1/Apr, 1/Jul, 1/Oct. Years start 1/Jan.
- Top-right: filter/sort button (persist chosen sorting mode).
- Top-left: engine + settings button (feature flags).

## Gesture & animation rules
- Swipe left/right on a task reveals actions (like email apps): trash (red) and complete (green). Confirm delete with a dialog before removing.
- Completion animation: when marked complete, the task animates toward the bottom of the visible list while remaining in the same list (other items animate upward). There is a setting to flip left/right meanings.
- Tasks are draggable between cadences and into future time-periods (drag-to target cadence/time period). Dropping updates storage immediately.

## Persistence & Hive schema (recommended)
Use Hive for local storage. Suggested box names and shapes:
- Box `timePeriods` — stores metadata about time periods and which periods were backfilled. Key = timePeriodId (see format below); value = { backfilled: bool, createdAt: DateTime }
- Box `tasks` — key = generated id (UUID or int); value = {
    id, title, description, categoryId, completed: bool, cadence: 'D'|'W'|'M'|'Q'|'Y', timePeriodId
  }
- Box `categories` — key = categoryId; value = { id, title, colorHex }
- Box `settings` — key-value for feature flags (dragFlip, sortMode, selectedTimePeriodId, ...)

Example timePeriodId formats (canonical):
- Day: `D#YYYY-MM-DD` (e.g. `D#2025-10-25`)
- Week: `W#YYYY-MM-DD` where date is the Sunday starting that week (e.g. `W#2025-10-19`)
- Month: `M#YYYY-MM`
- Quarter: `Q#YYYY-Q` where Q is 1..4 (e.g. `Q#2025-4` for Oct–Dec)
- Year: `Y#YYYY`

## Backfill algorithm (critical, deterministic rules)
When opening the app for cadence C and selected period P_current: if stored last-opened period P_last < P_current, run backfill for each intermediate period P_i = P_last+1 .. P_current:
1. For each recurring task in P_i-1: copy/port to P_i as incomplete.
2. For each ad-hoc task in P_i-1 that is incomplete: port to P_i as incomplete.
3. Completed ad-hoc tasks remain in the period where they were completed (do not port).
4. Mark P_i as backfilled in `timePeriods` box to avoid duplicate work.

Notes: When user explicitly changes cadence (e.g., D → W), run the same backfill flow in the selected cadence domain.

## Data model notes / UX expectations
- Task minimal shape: { title (string), description (string, optional), categoryId (nullable), completed (bool), cadence, timePeriodId }
- Category: { id, title, colorHex } — category colors are used as the background for task boxes; completed tasks render with opacity and a top-right checkmark.
- Creating a task: inline editor on the home screen — typing should create the task immediately in the visible period (optimistic update) and persist to Hive.

## Feature flags / settings
- `dragFlip` — flip left/right action meanings.
- `sortMode` — persist sorting choice (e.g. manual order, alphabetical, by category).
- `selectedTimePeriodId` — persist last selected time period for quick resume.

## Developer commands and testing
Use the Flutter toolchain in this repo:
```powershell
flutter pub get
flutter run   # debug on attached device or emulator
flutter test
flutter build apk   # build for Android
```

## Conventions specific to this repo
- UI is single-screen first: prefer implementing features inside `home` widgets rather than multiple routes unless necessary.
- Favor simple `setState` for local widget state. Persisted state (tasks/categories/settings) must go through Hive boxes.
- Keep time calculations timezone-aware and deterministic: weeks start Sunday, use local date for period boundaries.

## Key places to edit / extend
- Add domain code under `lib/` (e.g. `lib/models/`, `lib/db/`, `lib/widgets/`, `lib/screens/home.dart`).
- Implement Hive adapters under `lib/db/` and register them at app startup before `runApp()`.

## Questions for reviewers (when ambiguous)
- Should dragging to future time periods create a copy or move the task? (Spec assumes move.)
- Preferred ID format for tasks (UUID vs incremental int)?

Add or update this file when app behavior changes. After edits, run `flutter test` to validate widget logic you change.
````# AI Agent Instructions for Project Life

## Project Overview
This is a Flutter-based mobile application targeting multiple platforms (iOS, Android, Web, Desktop). The project follows standard Flutter architecture patterns with stateful and stateless widgets.

## Key Architecture Components
- Entry point: `lib/main.dart` - Contains the root application widget and theme configuration
- Platform-specific code:
  - `android/` - Android platform configuration and native code
  - `ios/` - iOS platform configuration and native code
  - `web/` - Web platform assets and configuration
  - `windows/`, `linux/`, `macos/` - Desktop platform configurations

## Development Workflow
1. Development Commands:
   ```bash
   flutter pub get        # Install dependencies
   flutter run           # Run app in debug mode
   flutter build [platform] # Build for specific platform
   ```
2. Hot Reload: Save changes or press 'r' in terminal to hot reload while app is running
3. Hot Restart: Press 'R' in terminal to perform a hot restart if state reset is needed

## Project Conventions
1. State Management:
   - Using Flutter's built-in `setState` for simple state management
   - Widgets are split into Stateful (`StatefulWidget`) and Stateless (`StatelessWidget`) based on state needs

2. Widget Structure:
   - Follow composition pattern with small, focused widgets
   - Each stateful widget has a corresponding State class (e.g., `MyHomePage` → `_MyHomePageState`)

3. Asset Management:
   - Assets should be declared in `pubspec.yaml` under the `flutter:` section
   - Platform-specific assets go in respective platform folders

## Testing
- Widget tests go in the `test/` directory
- Use `flutter test` to run tests
- Example test file: `test/widget_test.dart`

## Dependencies
- Flutter SDK ^3.7.2
- Core dependencies are defined in `pubspec.yaml`
- Platform-specific dependencies in respective platform configuration files