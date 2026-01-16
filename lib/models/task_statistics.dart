/// Represents statistics for a recurring task within a time period
class TaskStatistics {
  final String recurrenceId;
  final String taskTitle; // Most recent title
  final String cadence;
  final int completedCount;
  final int expectedCount;

  TaskStatistics({
    required this.recurrenceId,
    required this.taskTitle,
    required this.cadence,
    required this.completedCount,
    required this.expectedCount,
  });

  /// Calculate completion rate as a percentage (0-100)
  double get completionRate {
    if (expectedCount == 0) return 0;
    return (completedCount / expectedCount) * 100;
  }

  /// Whether the task was completed as expected
  bool get isComplete => completedCount >= expectedCount;
}
