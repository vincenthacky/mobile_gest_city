// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_sync_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionChecksumAdapter extends TypeAdapter<TransactionChecksum> {
  @override
  final int typeId = 6;

  @override
  TransactionChecksum read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionChecksum()
      ..transactionId = fields[0] as String
      ..checksum = fields[1] as String
      ..lastUpdated = fields[2] as DateTime
      ..receptionOrder = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, TransactionChecksum obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.transactionId)
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
      other is TransactionChecksumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedTransactionAdapter extends TypeAdapter<CachedTransaction> {
  @override
  final int typeId = 7;

  @override
  CachedTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedTransaction()
      ..transactionId = fields[0] as String
      ..transactionJson = fields[1] as String
      ..cachedAt = fields[2] as DateTime
      ..receptionOrder = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, CachedTransaction obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.transactionId)
      ..writeByte(1)
      ..write(obj.transactionJson)
      ..writeByte(2)
      ..write(obj.cachedAt)
      ..writeByte(3)
      ..write(obj.receptionOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
