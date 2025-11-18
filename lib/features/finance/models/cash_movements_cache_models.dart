import 'package:hive/hive.dart';

@HiveType(typeId: 15)
class CashMovementsCache extends HiveObject {
  @HiveField(0)
  late String movementsJson;
  
  @HiveField(1)
  late String paginationJson;
  
  @HiveField(2)
  late String? filter;
  
  @HiveField(3)
  late DateTime cachedAt;

  CashMovementsCache();

  factory CashMovementsCache.create({
    required String movementsJson,
    required String paginationJson,
    String? filter,
    required DateTime cachedAt,
  }) {
    return CashMovementsCache()
      ..movementsJson = movementsJson
      ..paginationJson = paginationJson
      ..filter = filter
      ..cachedAt = cachedAt;
  }
}

// Adapter Hive généré manuellement
class CashMovementsCacheAdapter extends TypeAdapter<CashMovementsCache> {
  @override
  final int typeId = 15;

  @override
  CashMovementsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashMovementsCache()
      ..movementsJson = fields[0] as String
      ..paginationJson = fields[1] as String
      ..filter = fields[2] as String?
      ..cachedAt = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CashMovementsCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.movementsJson)
      ..writeByte(1)
      ..write(obj.paginationJson)
      ..writeByte(2)
      ..write(obj.filter)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashMovementsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}