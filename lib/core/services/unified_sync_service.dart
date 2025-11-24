import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_sync_models.dart';
import '../services/connectivity_service.dart';
import '../../features/projets/data_sources/project_data_source.dart';
import '../../features/signalement/data_sources/signalement_data_source.dart';
import '../../features/cadre_de_vie/data_sources/information_data_source.dart';

/// Service unifié pour gérer toutes les données en attente de synchronisation
class UnifiedSyncService extends ChangeNotifier {
  static const String _boxName = 'unified_pending_sync';
  static Box<PendingSyncItem>? _box;
  
  final ConnectivityService _connectivityService = ConnectivityService();
  final ProjectDataSource _projectDataSource = ProjectDataSource();
  final SignalementDataSource _signalementDataSource = SignalementDataSource();
  final InformationDataSource _informationDataSource = InformationDataSource();
  
  /// Instance singleton
  static final UnifiedSyncService _instance = UnifiedSyncService._internal();
  factory UnifiedSyncService() => _instance;
  
  UnifiedSyncService._internal() {
    // Écouter les changements de connectivité pour synchroniser automatiquement
    _connectivityService.addListener(_onConnectivityChanged);
  }

  /// Initialise Hive et ouvre la box
  static Future<Box<PendingSyncItem>> get instance async {
    if (_box != null && _box!.isOpen) return _box!;
    
    await Hive.initFlutter();
    
    // Enregistrer les adapters si pas déjà fait
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(PendingDataTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(PendingSyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(PendingSyncItemAdapter());
    }
    
    _box = await Hive.openBox<PendingSyncItem>(_boxName);
    return _box!;
  }

  /// Ajoute un projet en attente
  Future<String> addPendingProject({
    required String title,
    required String briefDescription,
    required String detailedDescription,
    required String estimatedBudget,
    required String startDate,
    required String estimatedCompletionDate,
    required String dateLapses,
    required bool withCallForTenders,
    required bool withServiceProvider,
    String? providerName,
    String? providerAmount,
    List<String>? imagePaths,
  }) async {
    final item = PendingSyncItem.project(
      title: title,
      briefDescription: briefDescription,
      detailedDescription: detailedDescription,
      estimatedBudget: estimatedBudget,
      startDate: startDate,
      estimatedCompletionDate: estimatedCompletionDate,
      dateLapses: dateLapses,
      withCallForTenders: withCallForTenders,
      withServiceProvider: withServiceProvider,
      providerName: providerName,
      providerAmount: providerAmount,
      imagePaths: imagePaths,
    );
    
    return await _addPendingItem(item);
  }

  /// Ajoute un signalement en attente
  Future<String> addPendingSignalement({
    required String title,
    required String description,
    required String place,
    required String type,
    required String priority,
    required bool isAnonymous,
    List<String>? imagePaths,
  }) async {
    final item = PendingSyncItem.signalement(
      title: title,
      description: description,
      place: place,
      type: type,
      priority: priority,
      isAnonymous: isAnonymous,
      imagePaths: imagePaths,
    );
    
    return await _addPendingItem(item);
  }

  /// Ajoute une information cadre de vie en attente
  Future<String> addPendingCadreDeVie({
    required String title,
    required String description,
    required String place,
    required String type,
    required String priority,
    List<String>? imagePaths,
  }) async {
    final item = PendingSyncItem.cadreDeVie(
      title: title,
      description: description,
      place: place,
      type: type,
      priority: priority,
      imagePaths: imagePaths,
    );
    
    return await _addPendingItem(item);
  }

  /// Méthode privée pour ajouter un élément en attente
  Future<String> _addPendingItem(PendingSyncItem item) async {
    final box = await instance;
    await box.put(item.id, item);
    
    debugPrint('📤 [SYNC] ${item.typeLabel} "$item.title" ajouté en attente');
    notifyListeners();
    
    // Tenter une synchronisation immédiate si connecté
    if (_connectivityService.isConnected) {
      _syncPendingItems();
    }
    
    return item.id;
  }

  /// Récupère tous les éléments en attente
  Future<List<PendingSyncItem>> getAllPendingItems() async {
    final box = await instance;
    final items = box.values.toList();
    
    // Trier par date de création (plus récent en premier)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return items;
  }

  /// Récupère les éléments par type
  Future<List<PendingSyncItem>> getItemsByType(PendingDataType type) async {
    final box = await instance;
    return box.values.where((item) => item.type == type).toList();
  }

  /// Récupère les éléments par statut
  Future<List<PendingSyncItem>> getItemsByStatus(PendingSyncStatus status) async {
    final box = await instance;
    return box.values.where((item) => item.status == status).toList();
  }

  /// Compte le nombre d'éléments non synchronisés
  Future<int> getUnsyncedCount() async {
    final box = await instance;
    return box.values.where((item) => 
      item.status == PendingSyncStatus.pending || 
      item.status == PendingSyncStatus.failed
    ).length;
  }

  /// Compte par type
  Future<Map<PendingDataType, int>> getCountByType() async {
    final box = await instance;
    final counts = <PendingDataType, int>{};
    
    for (final type in PendingDataType.values) {
      counts[type] = box.values.where((item) => 
        item.type == type && 
        (item.status == PendingSyncStatus.pending || item.status == PendingSyncStatus.failed)
      ).length;
    }
    
    return counts;
  }

  /// Supprime un élément
  Future<void> removePendingItem(String itemId) async {
    final box = await instance;
    await box.delete(itemId);
    
    debugPrint('🗑️ [SYNC] Élément "$itemId" supprimé');
    notifyListeners();
  }

  /// Supprime tous les éléments synchronisés
  Future<void> clearCompletedItems() async {
    final box = await instance;
    final completedKeys = box.values
        .where((item) => item.status == PendingSyncStatus.completed)
        .map((item) => item.id)
        .toList();
    
    await box.deleteAll(completedKeys);
    
    debugPrint('🧹 [SYNC] ${completedKeys.length} éléments synchronisés supprimés');
    notifyListeners();
  }

  /// Synchronise tous les éléments en attente
  Future<void> syncAllPendingItems() async {
    if (!_connectivityService.isConnected) {
      debugPrint('📵 [SYNC] Pas de connexion - synchronisation impossible');
      return;
    }

    await _syncPendingItems();
  }

  /// Synchronise un élément spécifique
  Future<bool> syncItem(String itemId) async {
    if (!_connectivityService.isConnected) {
      debugPrint('📵 [SYNC] Pas de connexion pour synchroniser "$itemId"');
      return false;
    }

    final box = await instance;
    final item = box.get(itemId);
    
    if (item == null) {
      debugPrint('❌ [SYNC] Élément "$itemId" introuvable');
      return false;
    }

    if (!item.canSync) {
      debugPrint('⚠️ [SYNC] Élément "$itemId" ne peut pas être synchronisé (statut: ${item.status})');
      return false;
    }

    return await _syncSingleItem(item);
  }

  /// Remet en attente tous les éléments en échec qui peuvent être retentés
  Future<void> retryFailedItems() async {
    final box = await instance;
    final failedItems = box.values
        .where((item) => item.canRetry)
        .toList();

    for (final item in failedItems) {
      item.resetForRetry();
      await item.save();
    }

    debugPrint('🔄 [SYNC] ${failedItems.length} éléments remis en attente');
    notifyListeners();

    // Tenter la synchronisation si connecté
    if (_connectivityService.isConnected) {
      _syncPendingItems();
    }
  }

  /// Callback appelé lors du changement de connectivité
  void _onConnectivityChanged() {
    if (_connectivityService.isConnected) {
      debugPrint('🌐 [SYNC] Connexion rétablie - synchronisation automatique');
      _syncPendingItems();
    }
  }

  /// Synchronise tous les éléments en attente (méthode privée)
  Future<void> _syncPendingItems() async {
    final pendingItems = await getItemsByStatus(PendingSyncStatus.pending);
    
    if (pendingItems.isEmpty) {
      debugPrint('ℹ️ [SYNC] Aucun élément en attente à synchroniser');
      return;
    }

    debugPrint('🔄 [SYNC] Synchronisation de ${pendingItems.length} éléments');

    int successCount = 0;
    int failureCount = 0;

    for (final item in pendingItems) {
      final success = await _syncSingleItem(item);
      if (success) {
        successCount++;
      } else {
        failureCount++;
      }

      // Petit délai entre les requêtes pour éviter de surcharger l'API
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('✅ [SYNC] Synchronisation terminée: $successCount succès, $failureCount échecs');
    notifyListeners();
  }

  /// Synchronise un élément individuel
  Future<bool> _syncSingleItem(PendingSyncItem item) async {
    try {
      // Marquer comme en cours de synchronisation
      item.markAsSyncing();
      await item.save();
      notifyListeners();

      // Convertir les images en List<File> pour l'API
      final imageFiles = <File>[];
      for (final imagePath in item.imagePaths) {
        if (File(imagePath).existsSync()) {
          imageFiles.add(File(imagePath));
        }
      }

      bool success = false;
      String? syncedId;

      // Appeler l'API appropriée selon le type
      switch (item.type) {
        case PendingDataType.project:
          success = await _syncProject(item, imageFiles);
          break;
        case PendingDataType.signalement:
          success = await _syncSignalement(item, imageFiles);
          break;
        case PendingDataType.cadreDeVie:
          success = await _syncCadreDeVie(item, imageFiles);
          break;
      }

      if (success) {
        item.markAsCompleted(syncedId: syncedId);
        await item.save();
        
        debugPrint('✅ [SYNC] ${item.typeLabel} "${item.title}" synchronisé avec succès');
        return true;
      } else {
        item.markAsError('Erreur de synchronisation');
        await item.save();
        
        debugPrint('❌ [SYNC] Échec synchronisation ${item.typeLabel} "${item.title}"');
        return false;
      }
    } catch (e) {
      item.markAsError(e.toString());
      await item.save();
      
      debugPrint('❌ [SYNC] Erreur synchronisation ${item.typeLabel} "${item.title}": $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Synchronise un projet
  Future<bool> _syncProject(PendingSyncItem item, List<File> imageFiles) async {
    try {
      final data = item.data;
      final response = await _projectDataSource.createProject(
        title: item.title,
        briefDescription: data['brief_description'],
        detailedDescription: data['detailed_description'],
        estimatedBudget: data['estimated_budget'],
        startDate: data['start_date'],
        estimatedCompletionDate: data['estimated_completion_date'],
        dateLapses: data['date_lapses'],
        withCallForTenders: data['with_call_for_tenders'],
        withServiceProvider: data['with_service_provider'],
        images: imageFiles,
      );
      
      return response.success;
    } catch (e) {
      debugPrint('❌ [SYNC] Erreur API projet: $e');
      return false;
    }
  }

  /// Synchronise un signalement
  Future<bool> _syncSignalement(PendingSyncItem item, List<File> imageFiles) async {
    try {
      final data = item.data;
      final response = await _signalementDataSource.createSignalement(
        title: item.title,
        description: data['description'],
        place: data['place'],
        reportType: data['type'],
        priority: data['priority'],
        anonymous: data['is_anonymous'],
        images: imageFiles,
      );
      
      return response.success;
    } catch (e) {
      debugPrint('❌ [SYNC] Erreur API signalement: $e');
      return false;
    }
  }

  /// Synchronise une information cadre de vie
  Future<bool> _syncCadreDeVie(PendingSyncItem item, List<File> imageFiles) async {
    try {
      final data = item.data;
      final response = await _informationDataSource.createInformation(
        title: item.title,
        description: data['description'],
        place: data['place'],
        reportType: data['type'],
        priority: data['priority'],
        anonymous: false, // Cadre de vie n'est jamais anonyme
        images: imageFiles,
      );
      
      return response.success;
    } catch (e) {
      debugPrint('❌ [SYNC] Erreur API cadre de vie: $e');
      return false;
    }
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}