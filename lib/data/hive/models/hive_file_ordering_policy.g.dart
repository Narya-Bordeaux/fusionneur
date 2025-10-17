// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_file_ordering_policy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveFileOrderingPolicyAdapter
    extends TypeAdapter<HiveFileOrderingPolicy> {
  @override
  final int typeId = 11;

  @override
  HiveFileOrderingPolicy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveFileOrderingPolicy(
      explicitOrder: (fields[0] as List?)?.cast<String>(),
      fallbackTree: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveFileOrderingPolicy obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.explicitOrder)
      ..writeByte(1)
      ..write(obj.fallbackTree);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveFileOrderingPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
