import 'package:hive/hive.dart';
import '../models/time_period.dart';
import 'hive_boxes.dart';

/// Repository for managing time periods in Hive storage.
class TimePeriodRepository {
  final Box _timePeriodsBox;

  TimePeriodRepository() : _timePeriodsBox = Hive.box(timePeriodsBoxName);

  /// Gets or creates a time period.
  Future<TimePeriod> getOrCreateTimePeriod(String id) async {
    var period = _timePeriodsBox.get(id) as TimePeriod?;

    if (period == null) {
      period = TimePeriod(id: id, backfilled: false, createdAt: DateTime.now());
      await _timePeriodsBox.put(id, period);
    }

    return period;
  }

  /// Marks a time period as backfilled.
  Future<void> markAsBackfilled(String id) async {
    final period = await getOrCreateTimePeriod(id);
    period.backfilled = true;
    await _timePeriodsBox.put(id, period);
  }

  /// Checks if a time period has been backfilled.
  bool isBackfilled(String id) {
    final period = _timePeriodsBox.get(id) as TimePeriod?;
    return period?.backfilled ?? false;
  }

  /// Gets all time periods that have been created.
  List<TimePeriod> getAllTimePeriods() {
    return _timePeriodsBox.values.cast<TimePeriod>().toList();
  }

  /// Gets time periods between two IDs inclusively.
  /// Useful for backfill operations to find periods that need processing.
  List<TimePeriod> getTimePeriodsBetween(String startId, String endId) {
    // This implementation assumes IDs are comparable strings
    // (which they are given our format D#YYYY-MM-DD etc.)
    return _timePeriodsBox.values
        .cast<TimePeriod>()
        .where(
          (p) => p.id.compareTo(startId) >= 0 && p.id.compareTo(endId) <= 0,
        )
        .toList();
  }

  /// Gets the last accessed time period for a given cadence.
  /// Used to determine backfill needs when opening the app.
  String? getLastAccessedPeriod(String cadence) {
    final periods =
        getAllTimePeriods().where((p) => p.id.startsWith('$cadence#')).toList();

    if (periods.isEmpty) return null;

    // Sort by createdAt and return the most recent
    periods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return periods.first.id;
  }

  /// Deletes a time period.
  /// Should only be used for cleanup - normal operation should preserve all periods.
  Future<void> deleteTimePeriod(String id) async {
    await _timePeriodsBox.delete(id);
  }

  /// Resets all time periods' backfill flags to false.
  /// This will trigger a full backfill on the next app initialization.
  /// Useful for debugging or manual backfill reset.
  Future<void> resetAllBackfillFlags() async {
    final periods = getAllTimePeriods();
    for (final period in periods) {
      period.backfilled = false;
      await _timePeriodsBox.put(period.id, period);
    }
  }
}
