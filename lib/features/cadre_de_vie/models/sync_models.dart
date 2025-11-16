import 'package:hive/hive.dart';

part 'sync_models.g.dart';

// Modèle pour stocker les checksums des informations en local
@HiveType(typeId: 4) // Utiliser un typeId différent des autres modules
class InformationChecksum extends HiveObject {
  @HiveField(0)
  late String informationId;
  
  @HiveField(1)
  late String checksum;
  
  @HiveField(2)
  late DateTime lastUpdated;
  
  @HiveField(3)
  late int receptionOrder; // Ordre de réception depuis l'API

  InformationChecksum();

  InformationChecksum.create({
    required this.informationId,
    required this.checksum,
    required this.lastUpdated,
    required this.receptionOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': informationId,
      'checksum': checksum,
    };
  }
}

// Modèle pour stocker les informations complètes en local
@HiveType(typeId: 5)
class CachedInformation extends HiveObject {
  @HiveField(0)
  late String informationId;
  
  @HiveField(1)
  late String informationJson; // JSON complet de l'information
  
  @HiveField(2)
  late DateTime cachedAt;

  CachedInformation();

  CachedInformation.create({
    required this.informationId,
    required this.informationJson,
    required this.cachedAt,
  });
}

// Modèle pour les filtres de synchronisation des informations
class InformationSyncFilters {
  final String? status;
  final String? priority;
  final String? reportType;
  final String? search;
  final bool? sort;

  InformationSyncFilters({
    this.status,
    this.priority,
    this.reportType,
    this.search,
    this.sort,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (status != null) json['status'] = status;
    if (priority != null) json['priority'] = priority;
    if (reportType != null) json['report_type'] = reportType;
    if (search != null) json['search'] = search;
    if (sort != null) json['sort'] = sort;
    return json;
  }

  bool get isEmpty => status == null && priority == null && reportType == null && search == null && sort == null;
}

// Modèle de requête de synchronisation pour informations
class InformationSyncRequest {
  final bool? isInitializing;
  final String? globalChecksum;
  final List<Map<String, dynamic>>? itemsChecksums;
  final InformationSyncFilters? filters;

  InformationSyncRequest({
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

// Modèle de réponse de synchronisation pour informations
class InformationSyncResponse {
  final String syncType;
  final String? globalChecksum;
  final String? message;
  final InformationSyncChanges? changes;
  final InformationSyncStats? stats;
  final String? timestamp;
  final List<Map<String, dynamic>>? items; // Pour full sync

  InformationSyncResponse({
    required this.syncType,
    this.globalChecksum,
    this.message,
    this.changes,
    this.stats,
    this.timestamp,
    this.items,
  });

  factory InformationSyncResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return InformationSyncResponse(
      syncType: data['sync_type'] ?? 'unknown',
      globalChecksum: data['global_checksum'],
      message: data['message'] ?? json['message'],
      changes: data['changes'] != null ? InformationSyncChanges.fromJson(data['changes']) : null,
      stats: data['stats'] != null ? InformationSyncStats.fromJson(data['stats']) : null,
      timestamp: data['timestamp'],
      items: data['items'] != null ? List<Map<String, dynamic>>.from(data['items']) : null,
    );
  }

  bool get isFullSync => syncType == 'full';
  bool get isNoSync => syncType == 'none';
  bool get isDifferentialSync => syncType == 'differential';
  bool get hasChanges => changes != null && changes!.hasChanges;
}

// Modèle des changements dans la synchronisation des informations
class InformationSyncChanges {
  final List<dynamic> added;    // L'API renvoie des listes imbriquées
  final List<dynamic> updated;  // L'API renvoie des listes imbriquées
  final List<String> deleted;

  InformationSyncChanges({
    required this.added,
    required this.updated,
    required this.deleted,
  });

  factory InformationSyncChanges.fromJson(Map<String, dynamic> json) {
    return InformationSyncChanges(
      added: List<dynamic>.from(json['added'] ?? []),
      updated: List<dynamic>.from(json['updated'] ?? []),
      deleted: List<String>.from(json['deleted'] ?? []),
    );
  }

  bool get hasChanges => added.isNotEmpty || updated.isNotEmpty || deleted.isNotEmpty;
  int get totalChanges => added.length + updated.length + deleted.length;
}

// Modèle des statistiques de synchronisation des informations
class InformationSyncStats {
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final int totalServer;

  InformationSyncStats({
    required this.addedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.totalServer,
  });

  factory InformationSyncStats.fromJson(Map<String, dynamic> json) {
    return InformationSyncStats(
      addedCount: json['added_count'] ?? 0,
      updatedCount: json['updated_count'] ?? 0,
      deletedCount: json['deleted_count'] ?? 0,
      totalServer: json['total_server'] ?? 0,
    );
  }

  int get totalChanges => addedCount + updatedCount + deletedCount;
}

// États de synchronisation pour informations
enum InformationSyncStatus {
  idle,
  syncing,
  success,
  error,
}

// Types d'opérations de synchronisation pour informations
enum InformationSyncOperation {
  fullSync,        // Synchronisation complète (première fois)
  checkSync,       // Vérification avec checksums
  filterSync,      // Application de filtres uniquement
}

// Résultat d'une opération de synchronisation pour informations
class InformationSyncResult {
  final InformationSyncOperation operation;
  final bool hasChanges;
  final List<dynamic> informations; // InformationModel sera défini dans le controller
  final String message;
  final InformationSyncStats? stats;
  final InformationSyncChanges? changes;

  InformationSyncResult({
    required this.operation,
    required this.hasChanges,
    required this.informations,
    required this.message,
    this.stats,
    this.changes,
  });

  bool get isSuccessful => informations.isNotEmpty || !hasChanges;
}

// Résultat de validation des données locales pour informations
class InformationSyncValidation {
  final bool isValid;
  final List<String> issues;
  final int informationCount;
  final int checksumCount;

  InformationSyncValidation({
    required this.isValid,
    required this.issues,
    required this.informationCount,
    required this.checksumCount,
  });

  String get summary => isValid 
      ? 'Validation réussie: $informationCount informations, $checksumCount checksums'
      : 'Validation échouée: ${issues.length} problème${issues.length > 1 ? 's' : ''}';
}