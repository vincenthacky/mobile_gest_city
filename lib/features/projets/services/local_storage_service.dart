import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sync_models.dart';

class LocalStorageService {
  static Isar? _isar;
  
  /// Instance singleton d'Isar
  static Future<Isar> get instance async {
    if (_isar != null) return _isar!;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ProjectChecksumSchema],
      directory: dir.path,
    );
    
    return _isar!;
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Sauvegarde un checksum de projet
  static Future<void> saveProjectChecksum(String projectId, String checksum) async {
    final isar = await instance;
    
    final projectChecksum = ProjectChecksum.create(
      projectId: projectId,
      checksum: checksum,
      lastUpdated: DateTime.now(),
    );

    await isar.writeTxn(() async {
      await isar.projectChecksums.put(projectChecksum);
    });
  }

  /// Sauvegarde une liste de checksums de projets
  static Future<void> saveProjectChecksums(Map<String, String> projectChecksums) async {
    final isar = await instance;
    final now = DateTime.now();
    
    final checksums = projectChecksums.entries.map((entry) {
      return ProjectChecksum.create(
        projectId: entry.key,
        checksum: entry.value,
        lastUpdated: now,
      );
    }).toList();

    await isar.writeTxn(() async {
      await isar.projectChecksums.putAll(checksums);
    });
  }

  /// Récupère le checksum d'un projet spécifique
  static Future<String?> getProjectChecksum(String projectId) async {
    final isar = await instance;
    
    final projectChecksum = await isar.projectChecksums
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
        
    return projectChecksum?.checksum;
  }

  /// Récupère tous les checksums de projets
  static Future<List<ProjectChecksum>> getAllProjectChecksums() async {
    final isar = await instance;
    return await isar.projectChecksums.where().findAll();
  }

  /// Récupère les checksums sous forme de Map pour l'API
  static Future<List<Map<String, dynamic>>> getChecksumsForApi() async {
    final checksums = await getAllProjectChecksums();
    return checksums.map((checksum) => checksum.toJson()).toList();
  }

  /// Met à jour le checksum d'un projet existant
  static Future<void> updateProjectChecksum(String projectId, String newChecksum) async {
    final isar = await instance;
    
    final existingChecksum = await isar.projectChecksums
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();

    if (existingChecksum != null) {
      existingChecksum.checksum = newChecksum;
      existingChecksum.lastUpdated = DateTime.now();

      await isar.writeTxn(() async {
        await isar.projectChecksums.put(existingChecksum);
      });
    } else {
      await saveProjectChecksum(projectId, newChecksum);
    }
  }

  /// Supprime le checksum d'un projet
  static Future<void> deleteProjectChecksum(String projectId) async {
    final isar = await instance;
    
    await isar.writeTxn(() async {
      await isar.projectChecksums
          .filter()
          .projectIdEqualTo(projectId)
          .deleteAll();
    });
  }

  /// Supprime une liste de checksums de projets
  static Future<void> deleteProjectChecksums(List<String> projectIds) async {
    final isar = await instance;
    
    await isar.writeTxn(() async {
      for (final projectId in projectIds) {
        await isar.projectChecksums
            .filter()
            .projectIdEqualTo(projectId)
            .deleteAll();
      }
    });
  }

  /// Supprime tous les checksums (utile pour reset complet)
  static Future<void> clearAllChecksums() async {
    final isar = await instance;
    
    await isar.writeTxn(() async {
      await isar.projectChecksums.clear();
    });
  }

  /// Vérifie si un projet a un checksum stocké localement
  static Future<bool> hasProjectChecksum(String projectId) async {
    final checksum = await getProjectChecksum(projectId);
    return checksum != null;
  }

  /// Récupère le nombre total de checksums stockés
  static Future<int> getChecksumsCount() async {
    final isar = await instance;
    return await isar.projectChecksums.count();
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