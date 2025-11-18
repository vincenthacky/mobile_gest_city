import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class PaymentStatisticsCache extends HiveObject {
  @HiveField(0)
  late String monthKey; // Format: "YYYY-MM"
  
  @HiveField(1)
  late String statisticsJson;
  
  @HiveField(2)
  late DateTime cachedAt;

  PaymentStatisticsCache();

  factory PaymentStatisticsCache.create({
    required String monthKey,
    required String statisticsJson,
    required DateTime cachedAt,
  }) {
    return PaymentStatisticsCache()
      ..monthKey = monthKey
      ..statisticsJson = statisticsJson
      ..cachedAt = cachedAt;
  }
}

@HiveType(typeId: 9)
class PaymentOverviewCache extends HiveObject {
  @HiveField(0)
  late String overviewJson;
  
  @HiveField(1)
  late DateTime cachedAt;

  PaymentOverviewCache();

  factory PaymentOverviewCache.create({
    required String overviewJson,
    required DateTime cachedAt,
  }) {
    return PaymentOverviewCache()
      ..overviewJson = overviewJson
      ..cachedAt = cachedAt;
  }
}

// Adapters Hive générés manuellement
class PaymentStatisticsCacheAdapter extends TypeAdapter<PaymentStatisticsCache> {
  @override
  final int typeId = 8;

  @override
  PaymentStatisticsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentStatisticsCache()
      ..monthKey = fields[0] as String
      ..statisticsJson = fields[1] as String
      ..cachedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, PaymentStatisticsCache obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.monthKey)
      ..writeByte(1)
      ..write(obj.statisticsJson)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatisticsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentOverviewCacheAdapter extends TypeAdapter<PaymentOverviewCache> {
  @override
  final int typeId = 9;

  @override
  PaymentOverviewCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentOverviewCache()
      ..overviewJson = fields[0] as String
      ..cachedAt = fields[1] as DateTime;
  }

  @override
  void write(BinaryWriter writer, PaymentOverviewCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.overviewJson)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentOverviewCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}