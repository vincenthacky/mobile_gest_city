import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_models.dart';
import '../models/report_model.dart';

class ReportLocalStorageService {
  static const String _checksumBoxName = 'report_checksums';
  static const String _reportsBoxName = 'cached_reports';
  static Box<ReportChecksum>? _checksumBox;
  static Box<CachedReport>? _reportsBox;
  
  /// Initialise Hive et ouvre les boxes pour signalements
  static Future<Box<ReportChecksum>> get instance async {
    if (_checksumBox != null && _checksumBox!.isOpen) return _checksumBox!;
    
    await Hive.initFlutter();
    
    // Enregistrer les adaptateurs pour signalements si pas déjà fait
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(ReportChecksumAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(CachedReportAdapter());
    }
    
    _checksumBox = await Hive.openBox<ReportChecksum>(_checksumBoxName);
    _reportsBox = await Hive.openBox<CachedReport>(_reportsBoxName);
    
    print('✅ [REPORTS] Boxes créées pour les signalements');
    
    return _checksumBox!;
  }

  /// Ouvre la box des signalements
  static Future<Box<CachedReport>> get reportsBox async {
    await instance; // S'assurer que tout est initialisé
    return _reportsBox!;
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _checksumBox?.close();
    await _reportsBox?.close();
    _checksumBox = null;
    _reportsBox = null;
  }

  /// Sauvegarde un checksum de signalement
  static Future<void> saveReportChecksum(String reportId, String checksum) async {
    final box = await instance;
    
    final reportChecksum = ReportChecksum.create(
      reportId: reportId,
      checksum: checksum,
      lastUpdated: DateTime.now(),
      receptionOrder: 0, // Ordre arbitraire pour sauvegarde individuelle
    );

    await box.put(reportId, reportChecksum);
  }

  /// Sauvegarde une liste de checksums de signalements AVEC ordre de réception
  static Future<void> saveReportChecksumsWithOrder(
    List<ReportModel> reports, 
    Map<String, String> reportChecksums
  ) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, ReportChecksum>{};
    
    // Respecter l'ordre de réception depuis l'API
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      final checksum = reportChecksums[report.id];
      
      if (checksum != null) {
        checksums[report.id] = ReportChecksum.create(
          reportId: report.id,
          checksum: checksum,
          lastUpdated: now,
          receptionOrder: i, // Préserver l'ordre de réception
        );
      }
    }

    await box.putAll(checksums);
  }

  /// Sauvegarde une liste de checksums de signalements (méthode legacy)
  static Future<void> saveReportChecksums(Map<String, String> reportChecksums) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, ReportChecksum>{};
    int order = 0;
    for (final entry in reportChecksums.entries) {
      checksums[entry.key] = ReportChecksum.create(
        reportId: entry.key,
        checksum: entry.value,
        lastUpdated: now,
        receptionOrder: order++, // Ordre arbitraire pour legacy
      );
    }

    await box.putAll(checksums);
  }

  /// Récupère le checksum d'un signalement spécifique
  static Future<String?> getReportChecksum(String reportId) async {
    final box = await instance;
    final reportChecksum = box.get(reportId);
    return reportChecksum?.checksum;
  }

  /// Récupère tous les checksums de signalements
  static Future<List<ReportChecksum>> getAllReportChecksums() async {
    final box = await instance;
    return box.values.toList();
  }

  /// Récupère les checksums sous forme de Map pour l'API
  /// RESPECTE l'ordre de réception depuis l'API Laravel
  static Future<List<Map<String, dynamic>>> getChecksumsForApi() async {
    final checksums = await getAllReportChecksums();
    
    // TRIER par ordre de réception pour correspondre à l'ordre Laravel
    checksums.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));
    
    return checksums.map((checksum) => checksum.toJson()).toList();
  }

  /// Met à jour le checksum d'un signalement existant
  static Future<void> updateReportChecksum(String reportId, String newChecksum) async {
    final box = await instance;
    
    final existingChecksum = box.get(reportId);

    if (existingChecksum != null) {
      existingChecksum.checksum = newChecksum;
      existingChecksum.lastUpdated = DateTime.now();
      await box.put(reportId, existingChecksum);
    } else {
      await saveReportChecksum(reportId, newChecksum);
    }
  }

  /// Supprime le checksum d'un signalement
  static Future<void> deleteReportChecksum(String reportId) async {
    final box = await instance;
    await box.delete(reportId);
  }

  /// Supprime une liste de checksums de signalements
  static Future<void> deleteReportChecksums(List<String> reportIds) async {
    final box = await instance;
    await box.deleteAll(reportIds);
  }

  /// Supprime tous les checksums (utile pour reset complet)
  static Future<void> clearAllChecksums() async {
    final box = await instance;
    await box.clear();
  }

  /// Vérifie si un signalement a un checksum stocké localement
  static Future<bool> hasReportChecksum(String reportId) async {
    final checksum = await getReportChecksum(reportId);
    return checksum != null;
  }

  /// Récupère le nombre total de checksums stockés
  static Future<int> getChecksumsCount() async {
    final box = await instance;
    return box.length;
  }

  /// Synchronise les checksums locaux avec une liste de signalements
  /// Supprime les checksums des signalements qui ne sont plus dans la liste
  static Future<void> syncChecksumsWithReports(List<String> currentReportIds) async {
    final box = await instance;
    final allChecksums = await getAllReportChecksums();
    
    final checksumsToDelete = allChecksums
        .where((checksum) => !currentReportIds.contains(checksum.reportId))
        .map((checksum) => checksum.reportId)
        .toList();
    
    if (checksumsToDelete.isNotEmpty) {
      await deleteReportChecksums(checksumsToDelete);
    }
  }

  /// Obtient les statistiques de stockage local
  static Future<Map<String, dynamic>> getStorageStats() async {
    final checksumCount = await getChecksumsCount();
    final allChecksums = await getAllReportChecksums();
    
    final now = DateTime.now();
    final recentChecksums = allChecksums.where((checksum) {
      final diff = now.difference(checksum.lastUpdated);
      return diff.inDays <= 7; // Modifiés dans les 7 derniers jours
    }).length;

    return {
      'total_checksums': checksumCount,
      'recent_checksums': recentChecksums,
      'oldest_checksum': allChecksums.isEmpty 
          ? null 
          : allChecksums.map((c) => c.lastUpdated).reduce((a, b) => a.isBefore(b) ? a : b),
      'newest_checksum': allChecksums.isEmpty 
          ? null 
          : allChecksums.map((c) => c.lastUpdated).reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  // ============ MÉTHODES POUR LES SIGNALEMENTS COMPLETS ============

  /// Sauvegarde les signalements complets dans le cache local
  /// FUSION INTELLIGENTE : Met à jour ou ajoute les signalements sans effacer les autres
  static Future<void> saveCachedReports(List<ReportModel> reports, {bool replaceAll = false}) async {
    final box = await reportsBox;
    final now = DateTime.now();
    
    if (replaceAll) {
      // Mode remplacement complet (utilisé pour full sync)
      final cachedReports = <String, CachedReport>{};
      for (final report in reports) {
        final reportJson = jsonEncode(report.toJson());
        cachedReports[report.id] = CachedReport.create(
          reportId: report.id,
          reportJson: reportJson,
          cachedAt: now,
        );
      }
      await box.clear();
      await box.putAll(cachedReports);
      print('💾 [CACHE] ${reports.length} signalements remplacés complètement en cache');
    } else {
      // Mode fusion intelligente (par défaut)
      final cachedReports = <String, CachedReport>{};
      for (final report in reports) {
        final reportJson = jsonEncode(report.toJson());
        cachedReports[report.id] = CachedReport.create(
          reportId: report.id,
          reportJson: reportJson,
          cachedAt: now,
        );
      }
      // Fusion : met à jour ou ajoute, sans effacer les autres
      await box.putAll(cachedReports);
      print('💾 [CACHE] ${reports.length} signalements fusionnés en cache (total: ${box.length})');
    }
  }

  /// Récupère tous les signalements en cache
  static Future<List<ReportModel>> getCachedReports() async {
    final box = await reportsBox;
    final cachedReports = box.values.toList();
    
    print('📂 [CACHE] ${cachedReports.length} entrées trouvées dans la box cached_reports');
    
    final reports = <ReportModel>[];
    for (final cached in cachedReports) {
      try {
        print('🔄 [CACHE] Désérialisation du signalement ${cached.reportId}');
        final reportJson = jsonDecode(cached.reportJson) as Map<String, dynamic>;
        print('📋 [CACHE] JSON décodé pour ${cached.reportId}: ${reportJson.keys}');
        
        final report = ReportModel.fromJson(reportJson);
        reports.add(report);
        print('✅ [CACHE] Signalement ${cached.reportId} désérialisé avec succès - titre: "${report.title}"');
      } catch (e, stackTrace) {
        print('❌ [CACHE] Erreur lors du décodage du signalement ${cached.reportId}: $e');
        print('🔍 [CACHE] StackTrace: $stackTrace');
        print('📄 [CACHE] JSON brut: ${cached.reportJson.substring(0, 200)}...');
      }
    }
    
    print('📱 [CACHE] ${reports.length} signalements récupérés du cache avec succès');
    return reports;
  }

  /// Supprime tous les signalements en cache
  static Future<void> clearCachedReports() async {
    final box = await reportsBox;
    await box.clear();
    print('🗑️ [CACHE] Tous les signalements en cache supprimés');
  }

  /// Vérifie si on a des signalements en cache
  static Future<bool> hasCachedReports() async {
    final box = await reportsBox;
    return box.isNotEmpty;
  }

  /// Récupère le nombre de signalements en cache
  static Future<int> getCachedReportsCount() async {
    final box = await reportsBox;
    return box.length;
  }

  /// Supprime une liste de signalements du cache
  static Future<void> removeCachedReports(List<String> reportIds) async {
    final box = await reportsBox;
    await box.deleteAll(reportIds);
    print('🗑️ [CACHE] ${reportIds.length} signalements supprimés du cache');
  }
}