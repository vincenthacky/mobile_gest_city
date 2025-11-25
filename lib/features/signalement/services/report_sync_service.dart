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
      return ReportSyncOperation.fullSync;
    }

    // Si on a des filtres uniquement, c'est un filter sync
    if (filters != null && !filters.isEmpty) {
      final hasLocalData = await ReportLocalStorageService.getChecksumsCount() > 0;
      if (!hasLocalData) {
        return ReportSyncOperation.fullSync;
      }
      return ReportSyncOperation.filterSync;
    }

    // Si on n'a pas de données locales, c'est un full sync
    final hasLocalData = await ReportLocalStorageService.getChecksumsCount() > 0;
    if (!hasLocalData) {
      return ReportSyncOperation.fullSync;
    }

    // Sinon, c'est une vérification avec checksums
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
    if (response.changes == null) {
      return ReportSyncResult(
        operation: ReportSyncOperation.checkSync,
        hasChanges: false,
        reports: currentReports,
        message: 'Aucun changement détecté',
      );
    }

    final changes = response.changes!;
    final updatedReports = List<ReportModel>.from(currentReports);

    // Traiter les suppressions
    for (final deletedId in changes.deleted) {
      updatedReports.removeWhere((report) => report.id == deletedId);
      await ReportLocalStorageService.deleteReportChecksum(deletedId);
    }

    // Traiter les ajouts - l'API renvoie des listes imbriquées
    final addedReports = <ReportModel>[];
    final addedChecksums = <String, String>{};
    for (final item in changes.added) {
      if (item is List && item.isNotEmpty) {
        // Chaque "added" est une liste contenant un seul signalement avec checksum
        final reportWithChecksum = item.first as Map<String, dynamic>;
        
        // ✅ EXTRAIRE le checksum de l'API (ne pas recalculer)
        final reportId = reportWithChecksum['id'] as String;
        final apiChecksum = reportWithChecksum['checksum'] as String;
        addedChecksums[reportId] = apiChecksum;
        
        // Créer le ReportModel (sans le checksum dans les données)
        final reportData = Map<String, dynamic>.from(reportWithChecksum);
        reportData.remove('checksum'); // Supprimer checksum des données signalement
        addedReports.add(ReportModel.fromJson(reportData));
      }
    }
    
    updatedReports.addAll(addedReports);

    // Traiter les mises à jour - même structure
    final updatedReportsList = <ReportModel>[];
    final updatedChecksums = <String, String>{};
    for (final item in changes.updated) {
      if (item is List && item.isNotEmpty) {
        // Chaque "updated" est une liste contenant un seul signalement avec checksum
        final reportWithChecksum = item.first as Map<String, dynamic>;
        
        // ✅ EXTRAIRE le checksum de l'API (ne pas recalculer)
        final reportId = reportWithChecksum['id'] as String;
        final apiChecksum = reportWithChecksum['checksum'] as String;
        updatedChecksums[reportId] = apiChecksum;
        
        // Créer le ReportModel (sans le checksum dans les données)
        final reportData = Map<String, dynamic>.from(reportWithChecksum);
        reportData.remove('checksum'); // Supprimer checksum des données signalement
        updatedReportsList.add(ReportModel.fromJson(reportData));
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
    final checksums = <String, String>{};
    
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      final reportJson = report.toJson();
      final checksum = ReportChecksumService.calculateReportChecksum(reportJson);
      checksums[report.id] = checksum;
    }

    if (checksums.isNotEmpty) {
      // Sauvegarder les checksums AVEC l'ordre de réception
      await ReportLocalStorageService.saveReportChecksumsWithOrder(reports, checksums);
      
      // Pour full sync : remplacement complet
      await ReportLocalStorageService.saveCachedReports(reports, replaceAll: true);
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