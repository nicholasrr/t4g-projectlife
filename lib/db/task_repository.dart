import 'package:hive/hive.dart';
import 'package:projectlife/utils/utils.dart';
import '../models/task.dart';
import 'hive_boxes.dart';
import '../utils/global_data.dart';

/// Repository for managing tasks in Hive storage.
/// Uses a hybrid approach with a main task box and an index box for efficient time period lookups.
class TaskRepository {
  final Box _tasksBox;
  final Box _taskIndexBox;

  TaskRepository()
    : _tasksBox = Hive.box(tasksBoxName),
      _taskIndexBox = Hive.box(taskIndexBoxName);

  /// Creates a new task and adds it to storage.
  Future<void> createTask(Task task) async {
    await _tasksBox.put(task.id, task);
    await _addToIndex(task.timePeriodId, task.id);
    // Notify listeners that tasks changed
    Globals.tasksVersion.value++;
  }

  /// Retrieves a task by its ID.
  /// If the task references a category that no longer exists, its categoryId will be cleared.
  Task? getTask(String id) {
    final task = _tasksBox.get(id) as Task?;
    if (task == null) return null;

    // Check if the task's category still exists
    if (task.categoryId != null &&
        !Hive.box(categoriesBoxName).containsKey(task.categoryId)) {
      task.categoryId = null;
      _tasksBox.put(id, task); // Save the update
    }

    return task;
  }

  /// Updates an existing task.
  /// If the time period changed, updates the index accordingly.
  Future<void> editTask(Task task) async {
    final existingTask = _tasksBox.get(task.id) as Task?;
    if (existingTask == null) {
      throw StateError('Cannot edit non-existent task: ${task.id}');
    }

    // Check if the time period changed
    if (existingTask.timePeriodId != task.timePeriodId) {
      await _removeFromIndex(existingTask.timePeriodId, task.id);
      await _addToIndex(task.timePeriodId, task.id);
    }

    await _tasksBox.put(task.id, task);
    // Notify listeners that tasks changed
    Globals.tasksVersion.value++;
  }

  /// Deletes a task and removes it from indexes.
  Future<void> deleteTask(String id) async {
    final task = _tasksBox.get(id) as Task?;
    if (task != null) {
      await _removeFromIndex(task.timePeriodId, id);
      await _tasksBox.delete(id);
      // Notify listeners that tasks changed
      Globals.tasksVersion.value++;
    }
  }

  /// Moves a task to a new time period.
  Future<void> moveTask(String taskId, String newTimePeriodId) async {
    final task = _tasksBox.get(taskId) as Task?;
    if (task == null) return;

    await _removeFromIndex(task.timePeriodId, taskId);
    await _addToIndex(newTimePeriodId, taskId);

    task.timePeriodId = newTimePeriodId;
    await _tasksBox.put(taskId, task);
    // Notify listeners that tasks changed
    Globals.tasksVersion.value++;
  }

  /// Gets all tasks for a specific time period.
  /// If a task references a category that no longer exists, its categoryId will be cleared.
  List<Task> getTasksForPeriod(String timePeriodId) {
    if (timePeriodId == 'A') {
      List<Task> allTasks = [];
      for (final cadence in ['D', 'W', 'M', 'Q', 'Y']) {
        final periodId = getCurrentTimePeriodId(cadence);
        allTasks.addAll(getTasksForPeriod(periodId));
      }
      return allTasks;
    }

    final taskIds =
        _taskIndexBox.get(timePeriodId, defaultValue: <String>[]) as List;
    final categoryBox = Hive.box(categoriesBoxName);

    return taskIds
        .map((id) {
          final task = _tasksBox.get(id) as Task?;
          if (task == null) return null;

          // Check if the task's category still exists
          if (task.categoryId != null &&
              !categoryBox.containsKey(task.categoryId)) {
            // Category was deleted, update the task to remove the reference
            task.categoryId = null;
            _tasksBox.put(id, task); // Save the update
          }

          return task;
        })
        .where((task) => task != null)
        .map((task) => task as Task)
        .toList();
  }

  /// Gets all recurring or ad-hoc tasks for a time period.
  List<Task> getTasksForPeriodByType(String timePeriodId, bool isRecurring) {
    return getTasksForPeriod(
      timePeriodId,
    ).where((task) => task.isRecurring == isRecurring).toList();
  }

  /// Bulk creates tasks (useful for backfill operations).
  Future<void> createTasks(List<Task> tasks) async {
    // Group tasks by time period for efficient index updates
    final tasksByPeriod = <String, List<String>>{};
    for (final task in tasks) {
      tasksByPeriod.putIfAbsent(task.timePeriodId, () => []).add(task.id);
    }

    // Update all tasks
    await _tasksBox.putAll(
      Map.fromEntries(tasks.map((t) => MapEntry(t.id, t))),
    );

    // Update indexes
    for (final entry in tasksByPeriod.entries) {
      await _addManyToIndex(entry.key, entry.value);
    }
    // Notify listeners that tasks changed (bulk)
    Globals.tasksVersion.value++;
  }

  /// Helper to add a task ID to a time period's index.
  Future<void> _addToIndex(String timePeriodId, String taskId) async {
    final taskIds =
        _taskIndexBox.get(timePeriodId, defaultValue: <String>[]) as List;
    taskIds.add(taskId);
    await _taskIndexBox.put(timePeriodId, taskIds);
  }

  /// Helper to add multiple task IDs to a time period's index.
  Future<void> _addManyToIndex(
    String timePeriodId,
    List<String> taskIds,
  ) async {
    final existing =
        _taskIndexBox.get(timePeriodId, defaultValue: <String>[]) as List;
    existing.addAll(taskIds);
    await _taskIndexBox.put(timePeriodId, existing);
  }

  /// Helper to remove a task ID from a time period's index.
  Future<void> _removeFromIndex(String timePeriodId, String taskId) async {
    final taskIds =
        _taskIndexBox.get(timePeriodId, defaultValue: <String>[]) as List;
    taskIds.remove(taskId);
    await _taskIndexBox.put(timePeriodId, taskIds);
  }
}
