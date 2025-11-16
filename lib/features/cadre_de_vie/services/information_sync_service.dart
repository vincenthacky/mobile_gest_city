import '../models/sync_models.dart';
import '../models/information_model.dart';
import 'information_checksum_service.dart';
import 'information_local_storage_service.dart';

class InformationSyncService {
  /// Détermine le type d'opération de synchronisation nécessaire
  static Future<InformationSyncOperation> determineSyncOperation({
    InformationSyncFilters? filters,
    bool forceFullSync = false,
  }) async {
    if (forceFullSync) {
      return InformationSyncOperation.fullSync;
    }

    // Si on a des filtres uniquement, c'est un filter sync
    if (filters != null && !filters.isEmpty) {
      final hasLocalData = await InformationLocalStorageService.getChecksumsCount() > 0;
      if (!hasLocalData) {
        return InformationSyncOperation.fullSync;
      }
      return InformationSyncOperation.filterSync;
    }

    // Si on n'a pas de données locales, c'est un full sync
    final hasLocalData = await InformationLocalStorageService.getChecksumsCount() > 0;
    if (!hasLocalData) {
      return InformationSyncOperation.fullSync;
    }

    // Sinon, c'est une vérification avec checksums
    return InformationSyncOperation.checkSync;
  }

  /// Prépare une requête de synchronisation selon le type d'opération
  static Future<InformationSyncRequest> prepareSyncRequest({
    required InformationSyncOperation operation,
    InformationSyncFilters? filters,
  }) async {
    switch (operation) {
      case InformationSyncOperation.fullSync:
        return InformationSyncRequest(
          isInitializing: true,
          filters: filters,
        );

      case InformationSyncOperation.filterSync:
        return InformationSyncRequest(
          filters: filters,
        );

      case InformationSyncOperation.checkSync:
        final checksums = await InformationLocalStorageService.getChecksumsForApi();
        final globalChecksum = checksums.isNotEmpty 
            ? InformationChecksumService.calculateGlobalChecksumFromStrings(
                checksums.map((c) => c['checksum'] as String).toList()
              )
            : null;

        return InformationSyncRequest(
          globalChecksum: globalChecksum,
          itemsChecksums: checksums,
          filters: filters,
        );
    }
  }

  /// Traite une réponse de synchronisation
  static Future<InformationSyncResult> processSyncResponse(
    InformationSyncResponse response,
    List<InformationModel> currentInformations,
  ) async {
    switch (response.syncType) {
      case 'full':
        return await _processFullSync(response);
      
      case 'none':
        return InformationSyncResult(
          operation: InformationSyncOperation.checkSync,
          hasChanges: false,
          informations: currentInformations,
          message: response.message ?? 'Aucune synchronisation nécessaire',
        );
      
      case 'differential':
        return await _processDifferentialSync(response, currentInformations);
      
      default:
        throw Exception('Type de synchronisation non reconnu: ${response.syncType}');
    }
  }

  /// Traite une synchronisation complète
  static Future<InformationSyncResult> _processFullSync(InformationSyncResponse response) async {
    if (response.items == null) {
      throw Exception('Aucun élément reçu pour la synchronisation complète');
    }

    final informations = response.items!
        .map((json) => InformationModel.fromJson(json))
        .toList();

    // Sauvegarder les nouveaux checksums
    await _saveInformationChecksums(informations);

    return InformationSyncResult(
      operation: InformationSyncOperation.fullSync,
      hasChanges: true,
      informations: informations,
      message: 'Synchronisation complète effectuée (${informations.length} informations)',
      stats: response.stats,
    );
  }

  /// Traite une synchronisation différentielle
  static Future<InformationSyncResult> _processDifferentialSync(
    InformationSyncResponse response,
    List<InformationModel> currentInformations,
  ) async {
    if (response.changes == null) {
      return InformationSyncResult(
        operation: InformationSyncOperation.checkSync,
        hasChanges: false,
        informations: currentInformations,
        message: 'Aucun changement détecté',
      );
    }

    final changes = response.changes!;
    final updatedInformations = List<InformationModel>.from(currentInformations);

    // Traiter les suppressions
    for (final deletedId in changes.deleted) {
      updatedInformations.removeWhere((information) => information.id == deletedId);
      await InformationLocalStorageService.deleteInformationChecksum(deletedId);
    }

    // Traiter les ajouts - l'API renvoie des listes imbriquées
    final addedInformations = <InformationModel>[];
    final addedChecksums = <String, String>{};
    for (final item in changes.added) {
      if (item is List && item.isNotEmpty) {
        // Chaque "added" est une liste contenant une seule information avec checksum
        final informationWithChecksum = item.first as Map<String, dynamic>;
        
        // ✅ EXTRAIRE le checksum de l'API (ne pas recalculer)
        final informationId = informationWithChecksum['id'] as String;
        final apiChecksum = informationWithChecksum['checksum'] as String;
        addedChecksums[informationId] = apiChecksum;
        
        // Créer le InformationModel (sans le checksum dans les données)
        final informationData = Map<String, dynamic>.from(informationWithChecksum);
        informationData.remove('checksum'); // Supprimer checksum des données information
        addedInformations.add(InformationModel.fromJson(informationData));
      }
    }
    
    updatedInformations.addAll(addedInformations);

    // Traiter les mises à jour - même structure
    final updatedInformationsList = <InformationModel>[];
    final updatedChecksums = <String, String>{};
    for (final item in changes.updated) {
      if (item is List && item.isNotEmpty) {
        // Chaque "updated" est une liste contenant une seule information avec checksum
        final informationWithChecksum = item.first as Map<String, dynamic>;
        
        // ✅ EXTRAIRE le checksum de l'API (ne pas recalculer)
        final informationId = informationWithChecksum['id'] as String;
        final apiChecksum = informationWithChecksum['checksum'] as String;
        updatedChecksums[informationId] = apiChecksum;
        
        // Créer le InformationModel (sans le checksum dans les données)
        final informationData = Map<String, dynamic>.from(informationWithChecksum);
        informationData.remove('checksum'); // Supprimer checksum des données information
        updatedInformationsList.add(InformationModel.fromJson(informationData));
      }
    }

    for (final updatedInformation in updatedInformationsList) {
      final index = updatedInformations.indexWhere((i) => i.id == updatedInformation.id);
      if (index != -1) {
        updatedInformations[index] = updatedInformation;
      } else {
        updatedInformations.add(updatedInformation);
      }
    }

    // Sauvegarder les checksums pour les informations ajoutées et modifiées
    final allChangedInformations = [...addedInformations, ...updatedInformationsList];
    final allApiChecksums = <String, String>{};
    allApiChecksums.addAll(addedChecksums);
    allApiChecksums.addAll(updatedChecksums);
    
    // ✅ UTILISER les checksums de l'API (ne pas recalculer)
    await _saveInformationChecksumsWithApiData(allChangedInformations, allApiChecksums);

    return InformationSyncResult(
      operation: InformationSyncOperation.checkSync,
      hasChanges: true,
      informations: updatedInformations,
      message: _buildChangeMessage(changes),
      stats: response.stats,
      changes: changes,
    );
  }

  /// Sauvegarde les checksums des informations ET les informations complètes
  /// UTILISE les checksums fournis par l'API (ne recalcule PAS)
  static Future<void> _saveInformationChecksumsWithApiData(
    List<InformationModel> informations, 
    Map<String, String> apiChecksums
  ) async {
    if (informations.isNotEmpty) {
      // ✅ UTILISER les checksums de l'API directement
      await InformationLocalStorageService.saveInformationChecksumsWithOrder(informations, apiChecksums);
      
      // Sauvegarder les informations complètes en cache
      await InformationLocalStorageService.saveCachedInformations(informations);
    }
  }

  /// Sauvegarde les checksums des informations ET les informations complètes (méthode legacy - recalcule)
  static Future<void> _saveInformationChecksums(List<InformationModel> informations) async {
    final checksums = <String, String>{};
    
    for (int i = 0; i < informations.length; i++) {
      final information = informations[i];
      final informationJson = information.toJson();
      final checksum = InformationChecksumService.calculateInformationChecksum(informationJson);
      checksums[information.id] = checksum;
    }

    if (checksums.isNotEmpty) {
      // Sauvegarder les checksums AVEC l'ordre de réception
      await InformationLocalStorageService.saveInformationChecksumsWithOrder(informations, checksums);
      
      // Sauvegarder les informations complètes en cache
      await InformationLocalStorageService.saveCachedInformations(informations);
    }
  }

  /// Construit le message de changement
  static String _buildChangeMessage(InformationSyncChanges changes) {
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
    await InformationLocalStorageService.clearAllChecksums();
    await InformationLocalStorageService.clearCachedInformations();
  }

  /// Obtient les statistiques de synchronisation locale
  static Future<Map<String, dynamic>> getSyncStats() async {
    return await InformationLocalStorageService.getStorageStats();
  }

  /// Valide la cohérence des données locales
  static Future<InformationSyncValidation> validateLocalData(List<InformationModel> informations) async {
    final issues = <String>[];
    final storedChecksums = await InformationLocalStorageService.getAllInformationChecksums();
    
    // Vérifier que toutes les informations ont un checksum
    for (final information in informations) {
      final hasChecksum = storedChecksums.any((c) => c.informationId == information.id);
      if (!hasChecksum) {
        issues.add('Information ${information.id} n\'a pas de checksum stocké');
      }
    }

    // Vérifier les checksums orphelins
    for (final checksum in storedChecksums) {
      final hasInformation = informations.any((i) => i.id == checksum.informationId);
      if (!hasInformation) {
        issues.add('Checksum orphelin pour l\'information ${checksum.informationId}');
      }
    }

    return InformationSyncValidation(
      isValid: issues.isEmpty,
      issues: issues,
      informationCount: informations.length,
      checksumCount: storedChecksums.length,
    );
  }
}