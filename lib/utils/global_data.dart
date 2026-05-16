import 'package:flutter/foundation.dart';

enum SelectedType { all, recurring, adhoc, statistics, howto }

class Globals {
  bool isDarkMode = false;
  String language = 'en';
  static final ValueNotifier<SelectedType> selectedTypeNotifier =
      ValueNotifier<SelectedType>(SelectedType.recurring);
  // Simple version counter to notify that tasks changed (create/edit/delete)
  static final ValueNotifier<int> tasksVersion = ValueNotifier<int>(0);
  static final ValueNotifier<int> notificationsVersion = ValueNotifier<int>(0);
  // Selected category ids for filtering (empty = no filter)
  static final ValueNotifier<Set<String>> selectedCategoryIds =
      ValueNotifier<Set<String>>(<String>{});

  // Special key used to represent the 'Uncategorized' filter
  static const String uncategorizedKey = '__UNCATEGORIZED__';

  static setAll() {
    selectedTypeNotifier.value = SelectedType.all;
    tasksVersion.value++;
  }

  static setRecurring() {
    selectedTypeNotifier.value = SelectedType.recurring;
    tasksVersion.value++;
  }

  static setAdHoc() {
    selectedTypeNotifier.value = SelectedType.adhoc;
    tasksVersion.value++;
  }

  static setStatistics() {
    selectedTypeNotifier.value = SelectedType.statistics;
    tasksVersion.value++;
  }

  static setHowTo() {
    selectedTypeNotifier.value = SelectedType.howto;
    tasksVersion.value++;
  }

  static void setSelectedCategories(Set<String> ids) {
    selectedCategoryIds.value = Set.from(ids);
    // bump tasksVersion so UI that only listens to tasksVersion refreshes too
    tasksVersion.value++;
  }
}
