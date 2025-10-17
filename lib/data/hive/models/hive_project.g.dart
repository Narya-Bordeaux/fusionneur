// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveProjectAdapter extends TypeAdapter<HiveProject> {
  @override
  final int typeId = 1;

  @override
  HiveProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveProject(
      id: fields[0] as String,
      packageName: fields[1] as String,
      rootPath: fields[2] as String,
      slug: fields[3] as String?,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      isArchived: fields[6] as bool,
      lastRunId: fields[7] as String?,
      lastPresetId: fields[8] as String?,
      lastExportPath: fields[9] as String?,
      lastExportAt: fields[10] as DateTime?,
      totalRuns: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveProject obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.rootPath)
      ..writeByte(3)
      ..write(obj.slug)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isArchived)
      ..writeByte(7)
      ..write(obj.lastRunId)
      ..writeByte(8)
      ..write(obj.lastPresetId)
      ..writeByte(9)
      ..write(obj.lastExportPath)
      ..writeByte(10)
      ..write(obj.lastExportAt)
      ..writeByte(11)
      ..write(obj.totalRuns);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
