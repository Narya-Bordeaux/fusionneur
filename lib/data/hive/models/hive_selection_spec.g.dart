// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_selection_spec.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSelectionSpecAdapter extends TypeAdapter<HiveSelectionSpec> {
  @override
  final int typeId = 10;

  @override
  HiveSelectionSpec read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSelectionSpec(
      includeDirs: (fields[0] as List).cast<String>(),
      excludeDirs: (fields[1] as List).cast<String>(),
      includeFiles: (fields[2] as List).cast<String>(),
      excludeFiles: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSelectionSpec obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.includeDirs)
      ..writeByte(1)
      ..write(obj.excludeDirs)
      ..writeByte(2)
      ..write(obj.includeFiles)
      ..writeByte(3)
      ..write(obj.excludeFiles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSelectionSpecAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
