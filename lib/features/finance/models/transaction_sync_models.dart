import 'package:hive/hive.dart';

part 'transaction_sync_models.g.dart';

// Modèle pour stocker les checksums des transactions en local
@HiveType(typeId: 6)
class TransactionChecksum extends HiveObject {
  @HiveField(0)
  late String transactionId;
  
  @HiveField(1)
  late String checksum;
  
  @HiveField(2)
  late DateTime lastUpdated;
  
  @HiveField(3)
  late int receptionOrder; // Ordre de réception depuis l'API

  TransactionChecksum();

  TransactionChecksum.create({
    required this.transactionId,
    required this.checksum,
    required this.lastUpdated,
    required this.receptionOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': transactionId,
      'checksum': checksum,
    };
  }
}

// Modèle pour stocker les transactions complètes en local
@HiveType(typeId: 7)
class CachedTransaction extends HiveObject {
  @HiveField(0)
  late String transactionId;
  
  @HiveField(1)
  late String transactionJson; // JSON complet de la transaction
  
  @HiveField(2)
  late DateTime cachedAt;

  @HiveField(3)
  late int receptionOrder; // Ordre de réception depuis l'API

  CachedTransaction();

  CachedTransaction.create({
    required this.transactionId,
    required this.transactionJson,
    required this.cachedAt,
    required this.receptionOrder,
  });
}

// Modèle pour les filtres de synchronisation des transactions
class TransactionSyncFilters {
  final String? status;
  final String? kind;
  final String? method;
  final String? dateFrom;
  final String? dateTo;
  final bool? sort;

  TransactionSyncFilters({
    this.status,
    this.kind,
    this.method,
    this.dateFrom,
    this.dateTo,
    this.sort,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (status != null) json['status'] = status;
    if (kind != null) json['kind'] = kind;
    if (method != null) json['method'] = method;
    if (dateFrom != null) json['date_from'] = dateFrom;
    if (dateTo != null) json['date_to'] = dateTo;
    if (sort != null) json['sort'] = sort;
    return json;
  }

  bool get isEmpty => status == null && kind == null && method == null && 
                     dateFrom == null && dateTo == null && sort == null;
}

// Modèle de requête de synchronisation pour transactions
class TransactionSyncRequest {
  final bool? isInitializing;
  final String? globalChecksum;
  final List<Map<String, dynamic>>? itemsChecksums;
  final TransactionSyncFilters? filters;

  TransactionSyncRequest({
    this.isInitializing,
    this.globalChecksum,
    this.itemsChecksums,
    this.filters,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    
    if (isInitializing != null) {
      json['is_initializing'] = isInitializing.toString();
    }
    
    if (globalChecksum != null) {
      json['global_checksum'] = globalChecksum;
    }
    
    if (itemsChecksums != null) {
      json['items_checksums'] = itemsChecksums;
    }
    
    if (filters != null && !filters!.isEmpty) {
      json['filters'] = filters!.toJson();
    }
    
    return json;
  }
}

// Modèle des statistiques de synchronisation
class TransactionSyncStats {
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final int totalServer;

  TransactionSyncStats({
    required this.addedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.totalServer,
  });

  factory TransactionSyncStats.fromJson(Map<String, dynamic> json) {
    return TransactionSyncStats(
      addedCount: json['added_count'] ?? 0,
      updatedCount: json['updated_count'] ?? 0,
      deletedCount: json['deleted_count'] ?? 0,
      totalServer: json['total_server'] ?? 0,
    );
  }
}

// Modèle des changements de synchronisation
class TransactionSyncChanges {
  final List<Map<String, dynamic>>? added;
  final List<Map<String, dynamic>>? updated;
  final List<String>? deleted;

  TransactionSyncChanges({
    this.added,
    this.updated,
    this.deleted,
  });

  factory TransactionSyncChanges.fromJson(Map<String, dynamic> json) {
    return TransactionSyncChanges(
      added: json['added'] != null ? List<Map<String, dynamic>>.from(json['added']) : null,
      updated: json['updated'] != null ? List<Map<String, dynamic>>.from(json['updated']) : null,
      deleted: json['deleted'] != null ? List<String>.from(json['deleted']) : null,
    );
  }

  bool get hasChanges => 
    (added?.isNotEmpty ?? false) || 
    (updated?.isNotEmpty ?? false) || 
    (deleted?.isNotEmpty ?? false);
}

// Modèle de réponse de synchronisation des transactions
class TransactionSyncResponse {
  final String syncType;
  final String? globalChecksum;
  final String? message;
  final TransactionSyncChanges? changes;
  final TransactionSyncStats? stats;
  final String? timestamp;
  final List<Map<String, dynamic>>? items; // Pour full sync

  TransactionSyncResponse({
    required this.syncType,
    this.globalChecksum,
    this.message,
    this.changes,
    this.stats,
    this.timestamp,
    this.items,
  });

  factory TransactionSyncResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return TransactionSyncResponse(
      syncType: data['sync_type'] ?? 'unknown',
      globalChecksum: data['global_checksum'],
      message: data['message'] ?? json['message'],
      changes: data['changes'] != null ? TransactionSyncChanges.fromJson(data['changes']) : null,
      stats: data['stats'] != null ? TransactionSyncStats.fromJson(data['stats']) : null,
      timestamp: data['timestamp'],
      items: data['items'] != null ? List<Map<String, dynamic>>.from(data['items']) : null,
    );
  }

  bool get isFullSync => syncType == 'full';
  bool get isNoSync => syncType == 'none';
  bool get hasChanges => changes?.hasChanges ?? false;
}