import 'package:flutter/foundation.dart';

enum SelectedType { recurring, adhoc, howto }

class Globals {
  bool isDarkMode = false;
  String language = 'en';
  static final ValueNotifier<SelectedType> selectedTypeNotifier =
      ValueNotifier<SelectedType>(SelectedType.recurring);
  // Simple version counter to notify that tasks changed (create/edit/delete)
  static final ValueNotifier<int> tasksVersion = ValueNotifier<int>(0);
  // Selected category ids for filtering (empty = no filter)
  static final ValueNotifier<Set<String>> selectedCategoryIds =
      ValueNotifier<Set<String>>(<String>{});

  static setRecurring() {
    selectedTypeNotifier.value = SelectedType.recurring;
  }

  static setAdHoc() {
    selectedTypeNotifier.value = SelectedType.adhoc;
  }

  static setHowTo() {
    selectedTypeNotifier.value = SelectedType.howto;
  }

  static void setSelectedCategories(Set<String> ids) {
    selectedCategoryIds.value = Set.from(ids);
    // bump tasksVersion so UI that only listens to tasksVersion refreshes too
    tasksVersion.value++;
  }
}
