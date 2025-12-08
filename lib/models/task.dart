import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? categoryId;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  String cadence; // 'D'|'W'|'M'|'Q'|'Y'

  @HiveField(6)
  String timePeriodId; // e.g., 'D#2025-10-25'

  @HiveField(7)
  bool isRecurring;

  @HiveField(8)
  int? _targetCount;

  @HiveField(9)
  int? _currentCount;

  @HiveField(10)
  String? recurrenceId;

  // Getters that provide defaults for backward compatibility
  int get targetCount => _targetCount ?? 1;
  int get currentCount => _currentCount ?? 0;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    this.completed = false,
    required this.cadence,
    required this.timePeriodId,
    this.isRecurring = false,
    int? targetCount,
    int? currentCount,
    this.recurrenceId = "",
  }) : _targetCount = targetCount,
       _currentCount = currentCount;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    bool? completed,
    String? cadence,
    String? timePeriodId,
    bool? isRecurring,
    int? targetCount,
    int? currentCount,
    String? recurrenceId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      completed: completed ?? this.completed,
      cadence: cadence ?? this.cadence,
      timePeriodId: timePeriodId ?? this.timePeriodId,
      isRecurring: isRecurring ?? this.isRecurring,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      recurrenceId: recurrenceId ?? this.recurrenceId,
    );
  }
}
