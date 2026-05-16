import 'package:hive/hive.dart';

part 'notification_rule.g.dart';

/// A scheduled notification rule that triggers on selected weekdays at a fixed time.
@HiveType(typeId: 4)
class NotificationRule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int hour;

  @HiveField(2)
  int minute;

  @HiveField(3)
  List<int> daysOfWeek;

  @HiveField(4)
  String message;

  @HiveField(5)
  String timePeriodId;

  @HiveField(6)
  bool enabled;

  NotificationRule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    required this.message,
    required this.timePeriodId,
    this.enabled = true,
  });

  String get formattedTime {
    final hours = hour.toString().padLeft(2, '0');
    final minutes = minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get abbreviatedDays {
    if (daysOfWeek.isEmpty) return '';
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selected = daysOfWeek.toList()..sort();
    final nameList =
        selected
            .map((weekday) {
              if (weekday < 1 || weekday > 7) return '';
              return labels[weekday - 1];
            })
            .where((label) => label.isNotEmpty)
            .toList();
    return nameList.join(', ');
  }
}
