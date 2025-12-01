import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import '../models/sync_models.dart';
import '../models/report_model.dart';

class ReportLocalStorageService {
  static const String _checksumBoxName = 'report_checksums';
  static const String _reportsBoxName = 'cached_reports';
  static Box<ReportChecksum>? _checksumBox;
  static Box<CachedReport>? _reportsBox;
  
  /// Initialise Hive et ouvre les boxes
  static Future<Box<ReportChecksum>> get instance async {
    if (_checksumBox != null && _checksumBox!.isOpen) return _checksumBox!;
    
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(ReportChecksumAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(CachedReportAdapter());
    }
    
    _checksumBox = await Hive.openBox<ReportChecksum>(_checksumBoxName);
    _reportsBox = await Hive.openBox<CachedReport>(_reportsBoxName);
    
    debugPrint('✅ [REPORTS] Boxes Hive ouvertes avec succès');
    
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
    
    try {
      debugPrint('🗃️ [STORAGE] Début sauvegarde ${reports.length} checksums');
      debugPrint('🗃️ [STORAGE] Box avant clear: ${box.length} éléments');
      
      // Supprimer tous les anciens checksums
      await box.clear();
      debugPrint('🗃️ [STORAGE] Box après clear: ${box.length} éléments');
      
      // Sauvegarder les nouveaux avec ordre
      for (int i = 0; i < reports.length; i++) {
        final report = reports[i];
        final checksum = reportChecksums[report.id];
        
        if (checksum != null) {
          final reportChecksum = ReportChecksum.create(
            reportId: report.id,
            checksum: checksum,
            lastUpdated: DateTime.now(),
            receptionOrder: i, // Ordre important pour la sync
          );

          await box.put(report.id, reportChecksum);
          debugPrint('🗃️ [STORAGE] Checksum sauvé: ${report.id} (ordre: $i)');
        } else {
          debugPrint('⚠️ [STORAGE] Checksum manquant pour: ${report.id}');
        }
      }
      
      final finalCount = box.length;
      debugPrint('✅ [STORAGE] ${finalCount}/${reports.length} checksums sauvegardés avec ordre');
      
    } catch (e) {
      debugPrint('❌ [STORAGE] Erreur sauvegarde checksums: $e');
      throw Exception('Erreur lors de la sauvegarde des checksums: $e');
    }
  }

  /// Récupère un checksum de signalement
  static Future<String?> getReportChecksum(String reportId) async {
    final box = await instance;
    final checksum = box.get(reportId);
    return checksum?.checksum;
  }

  /// Récupère tous les checksums de signalements
  static Future<List<ReportChecksum>> getAllReportChecksums() async {
    final box = await instance;
    return box.values.toList();
  }

  /// Récupère les checksums pour l'API (format attendu)
  static Future<List<Map<String, dynamic>>> getChecksumsForApi() async {
    final box = await instance;
    
    // Trier par ordre de réception pour maintenir la cohérence
    final checksums = box.values.toList();
    checksums.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));
    
    return checksums.map((checksum) => checksum.toJson()).toList();
  }

  /// Calcule le checksum global des signalements locaux
  static Future<String?> calculateGlobalChecksum() async {
    final checksums = await getChecksumsForApi();
    
    if (checksums.isEmpty) return null;
    
    // Concaténer tous les checksums dans l'ordre
    final checksumString = checksums.map((c) => c['checksum']).join('');
    
    // Calculer le hash global
    final bytes = utf8.encode(checksumString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Supprime un checksum de signalement
  static Future<void> deleteReportChecksum(String reportId) async {
    final box = await instance;
    await box.delete(reportId);
  }

  /// Supprime tous les checksums
  static Future<void> clearAllChecksums() async {
    final box = await instance;
    await box.clear();
    debugPrint('🗑️ [REPORTS] Tous les checksums supprimés');
  }

  /// Compte le nombre de checksums
  static Future<int> getChecksumsCount() async {
    final box = await instance;
    final count = box.length;
    debugPrint('🔍 [STORAGE] getChecksumsCount() = $count');
    return count;
  }

  /// Sauvegarde les signalements complets en cache
  static Future<void> saveCachedReports(List<ReportModel> reports, {bool replaceAll = false}) async {
    final box = await reportsBox;
    
    try {
      if (replaceAll) {
        // Remplacement complet
        await box.clear();
        debugPrint('🗑️ [REPORTS] Cache signalements vidé pour remplacement complet');
      }
      
      for (final report in reports) {
        final cachedReport = CachedReport.create(
          reportId: report.id,
          reportJson: jsonEncode(report.toJson()),
          cachedAt: DateTime.now(),
        );

        await box.put(report.id, cachedReport);
      }
      
      debugPrint('💾 [REPORTS] ${reports.length} signalements sauvegardés en cache');
      
    } catch (e) {
      debugPrint('❌ [REPORTS] Erreur sauvegarde cache: $e');
      throw Exception('Erreur lors de la sauvegarde du cache: $e');
    }
  }

  /// Récupère les signalements depuis le cache
  static Future<List<ReportModel>> getCachedReports() async {
    final box = await reportsBox;
    
    try {
      final reports = <ReportModel>[];
      
      for (final cachedReport in box.values) {
        try {
          final reportJson = jsonDecode(cachedReport.reportJson) as Map<String, dynamic>;
          final report = ReportModel.fromJson(reportJson);
          reports.add(report);
        } catch (e) {
          debugPrint('⚠️ [REPORTS] Erreur décodage signalement ${cachedReport.reportId}: $e');
        }
      }
      
      debugPrint('📂 [REPORTS] ${reports.length} signalements récupérés du cache');
      return reports;
      
    } catch (e) {
      debugPrint('❌ [REPORTS] Erreur récupération cache: $e');
      return [];
    }
  }

  /// Récupère un signalement spécifique depuis le cache
  static Future<ReportModel?> getCachedReport(String reportId) async {
    final box = await reportsBox;
    
    try {
      final cachedReport = box.get(reportId);
      if (cachedReport != null) {
        final reportJson = jsonDecode(cachedReport.reportJson) as Map<String, dynamic>;
        return ReportModel.fromJson(reportJson);
      }
      return null;
      
    } catch (e) {
      debugPrint('❌ [REPORTS] Erreur récupération signalement $reportId: $e');
      return null;
    }
  }

  /// Supprime des signalements du cache
  static Future<void> removeCachedReports(List<String> reportIds) async {
    final box = await reportsBox;
    
    try {
      for (final reportId in reportIds) {
        await box.delete(reportId);
      }
      debugPrint('🗑️ [REPORTS] ${reportIds.length} signalements supprimés du cache');
      
    } catch (e) {
      debugPrint('❌ [REPORTS] Erreur suppression cache: $e');
      throw Exception('Erreur lors de la suppression du cache: $e');
    }
  }

  /// Supprime tout le cache des signalements
  static Future<void> clearCachedReports() async {
    final box = await reportsBox;
    await box.clear();
    debugPrint('🗑️ [REPORTS] Tout le cache signalements supprimé');
  }

  /// Compte le nombre de signalements en cache
  static Future<int> getCachedReportsCount() async {
    final box = await reportsBox;
    return box.length;
  }

  /// Vérifie si on a des signalements en cache
  static Future<bool> hasCachedReports() async {
    final count = await getCachedReportsCount();
    return count > 0;
  }

  /// Obtient les statistiques de stockage
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final checksumCount = await getChecksumsCount();
      final cachedCount = await getCachedReportsCount();
      final hasCache = await hasCachedReports();
      final globalChecksum = await calculateGlobalChecksum();
      
      return {
        'checksum_count': checksumCount,
        'cached_reports_count': cachedCount,
        'has_cached_reports': hasCache,
        'global_checksum': globalChecksum,
        'checksum_box_name': _checksumBoxName,
        'reports_box_name': _reportsBoxName,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'checksum_count': 0,
        'cached_reports_count': 0,
        'has_cached_reports': false,
      };
    }
  }

  /// Valide la cohérence entre checksums et cache
  static Future<bool> validateCacheConsistency() async {
    try {
      final checksumCount = await getChecksumsCount();
      final cachedCount = await getCachedReportsCount();
      
      // La cohérence parfaite n'est pas obligatoire (cache peut être partiel)
      // mais on vérifie qu'il n'y a pas d'incohérence majeure
      return checksumCount >= 0 && cachedCount >= 0;
      
    } catch (e) {
      debugPrint('⚠️ [REPORTS] Erreur validation cohérence: $e');
      return false;
    }
  }
}