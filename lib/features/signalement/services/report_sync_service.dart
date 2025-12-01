import 'package:flutter/foundation.dart';
import '../models/sync_models.dart';
import '../models/report_model.dart';
import 'report_checksum_service.dart';
import 'report_local_storage_service.dart';

class ReportSyncService {
  /// Détermine le type d'opération de synchronisation nécessaire
  static Future<ReportSyncOperation> determineSyncOperation({
    ReportSyncFilters? filters,
    bool forceFullSync = false,
  }) async {
    if (forceFullSync) {
      debugPrint('🔄 [SYNC_OPERATION] Force full sync demandé');
      return ReportSyncOperation.fullSync;
    }

    // Vérifier le nombre de checksums stockés
    final checksumCount = await ReportLocalStorageService.getChecksumsCount();
    final cachedReportsCount = await ReportLocalStorageService.getCachedReportsCount();
    debugPrint('🔍 [SYNC_OPERATION] Checksums stockés: $checksumCount, Rapports en cache: $cachedReportsCount');

    // Si on a des filtres uniquement, c'est un filter sync
    if (filters != null && !filters.isEmpty) {
      debugPrint('🔍 [SYNC_OPERATION] Filtres détectés: ${filters.toJson()}');
      if (checksumCount == 0) {
        debugPrint('🔄 [SYNC_OPERATION] → FULL SYNC (pas de checksums pour filtres)');
        return ReportSyncOperation.fullSync;
      }
      debugPrint('🔄 [SYNC_OPERATION] → FILTER SYNC');
      return ReportSyncOperation.filterSync;
    }

    // Si on n'a pas de données locales, c'est un full sync
    if (checksumCount == 0) {
      debugPrint('🔄 [SYNC_OPERATION] → FULL SYNC (aucun checksum stocké)');
      return ReportSyncOperation.fullSync;
    }

    // Sinon, c'est une vérification avec checksums
    debugPrint('🔄 [SYNC_OPERATION] → CHECK SYNC (${checksumCount} checksums disponibles)');
    return ReportSyncOperation.checkSync;
  }

  /// Prépare une requête de synchronisation selon le type d'opération
  static Future<ReportSyncRequest> prepareSyncRequest({
    required ReportSyncOperation operation,
    ReportSyncFilters? filters,
  }) async {
    switch (operation) {
      case ReportSyncOperation.fullSync:
        return ReportSyncRequest(
          isInitializing: true,
          filters: filters,
        );

      case ReportSyncOperation.filterSync:
        return ReportSyncRequest(
          filters: filters,
        );

      case ReportSyncOperation.checkSync:
        final checksums = await ReportLocalStorageService.getChecksumsForApi();
        final globalChecksum = checksums.isNotEmpty 
            ? ReportChecksumService.calculateGlobalChecksumFromStrings(
                checksums.map((c) => c['checksum'] as String).toList()
              )
            : null;

        return ReportSyncRequest(
          globalChecksum: globalChecksum,
          itemsChecksums: checksums,
          filters: filters,
        );
    }
  }

  /// Traite une réponse de synchronisation
  static Future<ReportSyncResult> processSyncResponse(
    ReportSyncResponse response,
    List<ReportModel> currentReports,
  ) async {
    switch (response.syncType) {
      case 'full':
        return await _processFullSync(response);
      
      case 'none':
        return ReportSyncResult(
          operation: ReportSyncOperation.checkSync,
          hasChanges: false,
          reports: currentReports,
          message: response.message ?? 'Aucune synchronisation nécessaire',
        );
      
      case 'differential':
        return await _processDifferentialSync(response, currentReports);
      
      default:
        throw Exception('Type de synchronisation non reconnu: ${response.syncType}');
    }
  }

  /// Traite une synchronisation complète
  static Future<ReportSyncResult> _processFullSync(ReportSyncResponse response) async {
    if (response.items == null) {
      throw Exception('Aucun élément reçu pour la synchronisation complète');
    }

    final reports = response.items!
        .map((json) => ReportModel.fromJson(json))
        .toList();

    // Sauvegarder les nouveaux checksums
    await _saveReportChecksums(reports);

    return ReportSyncResult(
      operation: ReportSyncOperation.fullSync,
      hasChanges: true,
      reports: reports,
      message: 'Synchronisation complète effectuée (${reports.length} signalements)',
      stats: response.stats,
    );
  }

  /// Traite une synchronisation différentielle
  static Future<ReportSyncResult> _processDifferentialSync(
    ReportSyncResponse response,
    List<ReportModel> currentReports,
  ) async {
    debugPrint('🔄 [DIFF_SYNC] Début sync différentielle avec ${currentReports.length} signalements locaux');
    
    if (response.changes == null) {
      debugPrint('🔄 [DIFF_SYNC] Aucun changement dans la réponse');
      return ReportSyncResult(
        operation: ReportSyncOperation.checkSync,
        hasChanges: false,
        reports: currentReports,
        message: 'Aucun changement détecté',
      );
    }

    final changes = response.changes!;
    debugPrint('🔄 [DIFF_SYNC] Changements: ${changes.added.length} ajouts, ${changes.updated.length} modifs, ${changes.deleted.length} suppressions');
    final updatedReports = List<ReportModel>.from(currentReports);

    // Traiter les suppressions
    final deletedIds = <String>[];
    for (final deletedId in changes.deleted) {
      updatedReports.removeWhere((report) => report.id == deletedId);
      await ReportLocalStorageService.deleteReportChecksum(deletedId);
      deletedIds.add(deletedId);
    }
    
    // Supprimer les signalements supprimés du cache
    if (deletedIds.isNotEmpty) {
      await ReportLocalStorageService.removeCachedReports(deletedIds);
    }

    // Traiter les ajouts - l'API renvoie directement un tableau d'objets
    final addedReports = <ReportModel>[];
    final addedChecksums = <String, String>{};
    debugPrint('🔄 [DIFF_SYNC] Traitement de ${changes.added.length} ajouts');
    
    for (int i = 0; i < changes.added.length; i++) {
      final item = changes.added[i];
      debugPrint('🔄 [DIFF_SYNC] Ajout $i: type=${item.runtimeType}');
      
      if (item is Map<String, dynamic>) {
        // L'API renvoie directement les signalements avec checksum
        final reportWithChecksum = item;
        
        // ✅ EXTRAIRE le checksum de l'API (ne pas recalculer)
        final reportId = reportWithChecksum['id'] as String;
        final apiChecksum = reportWithChecksum['checksum'] as String;
        addedChecksums[reportId] = apiChecksum;
        debugPrint('🔄 [DIFF_SYNC] Signalement ajouté: $reportId, checksum: ${apiChecksum.substring(0, 8)}...');
        
        // Créer le ReportModel (sans le checksum dans les données)
        final reportData = Map<String, dynamic>.from(reportWithChecksum);
        reportData.remove('checksum'); // Supprimer checksum des données signalement
        addedReports.add(ReportModel.fromJson(reportData));
      } else {
        debugPrint('⚠️ [DIFF_SYNC] Format d\'ajout inattendu: ${item.runtimeType} - $item');
      }
    }
    
    debugPrint('🔄 [DIFF_SYNC] ${addedReports.length} signalements traités pour ajout');
    
    updatedReports.addAll(addedReports);

    // Traiter les mises à jour - même structure
    final updatedReportsList = <ReportModel>[];
    final updatedChecksums = <String, String>{};
    debugPrint('🔄 [DIFF_SYNC] Traitement de ${changes.updated.length} mises à jour');
    
    for (final item in changes.updated) {
      if (item is Map<String, dynamic>) {
        // L'API renvoie directement les signalements avec checksum
        final reportWithChecksum = item;
        
        // ✅ EXTRAIRE le checksum de l'API (ne pas recalculer)
        final reportId = reportWithChecksum['id'] as String;
        final apiChecksum = reportWithChecksum['checksum'] as String;
        updatedChecksums[reportId] = apiChecksum;
        debugPrint('🔄 [DIFF_SYNC] Signalement modifié: $reportId, checksum: ${apiChecksum.substring(0, 8)}...');
        
        // Créer le ReportModel (sans le checksum dans les données)
        final reportData = Map<String, dynamic>.from(reportWithChecksum);
        reportData.remove('checksum'); // Supprimer checksum des données signalement
        updatedReportsList.add(ReportModel.fromJson(reportData));
      } else {
        debugPrint('⚠️ [DIFF_SYNC] Format de mise à jour inattendu: ${item.runtimeType} - $item');
      }
    }

    for (final updatedReport in updatedReportsList) {
      final index = updatedReports.indexWhere((r) => r.id == updatedReport.id);
      if (index != -1) {
        updatedReports[index] = updatedReport;
      } else {
        updatedReports.add(updatedReport);
      }
    }

    // Sauvegarder les checksums pour les signalements ajoutés et modifiés
    final allChangedReports = [...addedReports, ...updatedReportsList];
    final allApiChecksums = <String, String>{};
    allApiChecksums.addAll(addedChecksums);
    allApiChecksums.addAll(updatedChecksums);
    
    // ✅ UTILISER les checksums de l'API (ne pas recalculer)
    await _saveReportChecksumsWithApiData(allChangedReports, allApiChecksums);
    
    // ✅ FUSION INTELLIGENTE: Sauvegarder TOUS les signalements (anciens + nouveaux)
    await _saveMergedReports(updatedReports, allChangedReports);

    debugPrint('🔄 [DIFF_SYNC] Résultat final: ${updatedReports.length} signalements au total');
    return ReportSyncResult(
      operation: ReportSyncOperation.checkSync,
      hasChanges: true,
      reports: updatedReports,
      message: _buildChangeMessage(changes),
      stats: response.stats,
      changes: changes,
    );
  }

  /// Sauvegarde les checksums des signalements ET les signalements complets
  /// UTILISE les checksums fournis par l'API (ne recalcule PAS)
  static Future<void> _saveReportChecksumsWithApiData(
    List<ReportModel> reports, 
    Map<String, String> apiChecksums
  ) async {
    if (reports.isNotEmpty) {
      // ✅ UTILISER les checksums de l'API directement
      await ReportLocalStorageService.saveReportChecksumsWithOrder(reports, apiChecksums);
    }
  }
  
  /// Sauvegarde la liste complète des signalements avec fusion intelligente
  static Future<void> _saveMergedReports(
    List<ReportModel> allReports,
    List<ReportModel> changedReports
  ) async {
    if (changedReports.isNotEmpty) {
      // Sauvegarder seulement les signalements changés (fusion)
      await ReportLocalStorageService.saveCachedReports(changedReports);
    }
  }

  /// Sauvegarde les checksums des signalements ET les signalements complets (méthode legacy - recalcule)
  static Future<void> _saveReportChecksums(List<ReportModel> reports) async {
    debugPrint('💾 [SAVE_CHECKSUMS] Début sauvegarde de ${reports.length} checksums');
    final checksums = <String, String>{};
    
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      final reportJson = report.toJson();
      final checksum = ReportChecksumService.calculateReportChecksum(reportJson);
      checksums[report.id] = checksum;
    }
    debugPrint('💾 [SAVE_CHECKSUMS] ${checksums.length} checksums calculés');

    if (checksums.isNotEmpty) {
      // Sauvegarder les checksums AVEC l'ordre de réception
      debugPrint('💾 [SAVE_CHECKSUMS] Sauvegarde des checksums en cours...');
      await ReportLocalStorageService.saveReportChecksumsWithOrder(reports, checksums);
      
      // Pour full sync : remplacement complet
      debugPrint('💾 [SAVE_CHECKSUMS] Sauvegarde du cache complet en cours...');
      await ReportLocalStorageService.saveCachedReports(reports, replaceAll: true);
      
      // Vérification post-sauvegarde
      final savedCount = await ReportLocalStorageService.getChecksumsCount();
      final cachedCount = await ReportLocalStorageService.getCachedReportsCount();
      debugPrint('✅ [SAVE_CHECKSUMS] Terminé - Checksums: $savedCount, Cache: $cachedCount');
    } else {
      debugPrint('⚠️ [SAVE_CHECKSUMS] Aucun checksum à sauvegarder');
    }
  }

  /// Construit le message de changement
  static String _buildChangeMessage(ReportSyncChanges changes) {
    final parts = <String>[];
    
    if (changes.added.isNotEmpty) {
      parts.add('${changes.added.length} ajouté${changes.added.length > 1 ? 's' : ''}');
    }
    
    if (changes.updated.isNotEmpty) {
      parts.add('${changes.updated.length} modifié${changes.updated.length > 1 ? 's' : ''}');
    }
    
    if (changes.deleted.isNotEmpty) {
      parts.add('${changes.deleted.length} supprimé${changes.deleted.length > 1 ? 's' : ''}');
    }

    if (parts.isEmpty) {
      return 'Aucun changement';
    }

    return 'Synchronisation effectuée: ${parts.join(', ')}';
  }

  /// Nettoie les données locales (utile pour debug/reset)
  static Future<void> clearLocalData() async {
    await ReportLocalStorageService.clearAllChecksums();
    await ReportLocalStorageService.clearCachedReports();
  }

  /// Obtient les statistiques de synchronisation locale
  static Future<Map<String, dynamic>> getSyncStats() async {
    return await ReportLocalStorageService.getStorageStats();
  }

  /// Valide la cohérence des données locales
  static Future<ReportSyncValidation> validateLocalData(List<ReportModel> reports) async {
    final issues = <String>[];
    final storedChecksums = await ReportLocalStorageService.getAllReportChecksums();
    
    // Vérifier que tous les signalements ont un checksum
    for (final report in reports) {
      final hasChecksum = storedChecksums.any((c) => c.reportId == report.id);
      if (!hasChecksum) {
        issues.add('Signalement ${report.id} n\'a pas de checksum stocké');
      }
    }

    // Vérifier les checksums orphelins
    for (final checksum in storedChecksums) {
      final hasReport = reports.any((r) => r.id == checksum.reportId);
      if (!hasReport) {
        issues.add('Checksum orphelin pour le signalement ${checksum.reportId}');
      }
    }

    return ReportSyncValidation(
      isValid: issues.isEmpty,
      issues: issues,
      reportCount: reports.length,
      checksumCount: storedChecksums.length,
    );
  }
}