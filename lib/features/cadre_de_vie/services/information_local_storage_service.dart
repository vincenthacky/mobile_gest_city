import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_models.dart';
import '../models/information_model.dart';

class InformationLocalStorageService {
  static const String _checksumBoxName = 'information_checksums';
  static const String _informationsBoxName = 'cached_informations';
  static Box<InformationChecksum>? _checksumBox;
  static Box<CachedInformation>? _informationsBox;
  
  /// Initialise Hive et ouvre les boxes pour informations
  static Future<Box<InformationChecksum>> get instance async {
    if (_checksumBox != null && _checksumBox!.isOpen) return _checksumBox!;
    
    await Hive.initFlutter();
    
    // Enregistrer les adaptateurs pour informations si pas déjà fait
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(InformationChecksumAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CachedInformationAdapter());
    }
    
    _checksumBox = await Hive.openBox<InformationChecksum>(_checksumBoxName);
    _informationsBox = await Hive.openBox<CachedInformation>(_informationsBoxName);
    
    print('✅ [INFORMATION] Boxes créées pour les informations');
    
    return _checksumBox!;
  }

  /// Ouvre la box des informations
  static Future<Box<CachedInformation>> get informationsBox async {
    await instance; // S'assurer que tout est initialisé
    return _informationsBox!;
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _checksumBox?.close();
    await _informationsBox?.close();
    _checksumBox = null;
    _informationsBox = null;
  }

  /// Sauvegarde un checksum d'information
  static Future<void> saveInformationChecksum(String informationId, String checksum) async {
    final box = await instance;
    
    final informationChecksum = InformationChecksum.create(
      informationId: informationId,
      checksum: checksum,
      lastUpdated: DateTime.now(),
      receptionOrder: 0, // Ordre arbitraire pour sauvegarde individuelle
    );

    await box.put(informationId, informationChecksum);
  }

  /// Sauvegarde une liste de checksums d'informations AVEC ordre de réception
  static Future<void> saveInformationChecksumsWithOrder(
    List<InformationModel> informations, 
    Map<String, String> informationChecksums
  ) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, InformationChecksum>{};
    
    // Respecter l'ordre de réception depuis l'API
    for (int i = 0; i < informations.length; i++) {
      final information = informations[i];
      final checksum = informationChecksums[information.id];
      
      if (checksum != null) {
        checksums[information.id] = InformationChecksum.create(
          informationId: information.id,
          checksum: checksum,
          lastUpdated: now,
          receptionOrder: i, // Préserver l'ordre de réception
        );
      }
    }

    await box.putAll(checksums);
  }

  /// Sauvegarde une liste de checksums d'informations (méthode legacy)
  static Future<void> saveInformationChecksums(Map<String, String> informationChecksums) async {
    final box = await instance;
    final now = DateTime.now();
    
    final checksums = <String, InformationChecksum>{};
    int order = 0;
    for (final entry in informationChecksums.entries) {
      checksums[entry.key] = InformationChecksum.create(
        informationId: entry.key,
        checksum: entry.value,
        lastUpdated: now,
        receptionOrder: order++, // Ordre arbitraire pour legacy
      );
    }

    await box.putAll(checksums);
  }

  /// Récupère le checksum d'une information spécifique
  static Future<String?> getInformationChecksum(String informationId) async {
    final box = await instance;
    final informationChecksum = box.get(informationId);
    return informationChecksum?.checksum;
  }

  /// Récupère tous les checksums d'informations
  static Future<List<InformationChecksum>> getAllInformationChecksums() async {
    final box = await instance;
    return box.values.toList();
  }

  /// Récupère les checksums sous forme de Map pour l'API
  /// RESPECTE l'ordre de réception depuis l'API Laravel
  static Future<List<Map<String, dynamic>>> getChecksumsForApi() async {
    final checksums = await getAllInformationChecksums();
    
    // TRIER par ordre de réception pour correspondre à l'ordre Laravel
    checksums.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));
    
    return checksums.map((checksum) => checksum.toJson()).toList();
  }

  /// Met à jour le checksum d'une information existante
  static Future<void> updateInformationChecksum(String informationId, String newChecksum) async {
    final box = await instance;
    
    final existingChecksum = box.get(informationId);

    if (existingChecksum != null) {
      existingChecksum.checksum = newChecksum;
      existingChecksum.lastUpdated = DateTime.now();
      await box.put(informationId, existingChecksum);
    } else {
      await saveInformationChecksum(informationId, newChecksum);
    }
  }

  /// Supprime le checksum d'une information
  static Future<void> deleteInformationChecksum(String informationId) async {
    final box = await instance;
    await box.delete(informationId);
  }

  /// Supprime une liste de checksums d'informations
  static Future<void> deleteInformationChecksums(List<String> informationIds) async {
    final box = await instance;
    await box.deleteAll(informationIds);
  }

  /// Supprime tous les checksums (utile pour reset complet)
  static Future<void> clearAllChecksums() async {
    final box = await instance;
    await box.clear();
  }

  /// Vérifie si une information a un checksum stocké localement
  static Future<bool> hasInformationChecksum(String informationId) async {
    final checksum = await getInformationChecksum(informationId);
    return checksum != null;
  }

  /// Récupère le nombre total de checksums stockés
  static Future<int> getChecksumsCount() async {
    final box = await instance;
    return box.length;
  }

  /// Synchronise les checksums locaux avec une liste d'informations
  /// Supprime les checksums des informations qui ne sont plus dans la liste
  static Future<void> syncChecksumsWithInformations(List<String> currentInformationIds) async {
    final box = await instance;
    final allChecksums = await getAllInformationChecksums();
    
    final checksumsToDelete = allChecksums
        .where((checksum) => !currentInformationIds.contains(checksum.informationId))
        .map((checksum) => checksum.informationId)
        .toList();
    
    if (checksumsToDelete.isNotEmpty) {
      await deleteInformationChecksums(checksumsToDelete);
    }
  }

  /// Obtient les statistiques de stockage local
  static Future<Map<String, dynamic>> getStorageStats() async {
    final checksumCount = await getChecksumsCount();
    final allChecksums = await getAllInformationChecksums();
    
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

  // ============ MÉTHODES POUR LES INFORMATIONS COMPLÈTES ============

  /// Sauvegarde les informations complètes dans le cache local
  /// FUSION INTELLIGENTE : Met à jour ou ajoute les informations sans effacer les autres
  static Future<void> saveCachedInformations(List<InformationModel> informations, {bool replaceAll = false}) async {
    final box = await informationsBox;
    final now = DateTime.now();
    
    if (replaceAll) {
      // Mode remplacement complet (utilisé pour full sync)
      final cachedInformations = <String, CachedInformation>{};
      for (final information in informations) {
        final informationJson = jsonEncode(information.toJson());
        cachedInformations[information.id] = CachedInformation.create(
          informationId: information.id,
          informationJson: informationJson,
          cachedAt: now,
        );
      }
      await box.clear();
      await box.putAll(cachedInformations);
      print('💾 [CACHE] ${informations.length} informations remplacées complètement en cache');
    } else {
      // Mode fusion intelligente (par défaut)
      final cachedInformations = <String, CachedInformation>{};
      for (final information in informations) {
        final informationJson = jsonEncode(information.toJson());
        cachedInformations[information.id] = CachedInformation.create(
          informationId: information.id,
          informationJson: informationJson,
          cachedAt: now,
        );
      }
      // Fusion : met à jour ou ajoute, sans effacer les autres
      await box.putAll(cachedInformations);
      print('💾 [CACHE] ${informations.length} informations fusionnées en cache (total: ${box.length})');
    }
  }

  /// Récupère toutes les informations en cache
  static Future<List<InformationModel>> getCachedInformations() async {
    final box = await informationsBox;
    final cachedInformations = box.values.toList();
    
    print('📂 [CACHE] ${cachedInformations.length} entrées trouvées dans la box cached_informations');
    
    final informations = <InformationModel>[];
    for (final cached in cachedInformations) {
      try {
        print('🔄 [CACHE] Désérialisation de l\'information ${cached.informationId}');
        final informationJson = jsonDecode(cached.informationJson) as Map<String, dynamic>;
        print('📋 [CACHE] JSON décodé pour ${cached.informationId}: ${informationJson.keys}');
        
        final information = InformationModel.fromJson(informationJson);
        informations.add(information);
        print('✅ [CACHE] Information ${cached.informationId} désérialisée avec succès - titre: "${information.title}"');
      } catch (e, stackTrace) {
        print('❌ [CACHE] Erreur lors du décodage de l\'information ${cached.informationId}: $e');
        print('🔍 [CACHE] StackTrace: $stackTrace');
        print('📄 [CACHE] JSON brut: ${cached.informationJson.substring(0, 200)}...');
      }
    }
    
    print('📱 [CACHE] ${informations.length} informations récupérées du cache avec succès');
    return informations;
  }

  /// Supprime des informations spécifiques du cache
  static Future<void> removeCachedInformations(List<String> informationIds) async {
    final box = await informationsBox;
    await box.deleteAll(informationIds);
    print('🗑️ [CACHE] ${informationIds.length} informations supprimées du cache');
  }

  /// Supprime toutes les informations en cache
  static Future<void> clearCachedInformations() async {
    final box = await informationsBox;
    await box.clear();
    print('🗑️ [CACHE] Toutes les informations en cache supprimées');
  }

  /// Vérifie si on a des informations en cache
  static Future<bool> hasCachedInformations() async {
    final box = await informationsBox;
    return box.isNotEmpty;
  }

  /// Récupère le nombre d'informations en cache
  static Future<int> getCachedInformationsCount() async {
    final box = await informationsBox;
    return box.length;
  }
}