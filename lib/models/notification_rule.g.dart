// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_rule.dart';

class NotificationRuleAdapter extends TypeAdapter<NotificationRule> {
  @override
  final int typeId = 4;

  @override
  NotificationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return NotificationRule(
      id: fields[0] as String,
      hour: fields[1] as int,
      minute: fields[2] as int,
      daysOfWeek: (fields[3] as List).cast<int>(),
      message: fields[4] as String,
      timePeriodId: fields[5] as String,
      enabled: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationRule obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute)
      ..writeByte(3)
      ..write(obj.daysOfWeek)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.timePeriodId)
      ..writeByte(6)
      ..write(obj.enabled);
  }
}
