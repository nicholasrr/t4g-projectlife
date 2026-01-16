import '../models/task.dart';
import '../models/task_statistics.dart';

/// Service to calculate task statistics for a given time period
class StatisticsService {
  /// Gets all time periods with smaller granularity that overlap with the given period
  /// For example, if period is month, returns all days and weeks within that month
  List<String> getOverlappingPeriods(String periodId) {
    final cadence = periodId[0];
    final periods = <String>[];

    switch (cadence) {
      case 'Y': // Year -> get all quarters, months, weeks, days
        periods.addAll(_getMonthsInYear(periodId));
        periods.addAll(_getWeeksInYear(periodId));
        periods.addAll(_getDaysInYear(periodId));
        break;
      case 'Q': // Quarter -> get all months, weeks, days
        periods.addAll(_getMonthsInQuarter(periodId));
        periods.addAll(_getWeeksInQuarter(periodId));
        periods.addAll(_getDaysInQuarter(periodId));
        break;
      case 'M': // Month -> get all weeks, days
        periods.addAll(_getWeeksInMonth(periodId));
        periods.addAll(_getDaysInMonth(periodId));
        break;
      case 'W': // Week -> get all days
        periods.addAll(_getDaysInWeek(periodId));
        break;
      case 'D': // Day -> no smaller granularity
        break;
    }

    return periods;
  }

  /// Calculate statistics for all recurring tasks in the overlapping periods
  List<TaskStatistics> calculateStatistics(
    String periodId,
    List<Task> tasksFromOverlappingPeriods,
  ) {
    // Group tasks by recurrence ID
    final Map<String, List<Task>> tasksByRecurrence = {};

    for (final task in tasksFromOverlappingPeriods.where(
      (t) => t.isRecurring,
    )) {
      final recurrenceId = task.recurrenceId;
      if (recurrenceId != null) {
        tasksByRecurrence.putIfAbsent(recurrenceId, () => []).add(task);
      }
    }

    // Calculate statistics for each recurrence group
    final statistics = <TaskStatistics>[];

    for (final entry in tasksByRecurrence.entries) {
      final recurrenceId = entry.key;
      final tasks = entry.value;

      // Use the most recent task title
      final mostRecentTask = tasks.reduce(
        (a, b) => a.timePeriodId.compareTo(b.timePeriodId) > 0 ? a : b,
      );

      // Count expected completions (sum of targetCount)
      final expectedCount = tasks.fold<int>(
        0,
        (sum, task) => sum + task.targetCount,
      );

      // Count actual completions (sum of currentCount for completed tasks)
      final completedCount = tasks.fold<int>(
        0,
        (sum, task) =>
            sum + (task.completed ? task.targetCount : task.currentCount),
      );

      statistics.add(
        TaskStatistics(
          recurrenceId: recurrenceId,
          taskTitle: mostRecentTask.title,
          cadence: _resolveCadence(mostRecentTask.cadence),
          completedCount: completedCount,
          expectedCount: expectedCount,
        ),
      );
    }

    // Sort by completion rate (descending) so complete tasks appear first
    statistics.sort((a, b) => b.completionRate.compareTo(a.completionRate));

    return statistics;
  }

  // Helper methods to get overlapping periods
  // TODO: Merge with methods from utils.dart
  List<String> _getDaysInMonth(String monthId) {
    // M#2025-12 -> days from D#2025-12-01 to D#2025-12-31
    final date = _parseMonthId(monthId);
    final days = <String>[];
    final lastDay = DateTime(date.year, date.month + 1, 0).day;

    for (int i = 1; i <= lastDay; i++) {
      final dayDate = DateTime(date.year, date.month, i);
      days.add(_formatDayId(dayDate));
    }

    return days;
  }

  List<String> _getWeeksInMonth(String monthId) {
    // Get all weeks that overlap with the month
    final date = _parseMonthId(monthId);
    final weeks = <String>{};
    final lastDay = DateTime(date.year, date.month + 1, 0).day;

    for (int i = 1; i <= lastDay; i++) {
      final dayDate = DateTime(date.year, date.month, i);
      final weekStart = _getWeekStart(dayDate);
      weeks.add(_formatWeekId(weekStart));
    }

    return weeks.toList();
  }

  List<String> _getDaysInQuarter(String quarterId) {
    // Q#2025-1 -> days in Q1
    final date = _parseQuarterId(quarterId);
    final startMonth = (int.parse(quarterId.split('-')[1]) - 1) * 3 + 1;
    final days = <String>[];

    for (int month = startMonth; month < startMonth + 3; month++) {
      final lastDay = DateTime(date.year, month + 1, 0).day;
      for (int day = 1; day <= lastDay; day++) {
        final dayDate = DateTime(date.year, month, day);
        days.add(_formatDayId(dayDate));
      }
    }

    return days;
  }

  List<String> _getMonthsInQuarter(String quarterId) {
    final date = _parseQuarterId(quarterId);
    final quarter = int.parse(quarterId.split('-')[1]);
    final startMonth = (quarter - 1) * 3 + 1;
    final months = <String>[];

    for (int i = 0; i < 3; i++) {
      final month = startMonth + i;
      months.add('M#${date.year}-${month.toString().padLeft(2, '0')}');
    }

    return months;
  }

  List<String> _getWeeksInQuarter(String quarterId) {
    final date = _parseQuarterId(quarterId);
    final quarter = int.parse(quarterId.split('-')[1]);
    final startMonth = (quarter - 1) * 3 + 1;
    final weeks = <String>{};

    for (int month = startMonth; month < startMonth + 3; month++) {
      final lastDay = DateTime(date.year, month + 1, 0).day;
      for (int day = 1; day <= lastDay; day++) {
        final dayDate = DateTime(date.year, month, day);
        final weekStart = _getWeekStart(dayDate);
        weeks.add(_formatWeekId(weekStart));
      }
    }

    return weeks.toList();
  }

  List<String> _getDaysInYear(String yearId) {
    // Y#2025 -> all days of 2025
    final year = int.parse(yearId.split('#')[1]);
    final days = <String>[];

    for (int month = 1; month <= 12; month++) {
      final lastDay = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= lastDay; day++) {
        final dayDate = DateTime(year, month, day);
        days.add(_formatDayId(dayDate));
      }
    }

    return days;
  }

  List<String> _getMonthsInYear(String yearId) {
    // Y#2025 -> all months of 2025
    final year = int.parse(yearId.split('#')[1]);
    final months = <String>[];

    for (int month = 1; month <= 12; month++) {
      months.add('M#$year-${month.toString().padLeft(2, '0')}');
    }

    return months;
  }

  List<String> _getWeeksInYear(String yearId) {
    final year = int.parse(yearId.split('#')[1]);
    final weeks = <String>{};

    for (int month = 1; month <= 12; month++) {
      final lastDay = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= lastDay; day++) {
        final dayDate = DateTime(year, month, day);
        final weekStart = _getWeekStart(dayDate);
        weeks.add(_formatWeekId(weekStart));
      }
    }

    return weeks.toList();
  }

  List<String> _getDaysInWeek(String weekId) {
    // W#2025-01-12 -> days from Sunday to Saturday
    final date = _parseWeekId(weekId);
    final days = <String>[];

    for (int i = 0; i < 7; i++) {
      final dayDate = date.add(Duration(days: i));
      days.add(_formatDayId(dayDate));
    }

    return days;
  }

  // Parsing helpers
  DateTime _parseMonthId(String monthId) {
    // M#2025-12
    final parts = monthId.split('#')[1].split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime _parseQuarterId(String quarterId) {
    // Q#2025-1
    final parts = quarterId.split('#')[1].split('-');
    return DateTime(int.parse(parts[0]));
  }

  DateTime _parseWeekId(String weekId) {
    // W#2025-01-12 (the Sunday of that week)
    final parts = weekId.split('#')[1].split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    // Get the Sunday of the week containing this date
    final dayOfWeek = date.weekday; // Monday=1, Sunday=7
    final daysToSubtract = dayOfWeek % 7; // Sunday=0
    return date.subtract(Duration(days: daysToSubtract));
  }

  String _formatDayId(DateTime date) {
    return 'D#${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekId(DateTime sundayDate) {
    return 'W#${sundayDate.year}-${sundayDate.month.toString().padLeft(2, '0')}-${sundayDate.day.toString().padLeft(2, '0')}';
  }

  String _resolveCadence(String cadence) {
    switch (cadence) {
      case 'D':
        return 'daily';
      case 'W':
        return 'weekly';
      case 'M':
        return 'monthly';
      case 'Q':
        return 'quarterly';
      case 'Y':
        return 'yearly';
      default:
        return 'unknown';
    }
  }
}
