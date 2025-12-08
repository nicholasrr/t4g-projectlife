import 'package:hive/hive.dart';
import 'hive_boxes.dart';

/// Repository for managing application settings in Hive storage.
class SettingsRepository {
  final Box _settingsBox;

  SettingsRepository() : _settingsBox = Hive.box(settingsBoxName);

  /// Gets whether drag actions should be flipped (left/right meanings swapped).
  bool getDragFlip() {
    return _settingsBox.get(dragFlipKey, defaultValue: false);
  }

  /// Sets whether drag actions should be flipped.
  Future<void> setDragFlip(bool value) async {
    await _settingsBox.put(dragFlipKey, value);
  }

  /// Gets the current sort mode for tasks.
  /// Defaults to 'category_asc' if no sort mode has been set.
  String getSortMode() {
    return _settingsBox.get(sortModeKey, defaultValue: 'category_asc');
  }

  /// Sets the sort mode for tasks.
  Future<void> setSortMode(String mode) async {
    await _settingsBox.put(sortModeKey, mode);
  }

  /// Gets the last selected time period ID.
  /// Returns null if no period has been selected yet.
  String? getSelectedTimeCadence() {
    return _settingsBox.get(selectedTimeCadence);
  }

  /// Sets the currently selected time period ID.
  Future<void> setSelectedCadence(String cadence) async {
    await _settingsBox.put(selectedTimeCadence, cadence);
  }

  /// Clears all settings and resets to defaults.
  Future<void> resetToDefaults() async {
    await Future.wait([
      _settingsBox.delete(dragFlipKey),
      _settingsBox.delete(sortModeKey),
      _settingsBox.delete(selectedTimeCadence),
    ]);
  }

  /// Gets the current theme mode ('light', 'dark', or 'system').
  String getThemeMode() {
    return _settingsBox.get(themeModeKey, defaultValue: 'system');
  }

  /// Sets the theme mode ('light', 'dark', or 'system').
  Future<void> setThemeMode(String mode) async {
    assert(mode == 'light' || mode == 'dark' || mode == 'system');
    await _settingsBox.put(themeModeKey, mode);
  }

  /// Gets all settings as a Map for debugging or export.
  Map<String, dynamic> getAllSettings() {
    return {
      dragFlipKey: getDragFlip(),
      sortModeKey: getSortMode(),
      selectedTimeCadence: getSelectedTimeCadence(),
      themeModeKey: getThemeMode(),
    };
  }
}
