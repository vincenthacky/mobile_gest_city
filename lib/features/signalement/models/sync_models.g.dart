// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReportChecksumAdapter extends TypeAdapter<ReportChecksum> {
  @override
  final int typeId = 2;

  @override
  ReportChecksum read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReportChecksum()
      ..reportId = fields[0] as String
      ..checksum = fields[1] as String
      ..lastUpdated = fields[2] as DateTime
      ..receptionOrder = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, ReportChecksum obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.reportId)
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
      other is ReportChecksumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedReportAdapter extends TypeAdapter<CachedReport> {
  @override
  final int typeId = 3;

  @override
  CachedReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedReport()
      ..reportId = fields[0] as String
      ..reportJson = fields[1] as String
      ..cachedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CachedReport obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.reportId)
      ..writeByte(1)
      ..write(obj.reportJson)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
