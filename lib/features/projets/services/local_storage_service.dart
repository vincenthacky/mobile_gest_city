import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_models.dart';
import '../models/project_model.dart';

class LocalStorageService {
  static const String _checksumBoxName = 'project_checksums';
  static const String _projectsBoxName = 'cached_projects';
  static Box<ProjectChecksum>? _checksumBox;
  static Box<CachedProject>? _projectsBox;
  
  /// Initialise Hive et ouvre les boxes
  static Future<Box<ProjectChecksum>> get instance async {
    if (_checksumBox != null && _checksumBox!.isOpen) return _checksumBox!;
    
    await Hive.initFlutter();
    
    // 🧹 MIGRATION: Supprimer complètement les anciennes boxes pour corriger statuts
    // MIGRATION TERMINÉE - Correction sérialisation statuts validée
    // try {
    //   await Hive.deleteBoxFromDisk(_checksumBoxName);
    //   await Hive.deleteBoxFromDisk(_projectsBoxName);
    //   print('🧹 [MIGRATION] Anciennes boxes supprimées du disque - Correction sérialisation statuts');
    // } catch (e) {
    //   print('ℹ️ [MIGRATION] Pas d\'anciennes boxes à supprimer: $e');
    // }
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectChecksumAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedProjectAdapter());
    }
    
    _checksumBox = await Hive.openBox<ProjectChecksum>(_checksumBoxName);
    _projectsBox = await Hive.openBox<CachedProject>(_projectsBoxName);
    
    print('✅ [MIGRATION] Nouvelles boxes créées avec receptionOrder');
    
    return _checksumBox!;
  }

  /// Ouvre la box des projets
  static Future<Box<CachedProject>> get projectsBox async {
    await instance; // S'assurer que tout est initialisé
    return _projectsBox!;
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _checksumBox?.close();
    await _projectsBox?.close();
    _checksumBox = null;
    _projectsBox = null;
  }

  /// Sauvegarde un checksum de projet
  static Future<void> saveProjectChecksum(String projectId, String checksum) async {
    final box = await instance;
    
    final projectChecksum = ProjectChecksum.create(
      projectId: projectId,
      checksum: checksum,
      lastUpdated: DateTime.now(),
      receptionOrder: 0, // Ordre arbitraire pour sauvegarde individuelle
    );

    await box.put(projectId, projectChecksum);
  }

  /// Sauvegarde une liste de checksums de projets AVEC ordre de réception
  static Future<void> saveProjectChecksumsWithOrder(
    List<ProjectModel> projects, 
    Map<String, String> projectChecksums
  ) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, ProjectChecksum>{};
    
    // Respecter l'ordre de réception depuis l'API
    for (int i = 0; i < projects.length; i++) {
      final project = projects[i];
      final checksum = projectChecksums[project.id];
      
      if (checksum != null) {
        checksums[project.id] = ProjectChecksum.create(
          projectId: project.id,
          checksum: checksum,
          lastUpdated: now,
          receptionOrder: i, // Préserver l'ordre de réception
        );
      }
    }

    await box.putAll(checksums);
  }

  /// Sauvegarde une liste de checksums de projets (méthode legacy)
  static Future<void> saveProjectChecksums(Map<String, String> projectChecksums) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, ProjectChecksum>{};
    int order = 0;
    for (final entry in projectChecksums.entries) {
      checksums[entry.key] = ProjectChecksum.create(
        projectId: entry.key,
        checksum: entry.value,
        lastUpdated: now,
        receptionOrder: order++, // Ordre arbitraire pour legacy
      );
    }

    await box.putAll(checksums);
  }

  /// Récupère le checksum d'un projet spécifique
  static Future<String?> getProjectChecksum(String projectId) async {
    final box = await instance;
    final projectChecksum = box.get(projectId);
    return projectChecksum?.checksum;
  }

  /// Récupère tous les checksums de projets
  static Future<List<ProjectChecksum>> getAllProjectChecksums() async {
    final box = await instance;
    return box.values.toList();
  }

  /// Récupère les checksums sous forme de Map pour l'API
  /// RESPECTE l'ordre de réception depuis l'API Laravel
  static Future<List<Map<String, dynamic>>> getChecksumsForApi() async {
    final checksums = await getAllProjectChecksums();
    
    // TRIER par ordre de réception pour correspondre à l'ordre Laravel
    checksums.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));
    
    return checksums.map((checksum) => checksum.toJson()).toList();
  }

  /// Met à jour le checksum d'un projet existant
  static Future<void> updateProjectChecksum(String projectId, String newChecksum) async {
    final box = await instance;
    
    final existingChecksum = box.get(projectId);

    if (existingChecksum != null) {
      existingChecksum.checksum = newChecksum;
      existingChecksum.lastUpdated = DateTime.now();
      await box.put(projectId, existingChecksum);
    } else {
      await saveProjectChecksum(projectId, newChecksum);
    }
  }

  /// Supprime le checksum d'un projet
  static Future<void> deleteProjectChecksum(String projectId) async {
    final box = await instance;
    await box.delete(projectId);
  }

  /// Supprime une liste de checksums de projets
  static Future<void> deleteProjectChecksums(List<String> projectIds) async {
    final box = await instance;
    await box.deleteAll(projectIds);
  }

  /// Supprime tous les checksums (utile pour reset complet)
  static Future<void> clearAllChecksums() async {
    final box = await instance;
    await box.clear();
  }

  /// Vérifie si un projet a un checksum stocké localement
  static Future<bool> hasProjectChecksum(String projectId) async {
    final checksum = await getProjectChecksum(projectId);
    return checksum != null;
  }

  /// Récupère le nombre total de checksums stockés
  static Future<int> getChecksumsCount() async {
    final box = await instance;
    return box.length;
  }

  /// Synchronise les checksums locaux avec une liste de projets
  /// Supprime les checksums des projets qui ne sont plus dans la liste
  static Future<void> syncChecksumsWithProjects(List<String> currentProjectIds) async {
    final isar = await instance;
    final allChecksums = await getAllProjectChecksums();
    
    final checksumsToDelete = allChecksums
        .where((checksum) => !currentProjectIds.contains(checksum.projectId))
        .map((checksum) => checksum.projectId)
        .toList();
    
    if (checksumsToDelete.isNotEmpty) {
      await deleteProjectChecksums(checksumsToDelete);
    }
  }

  /// Obtient les statistiques de stockage local
  static Future<Map<String, dynamic>> getStorageStats() async {
    final checksumCount = await getChecksumsCount();
    final allChecksums = await getAllProjectChecksums();
    
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

  // ============ MÉTHODES POUR LES PROJETS COMPLETS ============

  /// Sauvegarde les projets complets dans le cache local
  static Future<void> saveCachedProjects(List<ProjectModel> projects) async {
    final box = await projectsBox;
    final now = DateTime.now();
    
    final cachedProjects = <String, CachedProject>{};
    for (final project in projects) {
      final projectJson = jsonEncode(project.toJson());
      cachedProjects[project.id] = CachedProject.create(
        projectId: project.id,
        projectJson: projectJson,
        cachedAt: now,
      );
    }

    await box.clear(); // Efface les anciens projets
    await box.putAll(cachedProjects);
    print('💾 [CACHE] ${projects.length} projets sauvegardés en cache');
  }

  /// Récupère tous les projets en cache
  static Future<List<ProjectModel>> getCachedProjects() async {
    final box = await projectsBox;
    final cachedProjects = box.values.toList();
    
    print('📂 [CACHE] ${cachedProjects.length} entrées trouvées dans la box cached_projects');
    
    final projects = <ProjectModel>[];
    for (final cached in cachedProjects) {
      try {
        print('🔄 [CACHE] Désérialisation du projet ${cached.projectId}');
        final projectJson = jsonDecode(cached.projectJson) as Map<String, dynamic>;
        print('📋 [CACHE] JSON décodé pour ${cached.projectId}: ${projectJson.keys}');
        
        final project = ProjectModel.fromJson(projectJson);
        projects.add(project);
        print('✅ [CACHE] Projet ${cached.projectId} désérialisé avec succès - titre: "${project.title}"');
      } catch (e, stackTrace) {
        print('❌ [CACHE] Erreur lors du décodage du projet ${cached.projectId}: $e');
        print('🔍 [CACHE] StackTrace: $stackTrace');
        print('📄 [CACHE] JSON brut: ${cached.projectJson.substring(0, 200)}...');
      }
    }
    
    print('📱 [CACHE] ${projects.length} projets récupérés du cache avec succès');
    return projects;
  }

  /// Supprime tous les projets en cache
  static Future<void> clearCachedProjects() async {
    final box = await projectsBox;
    await box.clear();
    print('🗑️  [CACHE] Tous les projets en cache supprimés');
  }

  /// Vérifie si on a des projets en cache
  static Future<bool> hasCachedProjects() async {
    final box = await projectsBox;
    return box.isNotEmpty;
  }

  /// Récupère le nombre de projets en cache
  static Future<int> getCachedProjectsCount() async {
    final box = await projectsBox;
    return box.length;
  }
}