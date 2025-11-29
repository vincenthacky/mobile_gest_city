import 'package:hive/hive.dart';

part 'sync_models.g.dart';

// Modèle pour stocker les checksums des signalements en local
@HiveType(typeId: 16) // Utiliser un typeId différent de celui des autres modules
class ReportChecksum extends HiveObject {
  @HiveField(0)
  late String reportId;
  
  @HiveField(1)
  late String checksum;
  
  @HiveField(2)
  late DateTime lastUpdated;
  
  @HiveField(3)
  late int receptionOrder; // Ordre de réception depuis l'API

  ReportChecksum();

  ReportChecksum.create({
    required this.reportId,
    required this.checksum,
    required this.lastUpdated,
    required this.receptionOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': reportId,
      'checksum': checksum,
    };
  }
}

// Modèle pour stocker les signalements complets en local
@HiveType(typeId: 17)
class CachedReport extends HiveObject {
  @HiveField(0)
  late String reportId;
  
  @HiveField(1)
  late String reportJson; // JSON complet du signalement
  
  @HiveField(2)
  late DateTime cachedAt;

  CachedReport();

  CachedReport.create({
    required this.reportId,
    required this.reportJson,
    required this.cachedAt,
  });
}

// Modèle pour les filtres de synchronisation des signalements
class ReportSyncFilters {
  final String? status;
  final String? priority;
  final String? reportType;
  final String? search;
  final bool? sort;

  ReportSyncFilters({
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

// Modèle de requête de synchronisation pour signalements
class ReportSyncRequest {
  final bool? isInitializing;
  final String? globalChecksum;
  final List<Map<String, dynamic>>? itemsChecksums;
  final ReportSyncFilters? filters;

  ReportSyncRequest({
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

// Modèle de réponse de synchronisation pour signalements
class ReportSyncResponse {
  final String syncType;
  final String? globalChecksum;
  final String? message;
  final ReportSyncChanges? changes;
  final ReportSyncStats? stats;
  final String? timestamp;
  final List<Map<String, dynamic>>? items; // Pour full sync

  ReportSyncResponse({
    required this.syncType,
    this.globalChecksum,
    this.message,
    this.changes,
    this.stats,
    this.timestamp,
    this.items,
  });

  factory ReportSyncResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return ReportSyncResponse(
      syncType: data['sync_type'] ?? 'unknown',
      globalChecksum: data['global_checksum'],
      message: data['message'] ?? json['message'],
      changes: data['changes'] != null ? ReportSyncChanges.fromJson(data['changes']) : null,
      stats: data['stats'] != null ? ReportSyncStats.fromJson(data['stats']) : null,
      timestamp: data['timestamp'],
      items: data['items'] != null ? List<Map<String, dynamic>>.from(data['items']) : null,
    );
  }

  bool get isFullSync => syncType == 'full';
  bool get isNoSync => syncType == 'none';
  bool get isDifferentialSync => syncType == 'differential';
  bool get hasChanges => changes != null && changes!.hasChanges;
}

// Modèle des changements dans la synchronisation des signalements
class ReportSyncChanges {
  final List<dynamic> added;    // L'API renvoie des listes imbriquées
  final List<dynamic> updated;  // L'API renvoie des listes imbriquées
  final List<String> deleted;

  ReportSyncChanges({
    required this.added,
    required this.updated,
    required this.deleted,
  });

  factory ReportSyncChanges.fromJson(Map<String, dynamic> json) {
    return ReportSyncChanges(
      added: List<dynamic>.from(json['added'] ?? []),
      updated: List<dynamic>.from(json['updated'] ?? []),
      deleted: List<String>.from(json['deleted'] ?? []),
    );
  }

  bool get hasChanges => added.isNotEmpty || updated.isNotEmpty || deleted.isNotEmpty;
  int get totalChanges => added.length + updated.length + deleted.length;
}

// Modèle des statistiques de synchronisation des signalements
class ReportSyncStats {
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final int totalServer;

  ReportSyncStats({
    required this.addedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.totalServer,
  });

  factory ReportSyncStats.fromJson(Map<String, dynamic> json) {
    return ReportSyncStats(
      addedCount: json['added_count'] ?? 0,
      updatedCount: json['updated_count'] ?? 0,
      deletedCount: json['deleted_count'] ?? 0,
      totalServer: json['total_server'] ?? 0,
    );
  }

  int get totalChanges => addedCount + updatedCount + deletedCount;
}

// États de synchronisation pour signalements
enum ReportSyncStatus {
  idle,
  syncing,
  success,
  error,
}

// Types d'opérations de synchronisation pour signalements
enum ReportSyncOperation {
  fullSync,        // Synchronisation complète (première fois)
  checkSync,       // Vérification avec checksums
  filterSync,      // Application de filtres uniquement
}

// Résultat d'une opération de synchronisation pour signalements
class ReportSyncResult {
  final ReportSyncOperation operation;
  final bool hasChanges;
  final List<dynamic> reports; // ReportModel sera défini dans le controller
  final String message;
  final ReportSyncStats? stats;
  final ReportSyncChanges? changes;

  ReportSyncResult({
    required this.operation,
    required this.hasChanges,
    required this.reports,
    required this.message,
    this.stats,
    this.changes,
  });

  bool get isSuccessful => reports.isNotEmpty || !hasChanges;
}

// Résultat de validation des données locales pour signalements
class ReportSyncValidation {
  final bool isValid;
  final List<String> issues;
  final int reportCount;
  final int checksumCount;

  ReportSyncValidation({
    required this.isValid,
    required this.issues,
    required this.reportCount,
    required this.checksumCount,
  });

  String get summary => isValid 
      ? 'Validation réussie: $reportCount signalements, $checksumCount checksums'
      : 'Validation échouée: ${issues.length} problème${issues.length > 1 ? 's' : ''}';
}