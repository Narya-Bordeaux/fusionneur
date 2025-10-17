// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HivePresetAdapter extends TypeAdapter<HivePreset> {
  @override
  final int typeId = 2;

  @override
  HivePreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePreset(
      id: fields[0] as String,
      projectId: fields[1] as String,
      name: fields[2] as String,
      hiveSelectionSpec: fields[3] as HiveSelectionSpec,
      hiveFileOrderingPolicy: fields[4] as HiveFileOrderingPolicy,
      hiveFilterOptions: fields[5] as HiveFilterOptions,
      isFavorite: fields[6] as bool,
      isDefault: fields[7] as bool,
      isArchived: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HivePreset obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.hiveSelectionSpec)
      ..writeByte(4)
      ..write(obj.hiveFileOrderingPolicy)
      ..writeByte(5)
      ..write(obj.hiveFilterOptions)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.isDefault)
      ..writeByte(8)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
