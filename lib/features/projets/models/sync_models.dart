import 'package:hive/hive.dart';

part 'sync_models.g.dart';

// Modèle pour stocker les checksums en local
@HiveType(typeId: 0)
class ProjectChecksum extends HiveObject {
  @HiveField(0)
  late String projectId;
  
  @HiveField(1)
  late String checksum;
  
  @HiveField(2)
  late DateTime lastUpdated;
  
  @HiveField(3)
  late int receptionOrder; // Ordre de réception depuis l'API

  ProjectChecksum();

  ProjectChecksum.create({
    required this.projectId,
    required this.checksum,
    required this.lastUpdated,
    required this.receptionOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': projectId,
      'checksum': checksum,
    };
  }
}

// Modèle pour stocker les projets complets en local
@HiveType(typeId: 1)
class CachedProject extends HiveObject {
  @HiveField(0)
  late String projectId;
  
  @HiveField(1)
  late String projectJson; // JSON complet du projet
  
  @HiveField(2)
  late DateTime cachedAt;

  CachedProject();

  CachedProject.create({
    required this.projectId,
    required this.projectJson,
    required this.cachedAt,
  });
}

// Modèle pour les filtres de synchronisation
class SyncFilters {
  final String? status;
  final String? search;
  final String? createdBy;
  final bool? sort;

  SyncFilters({
    this.status,
    this.search,
    this.createdBy,
    this.sort,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (status != null) json['status'] = status;
    if (search != null) json['search'] = search;
    if (createdBy != null) json['created_by'] = createdBy;
    if (sort != null) json['sort'] = sort;
    return json;
  }

  bool get isEmpty => status == null && search == null && createdBy == null && sort == null;
}

// Modèle de requête de synchronisation
class SyncRequest {
  final bool? isInitializing;
  final String? globalChecksum;
  final List<Map<String, dynamic>>? itemsChecksums;
  final SyncFilters? filters;

  SyncRequest({
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

// Modèle de réponse de synchronisation
class SyncResponse {
  final String syncType;
  final String? globalChecksum;
  final String? message;
  final SyncChanges? changes;
  final SyncStats? stats;
  final String? timestamp;
  final List<Map<String, dynamic>>? items; // Pour full sync

  SyncResponse({
    required this.syncType,
    this.globalChecksum,
    this.message,
    this.changes,
    this.stats,
    this.timestamp,
    this.items,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return SyncResponse(
      syncType: data['sync_type'] ?? 'unknown',
      globalChecksum: data['global_checksum'],
      message: data['message'] ?? json['message'],
      changes: data['changes'] != null ? SyncChanges.fromJson(data['changes']) : null,
      stats: data['stats'] != null ? SyncStats.fromJson(data['stats']) : null,
      timestamp: data['timestamp'],
      items: data['items'] != null ? List<Map<String, dynamic>>.from(data['items']) : null,
    );
  }

  bool get isFullSync => syncType == 'full';
  bool get isNoSync => syncType == 'none';
  bool get isDifferentialSync => syncType == 'differential';
  bool get hasChanges => changes != null && changes!.hasChanges;
}

// Modèle des changements dans la synchronisation
class SyncChanges {
  final List<dynamic> added;    // L'API renvoie des listes imbriquées
  final List<dynamic> updated;  // L'API renvoie des listes imbriquées
  final List<String> deleted;

  SyncChanges({
    required this.added,
    required this.updated,
    required this.deleted,
  });

  factory SyncChanges.fromJson(Map<String, dynamic> json) {
    return SyncChanges(
      added: List<dynamic>.from(json['added'] ?? []),
      updated: List<dynamic>.from(json['updated'] ?? []),
      deleted: List<String>.from(json['deleted'] ?? []),
    );
  }

  bool get hasChanges => added.isNotEmpty || updated.isNotEmpty || deleted.isNotEmpty;
  int get totalChanges => added.length + updated.length + deleted.length;
}

// Modèle des statistiques de synchronisation
class SyncStats {
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final int totalServer;

  SyncStats({
    required this.addedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.totalServer,
  });

  factory SyncStats.fromJson(Map<String, dynamic> json) {
    return SyncStats(
      addedCount: json['added_count'] ?? 0,
      updatedCount: json['updated_count'] ?? 0,
      deletedCount: json['deleted_count'] ?? 0,
      totalServer: json['total_server'] ?? 0,
    );
  }

  int get totalChanges => addedCount + updatedCount + deletedCount;
}

// États de synchronisation
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

// Types d'opérations de synchronisation
enum SyncOperation {
  fullSync,        // Synchronisation complète (première fois)
  checkSync,       // Vérification avec checksums
  filterSync,      // Application de filtres uniquement
}