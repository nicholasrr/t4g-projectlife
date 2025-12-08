import 'dart:developer';
import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../models/task.dart';

var _random = math.Random(DateTime.now().millisecondsSinceEpoch);

/////////////////////////
// Time period parsing //
/////////////////////////
String _getDayId(DateTime date) {
  return 'D#${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _getWeekId(DateTime date) {
  // Find the previous Sunday
  while (date.weekday != DateTime.sunday) {
    date = date.subtract(const Duration(days: 1));
  }
  return 'W#${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _getMonthId(DateTime date) {
  return 'M#${date.year}-${date.month.toString().padLeft(2, '0')}';
}

String _getQuarterId(DateTime date) {
  final quarter = (date.month + 2) ~/ 3;
  return 'Q#${date.year}-$quarter';
}

String _getYearId(DateTime date) {
  return 'Y#${date.year}';
}

DateTime _parseDay(String periodId) {
  final parts = periodId.split('#')[1].split('-');
  // We add 12 hours to avoid timezone/DST issues that might shift the date
  return DateTime(
    int.parse(parts[0]), // year
    int.parse(parts[1]), // month
    int.parse(parts[2]), // day
  ).add(const Duration(hours: 12));
}

DateTime _parseWeek(String periodId) {
  final parts = periodId.split('#')[1].split('-');
  // We add 12 hours to avoid timezone/DST issues that might shift the date
  return DateTime(
    int.parse(parts[0]), // year
    int.parse(parts[1]), // month
    int.parse(parts[2]), // day (start of week)
  ).add(const Duration(hours: 12));
}

DateTime _parseMonth(String periodId) {
  final parts = periodId.split('#')[1].split('-');
  // We add 12 hours to avoid timezone/DST issues that might shift the date
  return DateTime(
    int.parse(parts[0]), // year
    int.parse(parts[1]), // month
  ).add(const Duration(hours: 12));
}

DateTime _parseQuarter(String periodId) {
  final parts = periodId.split('#')[1].split('-');
  final quarter = int.parse(parts[1]);
  // We add 12 hours to avoid timezone/DST issues that might shift the date
  return DateTime(
    int.parse(parts[0]), // year
    (quarter - 1) * 3 + 1, // first month of quarter
  ).add(const Duration(hours: 12));
}

DateTime _parseYear(String periodId) {
  final parts = periodId.split('#')[1];
  // We add 12 hours to avoid timezone/DST issues that might shift the date
  return DateTime(
    int.parse(parts), // year
  ).add(const Duration(hours: 12));
}

String _getTimePeriodId(DateTime date, String cadence) {
  return switch (cadence) {
    'D' => _getDayId(date),
    'W' => _getWeekId(date),
    'M' => _getMonthId(date),
    'Q' => _getQuarterId(date),
    'Y' => _getYearId(date),
    _ => _getDayId(date),
  };
}

DateTime _parseTimePeriodId(String periodId) {
  return switch (periodId[0]) {
    'D' => _parseDay(periodId),
    'W' => _parseWeek(periodId),
    'M' => _parseMonth(periodId),
    'Q' => _parseQuarter(periodId),
    'Y' => _parseYear(periodId),
    _ => DateTime.now(),
  };
}

////////////////////////////
// Date time manipulation //
////////////////////////////
DateTime _getPreviousDay(DateTime date) {
  return date.subtract(const Duration(days: 1));
}

DateTime _getPreviousWeek(DateTime date) {
  return date.subtract(const Duration(days: 7));
}

DateTime _getPreviousMonth(DateTime date) {
  var year = date.year;
  var month = date.month - 1;
  if (month < 1) {
    year--;
    month = 12;
  }
  return DateTime(year, month);
}

DateTime _getPreviousQuarter(DateTime date) {
  var year = date.year;
  var quarter = (date.month + 2) ~/ 3;
  var previousQuarter = quarter - 1;
  if (previousQuarter < 1) {
    year--;
    previousQuarter = 4;
  }
  return DateTime(year, (previousQuarter - 1) * 3 + 1);
}

DateTime _getPreviousYear(DateTime date) {
  return DateTime(date.year - 1);
}

DateTime _getNextDay(DateTime date) {
  return date.add(const Duration(days: 1));
}

DateTime _getNextWeek(DateTime date) {
  return date.add(const Duration(days: 7));
}

DateTime _getNextMonth(DateTime date) {
  var year = date.year;
  var month = date.month + 1;
  if (month > 12) {
    year++;
    month = 1;
  }
  return DateTime(year, month);
}

DateTime _getNextQuarter(DateTime date) {
  var year = date.year;
  var quarter = (date.month + 2) ~/ 3;
  var nextQuarter = quarter + 1;
  if (nextQuarter > 4) {
    year++;
    nextQuarter = 1;
  }
  return DateTime(year, (nextQuarter - 1) * 3 + 1);
}

DateTime _getNextYear(DateTime date) {
  return DateTime(date.year + 1);
}

DateTime _getPreviousTimePeriod(DateTime date, String cadence) {
  return switch (cadence) {
    'D' => _getPreviousDay(date),
    'W' => _getPreviousWeek(date),
    'M' => _getPreviousMonth(date),
    'Q' => _getPreviousQuarter(date),
    'Y' => _getPreviousYear(date),
    _ => DateTime.now(),
  };
}

DateTime _getNextTimePeriod(DateTime date, String cadence) {
  return switch (cadence) {
    'D' => _getNextDay(date),
    'W' => _getNextWeek(date),
    'M' => _getNextMonth(date),
    'Q' => _getNextQuarter(date),
    'Y' => _getNextYear(date),
    _ => DateTime.now(),
  };
}

///////////////////////////////////////
// Time operations with only strings //
///////////////////////////////////////
String getPreviousTimePeriodId(String periodId) {
  final date = _parseTimePeriodId(periodId);
  final cadence = periodId[0];
  DateTime previousTimePeriod = _getPreviousTimePeriod(date, cadence);
  log('Previous time period date: $previousTimePeriod');
  final ret = _getTimePeriodId(previousTimePeriod, cadence);
  log('Previous time period id: $ret');
  return ret;
}

String getNextTimePeriodId(String periodId) {
  final date = _parseTimePeriodId(periodId);
  final cadence = periodId[0];
  DateTime nextTimePeriod = _getNextTimePeriod(date, cadence);
  log('Next time period date: $nextTimePeriod');
  final ret = _getTimePeriodId(nextTimePeriod, cadence);
  log('Next time period id: $ret');
  return ret;
}

String getCurrentTimePeriodId(String cadence) {
  final now = DateTime.now();
  return _getTimePeriodId(now, cadence);
}

String extractCadence(String periodId) {
  return periodId[0];
}

////////////////////////////
// Period display strings //
////////////////////////////
String _getDayDisplayString(DateTime date) {
  final formatter = DateFormat('MMM d, yyyy');
  return formatter.format(date);
}

String _getWeekDisplayString(DateTime date) {
  final formatter = DateFormat('MMM d');
  final weekEndDate = date.add(const Duration(days: 6));
  return '${formatter.format(date)} - ${formatter.format(weekEndDate)}';
}

String _getMonthDisplayString(DateTime date) {
  final formatter = DateFormat('MMM yyyy');
  return formatter.format(date);
}

String _getQuarterDisplayString(DateTime date) {
  final quarter = ((date.month - 1) ~/ 3) + 1;
  final yearQuarter = 'Q$quarter ${date.year}';
  final monthStart = DateFormat(
    'MMM',
  ).format(DateTime(date.year, (quarter - 1) * 3 + 1));
  final monthEnd = DateFormat('MMM').format(DateTime(date.year, quarter * 3));
  return '$yearQuarter ($monthStart—$monthEnd)';
}

String _getYearDisplayString(DateTime date) {
  return date.year.toString();
}

String getPeriodDisplayString(String periodId) {
  final date = _parseTimePeriodId(periodId);
  switch (extractCadence(periodId)) {
    case 'D':
      return _getDayDisplayString(date);
    case 'W':
      return _getWeekDisplayString(date);
    case 'M':
      return _getMonthDisplayString(date);
    case 'Q':
      return _getQuarterDisplayString(date);
    case 'Y':
      return _getYearDisplayString(date);
    default:
      return '';
  }
}

bool shouldBackfillPeriod(String periodId) {
  // Simple heuristic: backfill if the period date is after 2025
  // A better solution might be storing the first app use date
  final date = _parseTimePeriodId(periodId);
  return date.isAfter(DateTime(2025));
}

bool isBComparableAndGreaterThanA(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a[0] != b[0]) return false;
  final dateA = _parseTimePeriodId(a);
  final dateB = _parseTimePeriodId(b);
  return dateB.isAfter(dateA);
}

String generateTaskId(String timePeriodId) {
  return '${generateId()}_$timePeriodId';
}

String generateId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(
    12,
    (index) => chars[_random.nextInt(chars.length)],
  ).join();
}

Task portTaskToPeriod(Task task, String newPeriodId) {
  final newTaskId = generateTaskId(newPeriodId);

  // For recurring tasks, reset currentCount to 0
  // For ad-hoc tasks, preserve the currentCount
  final newCurrentCount = task.isRecurring ? 0 : task.currentCount;

  return task.copyWith(
    id: newTaskId,
    timePeriodId: newPeriodId,
    completed: false,
    currentCount: newCurrentCount,
  );
}
