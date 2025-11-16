// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InformationChecksumAdapter extends TypeAdapter<InformationChecksum> {
  @override
  final int typeId = 4;

  @override
  InformationChecksum read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InformationChecksum()
      ..informationId = fields[0] as String
      ..checksum = fields[1] as String
      ..lastUpdated = fields[2] as DateTime
      ..receptionOrder = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, InformationChecksum obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.informationId)
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
      other is InformationChecksumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedInformationAdapter extends TypeAdapter<CachedInformation> {
  @override
  final int typeId = 5;

  @override
  CachedInformation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedInformation()
      ..informationId = fields[0] as String
      ..informationJson = fields[1] as String
      ..cachedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CachedInformation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.informationId)
      ..writeByte(1)
      ..write(obj.informationJson)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedInformationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
