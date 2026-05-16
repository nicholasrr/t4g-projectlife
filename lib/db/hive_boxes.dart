import 'package:hive_flutter/hive_flutter.dart';

// Type IDs used in Hive TypeAdapters
const taskTypeId = 1;
const categoryTypeId = 2;
const timePeriodTypeId = 3;

// Box names used throughout the app
const tasksBoxName = 'tasks';
const taskIndexBoxName = 'taskIndex'; // Maps time periods to task IDs
const categoriesBoxName = 'categories';
const timePeriodsBoxName = 'timePeriods';
const notificationRulesBoxName = 'notificationRules';
const settingsBoxName = 'settings';

// Settings keys
const dragFlipKey = 'dragFlip';
const sortModeKey = 'sortMode';
const selectedTimeCadence = 'selectedTimeCadence';
const themeModeKey = 'themeMode';

/// Opens all Hive boxes needed by the app.
Future<void> openHiveBoxes() async {
  await Future.wait([
    Hive.openBox(tasksBoxName),
    Hive.openBox(taskIndexBoxName),
    Hive.openBox(categoriesBoxName),
    Hive.openBox(timePeriodsBoxName),
    Hive.openBox(notificationRulesBoxName),
    Hive.openBox(settingsBoxName),
  ]);
}
