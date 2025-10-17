// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_run.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveRunAdapter extends TypeAdapter<HiveRun> {
  @override
  final int typeId = 3;

  @override
  HiveRun read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveRun(
      id: fields[0] as String,
      projectId: fields[1] as String,
      presetId: fields[2] as String,
      indexInPreset: fields[3] as int,
      outputPath: fields[4] as String,
      outputHash: fields[5] as String,
      fileCount: fields[6] as int,
      status: fields[7] as RunStatus,
      notes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveRun obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.presetId)
      ..writeByte(3)
      ..write(obj.indexInPreset)
      ..writeByte(4)
      ..write(obj.outputPath)
      ..writeByte(5)
      ..write(obj.outputHash)
      ..writeByte(6)
      ..write(obj.fileCount)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveRunAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RunStatusAdapter extends TypeAdapter<RunStatus> {
  @override
  final int typeId = 30;

  @override
  RunStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RunStatus.success;
      case 1:
        return RunStatus.failed;
      case 2:
        return RunStatus.running;
      default:
        return RunStatus.success;
    }
  }

  @override
  void write(BinaryWriter writer, RunStatus obj) {
    switch (obj) {
      case RunStatus.success:
        writer.writeByte(0);
        break;
      case RunStatus.failed:
        writer.writeByte(1);
        break;
      case RunStatus.running:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
