import 'package:flutter/foundation.dart';

enum SelectedType { recurring, adhoc, howto }

class Globals {
  bool isDarkMode = false;
  String language = 'en';
  static final ValueNotifier<SelectedType> selectedTypeNotifier =
      ValueNotifier<SelectedType>(SelectedType.recurring);
  // Simple version counter to notify that tasks changed (create/edit/delete)
  static final ValueNotifier<int> tasksVersion = ValueNotifier<int>(0);

  static setRecurring() {
    selectedTypeNotifier.value = SelectedType.recurring;
  }

  static setAdHoc() {
    selectedTypeNotifier.value = SelectedType.adhoc;
  }

  static setHowTo() {
    selectedTypeNotifier.value = SelectedType.howto;
  }
}
