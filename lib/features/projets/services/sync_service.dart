import '../models/sync_models.dart';
import '../models/project_model.dart';
import 'checksum_service.dart';
import 'local_storage_service.dart';

class SyncService {
  /// Détermine le type d'opération de synchronisation nécessaire
  static Future<SyncOperation> determineSyncOperation({
    SyncFilters? filters,
    bool forceFullSync = false,
  }) async {
    if (forceFullSync) {
      return SyncOperation.fullSync;
    }

    // Si on a des filtres uniquement, c'est un filter sync
    if (filters != null && !filters.isEmpty) {
      final hasLocalData = await LocalStorageService.getChecksumsCount() > 0;
      if (!hasLocalData) {
        return SyncOperation.fullSync;
      }
      return SyncOperation.filterSync;
    }

    // Si on n'a pas de données locales, c'est un full sync
    final hasLocalData = await LocalStorageService.getChecksumsCount() > 0;
    if (!hasLocalData) {
      return SyncOperation.fullSync;
    }

    // Sinon, c'est une vérification avec checksums
    return SyncOperation.checkSync;
  }

  /// Prépare une requête de synchronisation selon le type d'opération
  static Future<SyncRequest> prepareSyncRequest({
    required SyncOperation operation,
    SyncFilters? filters,
  }) async {
    switch (operation) {
      case SyncOperation.fullSync:
        return SyncRequest(
          isInitializing: true,
          filters: filters,
        );

      case SyncOperation.filterSync:
        return SyncRequest(
          filters: filters,
        );

      case SyncOperation.checkSync:
        final checksums = await LocalStorageService.getChecksumsForApi();
        final globalChecksum = checksums.isNotEmpty 
            ? ChecksumService.calculateGlobalChecksum(checksums)
            : null;

        return SyncRequest(
          globalChecksum: globalChecksum,
          itemsChecksums: checksums,
          filters: filters,
        );
    }
  }

  /// Traite une réponse de synchronisation
  static Future<SyncResult> processSyncResponse(
    SyncResponse response,
    List<ProjectModel> currentProjects,
  ) async {
    switch (response.syncType) {
      case 'full':
        return await _processFullSync(response);
      
      case 'none':
        return SyncResult(
          operation: SyncOperation.checkSync,
          hasChanges: false,
          projects: currentProjects,
          message: response.message ?? 'Aucune synchronisation nécessaire',
        );
      
      case 'differential':
        return await _processDifferentialSync(response, currentProjects);
      
      default:
        throw Exception('Type de synchronisation non reconnu: ${response.syncType}');
    }
  }

  /// Traite une synchronisation complète
  static Future<SyncResult> _processFullSync(SyncResponse response) async {
    if (response.items == null) {
      throw Exception('Aucun élément reçu pour la synchronisation complète');
    }

    final projects = response.items!
        .map((json) => ProjectModel.fromJson(json))
        .toList();

    // Sauvegarder les nouveaux checksums
    await _saveProjectChecksums(projects);

    return SyncResult(
      operation: SyncOperation.fullSync,
      hasChanges: true,
      projects: projects,
      message: 'Synchronisation complète effectuée (${projects.length} projets)',
      stats: response.stats,
    );
  }

  /// Traite une synchronisation différentielle
  static Future<SyncResult> _processDifferentialSync(
    SyncResponse response,
    List<ProjectModel> currentProjects,
  ) async {
    if (response.changes == null) {
      return SyncResult(
        operation: SyncOperation.checkSync,
        hasChanges: false,
        projects: currentProjects,
        message: 'Aucun changement détecté',
      );
    }

    final changes = response.changes!;
    final updatedProjects = List<ProjectModel>.from(currentProjects);

    // Traiter les suppressions
    for (final deletedId in changes.deleted) {
      updatedProjects.removeWhere((project) => project.id == deletedId);
      await LocalStorageService.deleteProjectChecksum(deletedId);
    }

    // Traiter les ajouts
    final addedProjects = changes.added
        .map((json) => ProjectModel.fromJson(json))
        .toList();
    
    updatedProjects.addAll(addedProjects);

    // Traiter les mises à jour
    final updatedProjectsList = changes.updated
        .map((json) => ProjectModel.fromJson(json))
        .toList();

    for (final updatedProject in updatedProjectsList) {
      final index = updatedProjects.indexWhere((p) => p.id == updatedProject.id);
      if (index != -1) {
        updatedProjects[index] = updatedProject;
      } else {
        updatedProjects.add(updatedProject);
      }
    }

    // Sauvegarder les checksums pour les projets ajoutés et modifiés
    final allChangedProjects = [...addedProjects, ...updatedProjectsList];
    await _saveProjectChecksums(allChangedProjects);

    return SyncResult(
      operation: SyncOperation.checkSync,
      hasChanges: true,
      projects: updatedProjects,
      message: _buildChangeMessage(changes),
      stats: response.stats,
      changes: changes,
    );
  }

  /// Sauvegarde les checksums des projets
  static Future<void> _saveProjectChecksums(List<ProjectModel> projects) async {
    final checksums = <String, String>{};
    
    for (final project in projects) {
      final projectJson = project.toJson();
      final checksum = ChecksumService.calculateProjectChecksum(projectJson);
      checksums[project.id] = checksum;
    }

    if (checksums.isNotEmpty) {
      await LocalStorageService.saveProjectChecksums(checksums);
    }
  }

  /// Construit le message de changement
  static String _buildChangeMessage(SyncChanges changes) {
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
    await LocalStorageService.clearAllChecksums();
  }

  /// Obtient les statistiques de synchronisation locale
  static Future<Map<String, dynamic>> getSyncStats() async {
    return await LocalStorageService.getStorageStats();
  }

  /// Valide la cohérence des données locales
  static Future<SyncValidation> validateLocalData(List<ProjectModel> projects) async {
    final issues = <String>[];
    final storedChecksums = await LocalStorageService.getAllProjectChecksums();
    
    // Vérifier que tous les projets ont un checksum
    for (final project in projects) {
      final hasChecksum = storedChecksums.any((c) => c.projectId == project.id);
      if (!hasChecksum) {
        issues.add('Projet ${project.id} n\'a pas de checksum stocké');
      }
    }

    // Vérifier les checksums orphelins
    for (final checksum in storedChecksums) {
      final hasProject = projects.any((p) => p.id == checksum.projectId);
      if (!hasProject) {
        issues.add('Checksum orphelin pour le projet ${checksum.projectId}');
      }
    }

    return SyncValidation(
      isValid: issues.isEmpty,
      issues: issues,
      projectCount: projects.length,
      checksumCount: storedChecksums.length,
    );
  }
}

/// Résultat d'une opération de synchronisation
class SyncResult {
  final SyncOperation operation;
  final bool hasChanges;
  final List<ProjectModel> projects;
  final String message;
  final SyncStats? stats;
  final SyncChanges? changes;

  SyncResult({
    required this.operation,
    required this.hasChanges,
    required this.projects,
    required this.message,
    this.stats,
    this.changes,
  });

  bool get isSuccessful => projects.isNotEmpty || !hasChanges;
}

/// Résultat de validation des données locales
class SyncValidation {
  final bool isValid;
  final List<String> issues;
  final int projectCount;
  final int checksumCount;

  SyncValidation({
    required this.isValid,
    required this.issues,
    required this.projectCount,
    required this.checksumCount,
  });

  String get summary => isValid 
      ? 'Validation réussie: $projectCount projets, $checksumCount checksums'
      : 'Validation échouée: ${issues.length} problème${issues.length > 1 ? 's' : ''}';
}