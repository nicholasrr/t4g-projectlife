# projectlife

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


#### App description

This is an app called "Project: Life". The idea is to manage life tasks as in a project, objectively, categorizing them and enabling both "recurring tasks" and "ad-hoc" tasks. It's supposed to be very simple, almost everything should be do-able in the home-screen. So there are a few requirements, I will explain the vertical display, from bottom to top as it will make more sense:

- On the bottom, we have the cadence/deadline of the tasks: Day (D), Week (W), Month (M), Quarter (Q), Year (Y). Selecting a cadence shows the created tasks for that cadence.

- Right above it, there are three buttons: Recurring (an icon of two circular arrows pointing at each other), Ad-hoc (an icon of a checkmark) and How to use (a question mark icon). Selecting recurring or ad-hoc will show the respective tasks; selecting the how to use will expand the text of the buttons (For cadence, it will expand from the initial to the full cadence name, and for the icons, it will show the names below the icons (Recurring, Ad-hoc, How to use).

- Above that, are the tasks itself. There should be a fixed button on the bottom to add new tasks; and there should be a scrollable list with the tasks. Each task should have a background box, much like a kanban board. Adding a task should be as simple as typing it and seeing the new text already inside the box. Then, opening the task will expand the box and allow the user to type more details about the task, as well as select a category for it, or create a new category.

- On the top right corner, there should be a filter button which enables filtering by category or sorting. Categories are defined by the user when creating or editing an item, These should be persisted so that when the user re-opens the app, the sorting mode is kept.

- On the top middle, there should be a time period indicative that the user can navigate. For example, if it's a week, it should say the week number and span (Wk 1 - Jan 1st - Jan 7th). The weeks should always start on Sunday; Months should always start on the 1st of the Month; Quarters start on Jan 1st, April 1st, July 1st and October 1st. And Years start on Jan 1st.

- On the top left, there should be an engine with a settings button.

Now, there are a few nuances of the app:

- Much like an email app, dragging a task to the left should show up a trash icon in red background, and then pop-up a confirmation to delete the task. If the user confirms, the task is deleted from the board. Dragging left should show a checkmark button in green background to mark it as completed. When the task is marked as completed, it should animate towards the bottom of the list (not actually scrolling to the bottom of the list, but just animating) with the other items animating to the top. There should be a setting to flip the dragging left/dragging right actions.

- The items should be draggable to different cadences, like from daily to weekly, and to future time periods.

- Let's use Hive as a DB. We will store the selected time period; if the user moves to the future, we will store the new time period on the DB. So when the user moves the task to a future time period, it will be stored successfully.

- Let's say the user opens the app on time period X. And then the user stops using the app and opens again on time period X+3. (+3 weeks, +3 days, +3 months, etc). So, we will show the current date and time period. We should backfill the previous time periods. It's simple: for time period X+1, all the recurring tasks from X should be ported automatically to X+1, and marked as incomplete. All the non-recurring tasks from X which are incomplete, are also ported; the complete ad-hoc tasks stay where they are. We should then mark X+1 as backfilled on the DB and continue the process for X+2, X+3, ... X+N, until we reach the current time period. When the user changes the selection, e.g. from daily tasks to weekly tasks, we will do the same process. In that way, we preserve all of the tasks and carry them over, not losing anything.

- The DB/Object structure will be simple:
1. each time period will be uniquely identifiable. For example, Day will be D#2025-10-25. Week will be W#2025-10-19. Month will be M#2025-10 . Quarter will be Q#2025-4 . And Year will be Y#2025.
2. The tasks will be "Title", "Description", "Category", "Completed". 
3. The categories will have a title and a color, selectable by the user when creating an item of that category. The items of a category will have a background of that color, and complete items will have a slight opaque box with a checkmark at the top right corner.
4. The settings and filter will be a bunch of feature flags.
5. There will be boxes for each time cadence, one box for categories and another for settings. The box of each time cadence will contain the tasks for each time period.

I think this is a good description of the goals. I know this is a lot, so let's take this little by little. First, please add all of this to the copilot instructions, in details, so that it doesn't get lost.

## Development Commands

### Dependencies
```powershell
# Install/update dependencies
flutter pub get

# Check for outdated packages
flutter pub outdated

# Upgrade dependencies (respecting constraints)
flutter pub upgrade
```

### Code Generation
```powershell
# Regenerate Hive models and adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (regenerates automatically on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Running & Testing
```powershell
# List available devices
flutter devices

# Run in debug mode (default)
flutter run

# Run on specific device
flutter run -d <device-id>

# Run tests
flutter test

# Run with specific Flutter version
flutter --version
```

### Building
```powershell
# Build APK for debug
flutter build apk --debug

# Build APK for release
flutter build apk --release

# Build Android App Bundle (AAB) for Play Store
flutter build appbundle --release

# Build for other platforms
flutter build ios --release
flutter build web --release
flutter build windows --release
```

### Formatting & Analysis
```powershell
# Format all Dart files
dart format .

# Run static analysis
flutter analyze

# Fix common issues automatically
dart fix --apply
```

### Clean & Reset
```powershell
# Clean build artifacts
flutter clean

# Clean and reinstall dependencies
flutter clean; flutter pub get
```

### Release Workflow
```powershell
# 1. Update version in pubspec.yaml
# 2. Regenerate models if needed
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run tests
flutter test

# 4. Build signed AAB
flutter build appbundle --release

# Output: build\app\outputs\bundle\release\app-release.aab
```