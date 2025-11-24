// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_project_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingProjectAdapter extends TypeAdapter<PendingProject> {
  @override
  final int typeId = 20;

  @override
  PendingProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingProject(
      id: fields[0] as String,
      title: fields[1] as String,
      shortDescription: fields[2] as String,
      longDescription: fields[3] as String,
      estimatedAmount: fields[4] as String,
      startDate: fields[5] as DateTime?,
      endDate: fields[6] as DateTime?,
      deadlineDate: fields[7] as DateTime,
      withCallForTenders: fields[8] as bool,
      withServiceProvider: fields[9] as bool,
      providerName: fields[10] as String?,
      providerAmount: fields[11] as String?,
      attachments: (fields[12] as List).cast<String>(),
      imagePaths: (fields[13] as List).cast<String>(),
      createdAt: fields[14] as DateTime,
      retryCount: fields[15] as int,
      lastError: fields[16] as String?,
      status: fields[17] as PendingProjectStatus,
    );
  }

  @override
  void write(BinaryWriter writer, PendingProject obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.shortDescription)
      ..writeByte(3)
      ..write(obj.longDescription)
      ..writeByte(4)
      ..write(obj.estimatedAmount)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.deadlineDate)
      ..writeByte(8)
      ..write(obj.withCallForTenders)
      ..writeByte(9)
      ..write(obj.withServiceProvider)
      ..writeByte(10)
      ..write(obj.providerName)
      ..writeByte(11)
      ..write(obj.providerAmount)
      ..writeByte(12)
      ..write(obj.attachments)
      ..writeByte(13)
      ..write(obj.imagePaths)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.retryCount)
      ..writeByte(16)
      ..write(obj.lastError)
      ..writeByte(17)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingProjectStatusAdapter extends TypeAdapter<PendingProjectStatus> {
  @override
  final int typeId = 21;

  @override
  PendingProjectStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PendingProjectStatus.pending;
      case 1:
        return PendingProjectStatus.syncing;
      case 2:
        return PendingProjectStatus.completed;
      case 3:
        return PendingProjectStatus.failed;
      default:
        return PendingProjectStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PendingProjectStatus obj) {
    switch (obj) {
      case PendingProjectStatus.pending:
        writer.writeByte(0);
        break;
      case PendingProjectStatus.syncing:
        writer.writeByte(1);
        break;
      case PendingProjectStatus.completed:
        writer.writeByte(2);
        break;
      case PendingProjectStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingProjectStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
