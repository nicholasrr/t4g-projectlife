// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationRuleAdapter extends TypeAdapter<NotificationRule> {
  @override
  final int typeId = 4;

  @override
  NotificationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationRule(
      id: fields[0] as String,
      hour: fields[1] as int,
      minute: fields[2] as int,
      daysOfWeek: (fields[3] as List).cast<int>(),
      message: fields[4] as String,
      timeCadence: fields[5] as String,
      enabled: fields[6] as bool,
      scheduledSuccessfully: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationRule obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.timeCadence)
      ..writeByte(6)
      ..write(obj.enabled)
      ..writeByte(7)
      ..write(obj.scheduledSuccessfully);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
