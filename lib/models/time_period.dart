import 'package:hive/hive.dart';

part 'time_period.g.dart';

@HiveType(typeId: 3)
class TimePeriod extends HiveObject {
  @HiveField(0)
  String id; // Format: 'D#2025-10-25', 'W#2025-10-19', etc.

  @HiveField(1)
  bool backfilled;

  @HiveField(2)
  DateTime createdAt;

  TimePeriod({
    required this.id,
    this.backfilled = false,
    required this.createdAt,
  });
}
