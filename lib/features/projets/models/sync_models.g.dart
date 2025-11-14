// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectChecksumAdapter extends TypeAdapter<ProjectChecksum> {
  @override
  final int typeId = 0;

  @override
  ProjectChecksum read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectChecksum()
      ..projectId = fields[0] as String
      ..checksum = fields[1] as String
      ..lastUpdated = fields[2] as DateTime
      ..receptionOrder = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, ProjectChecksum obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.projectId)
      ..writeByte(1)
      ..write(obj.checksum)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.receptionOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectChecksumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedProjectAdapter extends TypeAdapter<CachedProject> {
  @override
  final int typeId = 1;

  @override
  CachedProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProject()
      ..projectId = fields[0] as String
      ..projectJson = fields[1] as String
      ..cachedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CachedProject obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.projectId)
      ..writeByte(1)
      ..write(obj.projectJson)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
