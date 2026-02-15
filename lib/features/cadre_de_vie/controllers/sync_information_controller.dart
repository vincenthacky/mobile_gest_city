import 'package:flutter/material.dart';
import '../data_sources/information_data_source.dart';
import '../models/information_model.dart';
import '../models/sync_models.dart';
import '../services/information_sync_service.dart';
import '../services/information_local_storage_service.dart';
import '../../../core/widgets/sync_notification.dart';

enum InformationLoadingStatus { initial, loading, success, error }

class SyncInformationController extends ChangeNotifier {
  final InformationDataSource _informationDataSource = InformationDataSource();
  
  // Pour la récupération des informations avec synchronisation
  InformationLoadingStatus _loadingStatus = InformationLoadingStatus.initial;
  List<InformationModel> _allInformations = []; // Cache complet comme WhatsApp
  List<InformationModel> _informations = []; // Données filtrées affichées
  Map<String, dynamic>? _pagination;
  String? _loadingErrorMessage;
  
  // Filtres locaux (comme WhatsApp)
  InformationStatus? _currentStatusFilter;
  PriorityLevel? _currentPriorityFilter;
  InformationType? _currentTypeFilter;
  String? _currentSearch;

  // Tracking des changements pour animations
  List<String> _recentlyAddedIds = [];
  List<String> _recentlyUpdatedIds = [];
  List<String> _recentlyDeletedIds = [];

  // Pour la synchronisation
  InformationSyncStatus _syncStatus = InformationSyncStatus.idle;
  String? _syncErrorMessage;
  String? _syncMessage;
  
  // Pour les notifications de synchronisation
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;

  // Getters pour la récupération des informations
  InformationLoadingStatus get loadingStatus => _loadingStatus;
  List<InformationModel> get informations => List.unmodifiable(_informations);
  List<InformationModel> get allInformations => List.unmodifiable(_allInformations);
  Map<String, dynamic>? get pagination => _pagination;
  String? get loadingErrorMessage => _loadingErrorMessage;
  bool get isLoadingInformations => _loadingStatus == InformationLoadingStatus.loading;
  
  // Getters pour les filtres
  InformationStatus? get currentStatusFilter => _currentStatusFilter;
  PriorityLevel? get currentPriorityFilter => _currentPriorityFilter;
  InformationType? get currentTypeFilter => _currentTypeFilter;
  String? get currentSearch => _currentSearch;
  int get totalInformationsCount => _allInformations.length;
  int get filteredInformationsCount => _informations.length;

  // Getters pour le tracking des changements
  List<String> get recentlyAddedIds => List.unmodifiable(_recentlyAddedIds);
  List<String> get recentlyUpdatedIds => List.unmodifiable(_recentlyUpdatedIds);
  List<String> get recentlyDeletedIds => List.unmodifiable(_recentlyDeletedIds);

  void clearRecentChanges() {
    _recentlyAddedIds = [];
    _recentlyUpdatedIds = [];
    _recentlyDeletedIds = [];
  }

  // Getters pour la synchronisation
  InformationSyncStatus get syncStatus => _syncStatus;
  String? get syncErrorMessage => _syncErrorMessage;
  String? get syncMessage => _syncMessage;
  bool get isSyncing => _syncStatus == InformationSyncStatus.syncing;
  
  // Getters pour les notifications
  SyncNotificationType get notificationType => _notificationType;
  String? get notificationMessage => _notificationMessage;

  // ============ MÉTHODES DE NOTIFICATION ============
  
  /// Met à jour le type de notification
  void _setNotificationType(SyncNotificationType type, [String? message]) {
    _notificationType = type;
    _notificationMessage = message;
    notifyListeners();
  }
  
  /// Efface la notification
  void clearNotification() {
    _setNotificationType(SyncNotificationType.none);
  }
  
  /// Affiche la notification de données hors ligne
  void showOfflineNotification() {
    _setNotificationType(SyncNotificationType.offline);
  }
  
  /// Affiche la notification de synchronisation en cours
  void showSyncingNotification([String? message]) {
    _setNotificationType(SyncNotificationType.syncing, message);
  }
  
  /// Affiche la notification de synchronisation terminée
  void showSyncCompleteNotification([String? message]) {
    _setNotificationType(
      SyncNotificationType.syncComplete, 
      message ?? 'Informations synchronisées avec succès'
    );
  }
  
  /// Affiche la notification de données déjà à jour
  void showUpToDateNotification([String? message]) {
    _setNotificationType(
      SyncNotificationType.upToDate, 
      message ?? 'Données à jour • Aucune synchronisation nécessaire'
    );
  }

  // ============ MÉTHODES DE FILTRAGE LOCAL (WhatsApp Style) ============
  
  /// Applique un filtre de statut localement (SANS API)
  void applyStatusFilter(InformationStatus? status) {
    _currentStatusFilter = status;
    _applyLocalFilters();
  }
  
  /// Applique un filtre de priorité localement (SANS API)
  void applyPriorityFilter(PriorityLevel? priority) {
    _currentPriorityFilter = priority;
    _applyLocalFilters();
  }
  
  /// Applique un filtre de type localement (SANS API)
  void applyTypeFilter(InformationType? type) {
    _currentTypeFilter = type;
    _applyLocalFilters();
  }
  
  /// Applique une recherche localement (SANS API)
  void applySearchFilter(String? search) {
    _currentSearch = search;
    _applyLocalFilters();
  }
  
  /// Efface tous les filtres et affiche toutes les informations du cache
  void clearAllFilters() {
    _currentStatusFilter = null;
    _currentPriorityFilter = null;
    _currentTypeFilter = null;
    _currentSearch = null;
    _applyLocalFilters();
  }
  
  /// Méthode publique pour rafraîchir les filtres
  void refreshFilters() {
    _applyLocalFilters();
  }

  // ============ MÉTHODES DE SYNCHRONISATION ============

  /// Synchronise les informations avec le serveur
  Future<void> syncInformations({
    InformationSyncFilters? filters,
    bool forceFullSync = false,
    bool showNotifications = true,
  }) async {
    _setSyncStatus(InformationSyncStatus.syncing);
    _clearSyncMessages();
    
    // Afficher notification de synchronisation si demandé
    if (showNotifications) {
      showSyncingNotification();
    }

    try {
      // 1. Déterminer le type de synchronisation
      final operation = await InformationSyncService.determineSyncOperation(
        filters: filters,
        forceFullSync: forceFullSync,
      );
      print('📋 [SYNC] Type d\'opération: ${operation.name}');

      // 2. Préparer la requête
      final request = await InformationSyncService.prepareSyncRequest(
        operation: operation,
        filters: filters,
      );
      print('📤 [SYNC] Requête préparée: ${request.toJson()}');

      // 3. Appeler l'API
      final response = await _informationDataSource.syncInformation(request);
      print('📥 [SYNC] Réponse reçue: ${response.syncType}');

      // 4. Traiter la réponse
      final result = await InformationSyncService.processSyncResponse(response, _informations);
      print('🔄 [SYNC] Résultat traité: ${result.informations.length} informations, hasChanges: ${result.hasChanges}');

      // 5. Mettre à jour les données locales dans le cache complet
      if (result.hasChanges) {
        // ✅ FUSION INTELLIGENTE : Maintenir les données existantes
        if (result.operation == InformationSyncOperation.fullSync) {
          // Full sync : remplacement complet
          _allInformations = result.informations.cast<InformationModel>();
        } else {
          // Sync différentielle : fusion intelligente
          _mergeInformationsIntelligently(result.informations.cast<InformationModel>(), result.changes);
        }
        _applyLocalFilters(); // Filtrage local
        _pagination = null; // Reset pagination après sync
      }

      _setSyncMessage(result.message);
      _setSyncStatus(InformationSyncStatus.success);
      
      // Afficher notification appropriée selon le résultat
      if (showNotifications) {
        if (result.hasChanges) {
          showSyncCompleteNotification(result.message);
        } else {
          // Données déjà à jour - pas de sync nécessaire
          showUpToDateNotification();
        }
      }
      
    } catch (e) {
      _setSyncError(e.toString());
      _setSyncStatus(InformationSyncStatus.error);
      
      // En cas d'erreur, effacer la notification de syncing
      if (showNotifications) {
        clearNotification();
      }
    }
  }

  /// Synchronise avec des filtres spécifiques
  Future<void> syncWithFilters(InformationSyncFilters filters) async {
    await syncInformations(filters: filters);
  }

  /// Force une synchronisation complète
  Future<void> forceFullSync() async {
    await syncInformations(forceFullSync: true);
  }

  /// Synchronise de manière intelligente (détection automatique)
  Future<void> smartSync() async {
    await syncInformations();
  }

  /// Vérifie et synchronise si nécessaire
  Future<bool> checkAndSync({InformationSyncFilters? filters}) async {
    try {
      await syncInformations(filters: filters);
      return _syncStatus == InformationSyncStatus.success;
    } catch (e) {
      return false;
    }
  }

  /// Méthode principale pour récupérer les informations avec synchronisation intelligente
  Future<void> fetchInformations({
    String? status,
    String? priority,
    String? reportType,
    String? search,
    int perPage = 15,
    int page = 1,
    bool append = false,
    bool useSync = true,
    bool showNotifications = false,
    bool forceFreshData = false,
  }) async {
    print('📲 [FETCH] fetchInformations appelée - useSync: $useSync, status: $status, search: $search');
    
    if (useSync) {
      // 1. Charger d'abord les données du cache si disponibles (sauf si forceFreshData)
      if (!forceFreshData) {
        await _loadFromCacheIfNeeded();
      }
      
      // 2. Utiliser la synchronisation intelligente
      print('🔄 [FETCH] Utilisation de la synchronisation intelligente');
      final filters = InformationSyncFilters(
        status: status,
        priority: priority,
        reportType: reportType,
        search: search,
      );
      print('📋 [FETCH] Filtres: ${filters.toJson()}');
      
      try {
        await syncInformations(
          filters: filters.isEmpty ? null : filters,
          showNotifications: showNotifications,
          forceFullSync: forceFreshData,
        );
      } catch (e) {
        // En cas d'erreur réseau, on garde les données du cache
        _setLoadingStatus(InformationLoadingStatus.success);
      }
    } else {
      // Utiliser l'ancienne méthode (fallback)
      print('🔙 [FETCH] Utilisation de la méthode legacy');
      await _fetchInformationsLegacy(
        status: status,
        priority: priority,
        reportType: reportType,
        perPage: perPage,
        page: page,
        append: append,
      );
    }
    print('📱 [FETCH] fetchInformations terminée - ${_informations.length} informations en mémoire');
  }

  /// Charge les informations depuis le cache si nécessaire (architecture WhatsApp)
  Future<void> _loadFromCacheIfNeeded() async {
    // Charger dans _allInformations (cache complet)
    if (_allInformations.isEmpty) {
      final cachedInformations = await InformationLocalStorageService.getCachedInformations();
      if (cachedInformations.isNotEmpty) {
        _allInformations = cachedInformations;
        _applyLocalFilters(); // Appliquer les filtres localement
        _setLoadingStatus(InformationLoadingStatus.success);
      }
    }
  }
  
  /// Fusionne intelligemment les informations avec les changements
  void _mergeInformationsIntelligently(List<InformationModel> syncedInformations, InformationSyncChanges? changes) {
    // Reset tracking
    _recentlyAddedIds = [];
    _recentlyUpdatedIds = [];
    _recentlyDeletedIds = [];

    if (changes == null) {
      _allInformations = syncedInformations;
      return;
    }

    final updatedInformations = List<InformationModel>.from(_allInformations);

    // Traiter les suppressions
    for (final deletedId in changes.deleted) {
      updatedInformations.removeWhere((information) => information.id == deletedId);
      _recentlyDeletedIds.add(deletedId);
    }

    // Traiter les ajouts et mises à jour
    for (final newInformation in syncedInformations) {
      final existingIndex = updatedInformations.indexWhere((i) => i.id == newInformation.id);
      if (existingIndex != -1) {
        if (updatedInformations[existingIndex] != newInformation) {
          updatedInformations[existingIndex] = newInformation;
          _recentlyUpdatedIds.add(newInformation.id);
        }
      } else {
        updatedInformations.add(newInformation);
        _recentlyAddedIds.add(newInformation.id);
      }
    }

    _allInformations = updatedInformations;
  }
  
  /// Applique les filtres localement comme WhatsApp (SANS API)
  void _applyLocalFilters() {
    var filteredInformations = List<InformationModel>.from(_allInformations);

    // Filtrer par statut
    if (_currentStatusFilter != null) {
      filteredInformations = filteredInformations.where((information) {
        return information.status == _currentStatusFilter;
      }).toList();
    }

    // Filtrer par priorité
    if (_currentPriorityFilter != null) {
      filteredInformations = filteredInformations.where((information) {
        return information.priority == _currentPriorityFilter;
      }).toList();
    }

    // Filtrer par type
    if (_currentTypeFilter != null) {
      filteredInformations = filteredInformations.where((information) {
        return information.reportType == _currentTypeFilter;
      }).toList();
    }

    // Filtrer par recherche
    if (_currentSearch != null && _currentSearch!.length >= 2) {
      final searchLower = _currentSearch!.toLowerCase();
      filteredInformations = filteredInformations.where((information) {
        return information.title.toLowerCase().contains(searchLower) ||
               information.description.toLowerCase().contains(searchLower) ||
               (information.place?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // Ne notifier que si la liste filtrée a réellement changé
    if (_informations.length != filteredInformations.length ||
        !_listsEqual(_informations, filteredInformations)) {
      _informations = filteredInformations;
      notifyListeners();
    }
  }

  /// Compare deux listes d'informations en utilisant operator ==
  bool _listsEqual(List<InformationModel> a, List<InformationModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Ancienne méthode fetchInformations (fallback)
  Future<void> _fetchInformationsLegacy({
    String? status,
    String? priority,
    String? reportType,
    int perPage = 15,
    int page = 1,
    bool append = false,
  }) async {
    if (!append) {
      _setLoadingStatus(InformationLoadingStatus.loading);
      _clearLoadingError();
    }

    try {
      final response = await _informationDataSource.getInformation(
        status: status,
        priority: priority,
        reportType: reportType,
        perPage: perPage,
        page: page,
      );

      if (response['success'] == true) {
        final informationsData = response['data'] as List<dynamic>;
        final newInformations = informationsData.map((json) => InformationModel.fromJson(json as Map<String, dynamic>)).toList();
        
        if (append) {
          _allInformations.addAll(newInformations);
        } else {
          _allInformations = newInformations;
        }
        
        // Appliquer les filtres après mise à jour du cache
        _applyLocalFilters();
        
        _pagination = response['pagination'] as Map<String, dynamic>?;
        _setLoadingStatus(InformationLoadingStatus.success);
      } else {
        _setLoadingError(response['message'] ?? 'Erreur lors de la récupération des informations');
        _setLoadingStatus(InformationLoadingStatus.error);
      }
    } catch (e) {
      _setLoadingError(e.toString());
      _setLoadingStatus(InformationLoadingStatus.error);
    }
  }

  /// Obtient les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    return await InformationSyncService.getSyncStats();
  }

  /// Valide la cohérence des données locales
  Future<InformationSyncValidation> validateLocalData() async {
    return await InformationSyncService.validateLocalData(_informations);
  }

  /// Nettoie les données de synchronisation
  Future<void> clearSyncData() async {
    await InformationSyncService.clearLocalData();
    _setSyncMessage('Données de synchronisation effacées');
  }

  // Méthodes utilitaires
  void _setLoadingStatus(InformationLoadingStatus status) {
    _loadingStatus = status;
    notifyListeners();
  }

  void _setLoadingError(String error) {
    _loadingErrorMessage = error;
    notifyListeners();
  }

  void _clearLoadingError() {
    _loadingErrorMessage = null;
    notifyListeners();
  }

  void _setSyncStatus(InformationSyncStatus status) {
    print('🔄 [SYNC] Changement de statut: ${_syncStatus.name} → ${status.name}');
    _syncStatus = status;
    notifyListeners();
  }

  void _setSyncError(String error) {
    print('❌ [SYNC] Erreur: $error');
    _syncErrorMessage = error;
    notifyListeners();
  }

  void _setSyncMessage(String message) {
    print('💬 [SYNC] Message: $message');
    _syncMessage = message;
    notifyListeners();
  }

  void _clearSyncMessages() {
    _syncErrorMessage = null;
    _syncMessage = null;
    notifyListeners();
  }

  void clearSyncError() {
    _syncErrorMessage = null;
    notifyListeners();
  }

  void resetSyncStatus() {
    _syncStatus = InformationSyncStatus.idle;
    _clearSyncMessages();
    notifyListeners();
  }

  // Méthode pour rafraîchir les informations
  Future<void> refreshInformations() async {
    await fetchInformations();
  }

  // Méthode pour filtrer les informations (pour compatibilité)
  List<InformationModel> getFilteredInformations({
    String? searchQuery,
  }) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      applySearchFilter(searchQuery);
    }
    return informations;
  }
  
  /// Méthode de validation pour déboguer les problèmes de synchronisation
  Future<Map<String, dynamic>> debugSyncState() async {
    final cacheCount = await InformationLocalStorageService.getCachedInformationsCount();
    final checksumCount = await InformationLocalStorageService.getChecksumsCount();
    final storageStats = await InformationLocalStorageService.getStorageStats();
    
    return {
      'memory_informations': _allInformations.length,
      'displayed_informations': _informations.length,
      'cache_count': cacheCount,
      'checksum_count': checksumCount,
      'storage_stats': storageStats,
      'current_status_filter': _currentStatusFilter?.toString(),
      'current_priority_filter': _currentPriorityFilter?.toString(),
      'current_type_filter': _currentTypeFilter?.toString(),
      'current_search': _currentSearch,
      'sync_status': _syncStatus.toString(),
      'has_cache': await InformationLocalStorageService.hasCachedInformations(),
    };
  }
  
  /// Force une synchronisation complète pour corriger les incohérences
  Future<void> forceSyncRepair() async {
    debugPrint('🔄 [REPAIR] Début de la réparation de synchronisation des informations');
    
    try {
      // 1. Nettoyer les données incohérentes
      await InformationLocalStorageService.clearCachedInformations();
      await InformationLocalStorageService.clearAllChecksums();
      
      // 2. Forcer une synchronisation complète
      await syncInformations(forceFullSync: true, showNotifications: true);
      
      debugPrint('✅ [REPAIR] Réparation de synchronisation des informations terminée');
    } catch (e) {
      debugPrint('❌ [REPAIR] Erreur lors de la réparation des informations: $e');
      rethrow;
    }
  }
}