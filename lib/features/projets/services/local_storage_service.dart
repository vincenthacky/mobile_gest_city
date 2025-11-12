import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_models.dart';

class LocalStorageService {
  static const String _boxName = 'project_checksums';
  static Box<ProjectChecksum>? _box;
  
  /// Initialise Hive et ouvre la box
  static Future<Box<ProjectChecksum>> get instance async {
    if (_box != null && _box!.isOpen) return _box!;
    
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectChecksumAdapter());
    }
    
    _box = await Hive.openBox<ProjectChecksum>(_boxName);
    return _box!;
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Sauvegarde un checksum de projet
  static Future<void> saveProjectChecksum(String projectId, String checksum) async {
    final box = await instance;
    
    final projectChecksum = ProjectChecksum.create(
      projectId: projectId,
      checksum: checksum,
      lastUpdated: DateTime.now(),
    );

    await box.put(projectId, projectChecksum);
  }

  /// Sauvegarde une liste de checksums de projets
  static Future<void> saveProjectChecksums(Map<String, String> projectChecksums) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, ProjectChecksum>{};
    for (final entry in projectChecksums.entries) {
      checksums[entry.key] = ProjectChecksum.create(
        projectId: entry.key,
        checksum: entry.value,
        lastUpdated: now,
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
  static Future<List<Map<String, dynamic>>> getChecksumsForApi() async {
    final checksums = await getAllProjectChecksums();
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
}