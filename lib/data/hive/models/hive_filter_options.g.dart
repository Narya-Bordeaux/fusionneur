// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_filter_options.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveFilterOptionsAdapter extends TypeAdapter<HiveFilterOptions> {
  @override
  final int typeId = 12;

  @override
  HiveFilterOptions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveFilterOptions(
      excludePatterns: (fields[0] as List).cast<String>(),
      onlyDart: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveFilterOptions obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.excludePatterns)
      ..writeByte(1)
      ..write(obj.onlyDart);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveFilterOptionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
