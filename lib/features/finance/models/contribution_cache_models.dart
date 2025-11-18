import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class ContributionDataCache extends HiveObject {
  @HiveField(0)
  late String contributionJson;
  
  @HiveField(1)
  late DateTime cachedAt;

  ContributionDataCache();

  factory ContributionDataCache.create({
    required String contributionJson,
    required DateTime cachedAt,
  }) {
    return ContributionDataCache()
      ..contributionJson = contributionJson
      ..cachedAt = cachedAt;
  }
}

@HiveType(typeId: 11)
class UnpaidMonthsCache extends HiveObject {
  @HiveField(0)
  late String unpaidMonthsJson;
  
  @HiveField(1)
  late DateTime cachedAt;

  UnpaidMonthsCache();

  factory UnpaidMonthsCache.create({
    required String unpaidMonthsJson,
    required DateTime cachedAt,
  }) {
    return UnpaidMonthsCache()
      ..unpaidMonthsJson = unpaidMonthsJson
      ..cachedAt = cachedAt;
  }
}

@HiveType(typeId: 12)
class PaymentProofsCache extends HiveObject {
  @HiveField(0)
  late String proofType; // 'validated' ou 'pending'
  
  @HiveField(1)
  late String userId;
  
  @HiveField(2)
  late String paymentProofsJson;
  
  @HiveField(3)
  late DateTime cachedAt;

  PaymentProofsCache();

  factory PaymentProofsCache.create({
    required String proofType,
    required String userId,
    required String paymentProofsJson,
    required DateTime cachedAt,
  }) {
    return PaymentProofsCache()
      ..proofType = proofType
      ..userId = userId
      ..paymentProofsJson = paymentProofsJson
      ..cachedAt = cachedAt;
  }
}

@HiveType(typeId: 13)
class AllPaymentsCache extends HiveObject {
  @HiveField(0)
  late String userId;
  
  @HiveField(1)
  late String paymentsJson;
  
  @HiveField(2)
  late DateTime cachedAt;

  AllPaymentsCache();

  factory AllPaymentsCache.create({
    required String userId,
    required String paymentsJson,
    required DateTime cachedAt,
  }) {
    return AllPaymentsCache()
      ..userId = userId
      ..paymentsJson = paymentsJson
      ..cachedAt = cachedAt;
  }
}

@HiveType(typeId: 14)
class PaymentPeriodsCache extends HiveObject {
  @HiveField(0)
  late String periodsJson;
  
  @HiveField(1)
  late DateTime cachedAt;

  PaymentPeriodsCache();

  factory PaymentPeriodsCache.create({
    required String periodsJson,
    required DateTime cachedAt,
  }) {
    return PaymentPeriodsCache()
      ..periodsJson = periodsJson
      ..cachedAt = cachedAt;
  }
}

// Adapters Hive générés manuellement
class ContributionDataCacheAdapter extends TypeAdapter<ContributionDataCache> {
  @override
  final int typeId = 10;

  @override
  ContributionDataCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContributionDataCache()
      ..contributionJson = fields[0] as String
      ..cachedAt = fields[1] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ContributionDataCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.contributionJson)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionDataCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnpaidMonthsCacheAdapter extends TypeAdapter<UnpaidMonthsCache> {
  @override
  final int typeId = 11;

  @override
  UnpaidMonthsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnpaidMonthsCache()
      ..unpaidMonthsJson = fields[0] as String
      ..cachedAt = fields[1] as DateTime;
  }

  @override
  void write(BinaryWriter writer, UnpaidMonthsCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.unpaidMonthsJson)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnpaidMonthsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentProofsCacheAdapter extends TypeAdapter<PaymentProofsCache> {
  @override
  final int typeId = 12;

  @override
  PaymentProofsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentProofsCache()
      ..proofType = fields[0] as String
      ..userId = fields[1] as String
      ..paymentProofsJson = fields[2] as String
      ..cachedAt = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, PaymentProofsCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.proofType)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.paymentProofsJson)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentProofsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AllPaymentsCacheAdapter extends TypeAdapter<AllPaymentsCache> {
  @override
  final int typeId = 13;

  @override
  AllPaymentsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AllPaymentsCache()
      ..userId = fields[0] as String
      ..paymentsJson = fields[1] as String
      ..cachedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, AllPaymentsCache obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.paymentsJson)
      ..writeByte(2)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllPaymentsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentPeriodsCacheAdapter extends TypeAdapter<PaymentPeriodsCache> {
  @override
  final int typeId = 14;

  @override
  PaymentPeriodsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentPeriodsCache()
      ..periodsJson = fields[0] as String
      ..cachedAt = fields[1] as DateTime;
  }

  @override
  void write(BinaryWriter writer, PaymentPeriodsCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.periodsJson)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentPeriodsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}