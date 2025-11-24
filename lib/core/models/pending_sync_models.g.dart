// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_sync_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingSyncItemAdapter extends TypeAdapter<PendingSyncItem> {
  @override
  final int typeId = 24;

  @override
  PendingSyncItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingSyncItem(
      id: fields[0] as String,
      type: fields[1] as PendingDataType,
      title: fields[2] as String,
      description: fields[3] as String,
      data: (fields[4] as Map).cast<String, dynamic>(),
      imagePaths: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      retryCount: fields[7] as int,
      lastError: fields[8] as String?,
      status: fields[9] as PendingSyncStatus,
      syncedId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSyncItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.imagePaths)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.retryCount)
      ..writeByte(8)
      ..write(obj.lastError)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.syncedId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSyncItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingDataTypeAdapter extends TypeAdapter<PendingDataType> {
  @override
  final int typeId = 22;

  @override
  PendingDataType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PendingDataType.project;
      case 1:
        return PendingDataType.signalement;
      case 2:
        return PendingDataType.cadreDeVie;
      default:
        return PendingDataType.project;
    }
  }

  @override
  void write(BinaryWriter writer, PendingDataType obj) {
    switch (obj) {
      case PendingDataType.project:
        writer.writeByte(0);
        break;
      case PendingDataType.signalement:
        writer.writeByte(1);
        break;
      case PendingDataType.cadreDeVie:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingDataTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingSyncStatusAdapter extends TypeAdapter<PendingSyncStatus> {
  @override
  final int typeId = 23;

  @override
  PendingSyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PendingSyncStatus.pending;
      case 1:
        return PendingSyncStatus.syncing;
      case 2:
        return PendingSyncStatus.completed;
      case 3:
        return PendingSyncStatus.failed;
      default:
        return PendingSyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PendingSyncStatus obj) {
    switch (obj) {
      case PendingSyncStatus.pending:
        writer.writeByte(0);
        break;
      case PendingSyncStatus.syncing:
        writer.writeByte(1);
        break;
      case PendingSyncStatus.completed:
        writer.writeByte(2);
        break;
      case PendingSyncStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
