import 'package:flutter/foundation.dart';

enum SelectedType { recurring, adhoc, howto }

class Globals {
  bool isDarkMode = false;
  String language = 'en';
  static SelectedType selectedType = SelectedType.recurring;
  static final ValueNotifier<bool> isHowTo = ValueNotifier<bool>(false);

  static setRecurring() {
    selectedType = SelectedType.recurring;
    isHowTo.value = false;
  }

  static setAdHoc() {
    selectedType = SelectedType.adhoc;
    isHowTo.value = false;
  }

  static setHowTo() {
    selectedType = SelectedType.howto;
    isHowTo.value = true;
  }
}
