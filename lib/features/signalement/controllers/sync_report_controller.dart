import 'package:flutter/material.dart';
import '../data_sources/report_data_source.dart';
import '../models/report_model.dart';
import '../models/sync_models.dart';
import '../services/report_sync_service.dart';
import '../services/report_local_storage_service.dart';
import '../../../core/widgets/sync_notification.dart';

enum ReportLoadingStatus { initial, loading, success, error }

class SyncReportController extends ChangeNotifier {
  final ReportDataSource _reportDataSource = ReportDataSource();
  
  // Pour la récupération des signalements avec synchronisation
  ReportLoadingStatus _loadingStatus = ReportLoadingStatus.initial;
  List<ReportModel> _allReports = []; // Cache complet comme WhatsApp
  List<ReportModel> _reports = []; // Données filtrées affichées
  Map<String, dynamic>? _pagination;
  String? _loadingErrorMessage;
  
  // Filtres locaux (comme WhatsApp)
  ReportStatus? _currentStatusFilter;
  PriorityLevel? _currentPriorityFilter;
  ReportType? _currentTypeFilter;
  String? _currentSearch;

  // Pour la synchronisation
  ReportSyncStatus _syncStatus = ReportSyncStatus.idle;
  String? _syncErrorMessage;
  String? _syncMessage;
  
  // Pour les notifications de synchronisation
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;

  // Getters pour la récupération des signalements
  ReportLoadingStatus get loadingStatus => _loadingStatus;
  List<ReportModel> get reports => List.unmodifiable(_reports);
  List<ReportModel> get allReports => List.unmodifiable(_allReports);
  Map<String, dynamic>? get pagination => _pagination;
  String? get loadingErrorMessage => _loadingErrorMessage;
  bool get isLoadingReports => _loadingStatus == ReportLoadingStatus.loading;
  
  // Getters pour les filtres
  ReportStatus? get currentStatusFilter => _currentStatusFilter;
  PriorityLevel? get currentPriorityFilter => _currentPriorityFilter;
  ReportType? get currentTypeFilter => _currentTypeFilter;
  String? get currentSearch => _currentSearch;
  int get totalReportsCount => _allReports.length;
  int get filteredReportsCount => _reports.length;

  // Getters pour la synchronisation
  ReportSyncStatus get syncStatus => _syncStatus;
  String? get syncErrorMessage => _syncErrorMessage;
  String? get syncMessage => _syncMessage;
  bool get isSyncing => _syncStatus == ReportSyncStatus.syncing;
  
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
      message ?? 'Signalements synchronisés avec succès'
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
  void applyStatusFilter(ReportStatus? status) {
    _currentStatusFilter = status;
    _applyLocalFilters();
  }
  
  /// Applique un filtre de priorité localement (SANS API)
  void applyPriorityFilter(PriorityLevel? priority) {
    _currentPriorityFilter = priority;
    _applyLocalFilters();
  }
  
  /// Applique un filtre de type localement (SANS API)
  void applyTypeFilter(ReportType? type) {
    _currentTypeFilter = type;
    _applyLocalFilters();
  }
  
  /// Applique une recherche localement (SANS API)
  void applySearchFilter(String? search) {
    _currentSearch = search;
    _applyLocalFilters();
  }
  
  /// Efface tous les filtres et affiche tous les signalements du cache
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

  /// Synchronise les signalements avec le serveur
  Future<void> syncReports({
    ReportSyncFilters? filters,
    bool forceFullSync = false,
    bool showNotifications = true,
  }) async {
    _setSyncStatus(ReportSyncStatus.syncing);
    _clearSyncMessages();
    
    // Afficher notification de synchronisation si demandé
    if (showNotifications) {
      showSyncingNotification();
    }

    try {
      // 1. Déterminer le type de synchronisation
      final operation = await ReportSyncService.determineSyncOperation(
        filters: filters,
        forceFullSync: forceFullSync,
      );
      print('📋 [SYNC] Type d\'opération: ${operation.name}');

      // 2. Préparer la requête
      final request = await ReportSyncService.prepareSyncRequest(
        operation: operation,
        filters: filters,
      );
      print('📤 [SYNC] Requête préparée: ${request.toJson()}');

      // 3. Appeler l'API
      final response = await _reportDataSource.syncReports(request);
      print('📥 [SYNC] Réponse reçue: ${response.syncType}');

      // 4. Traiter la réponse
      final result = await ReportSyncService.processSyncResponse(response, _reports);
      print('🔄 [SYNC] Résultat traité: ${result.reports.length} signalements, hasChanges: ${result.hasChanges}');

      // 5. Mettre à jour les données locales dans le cache complet
      if (result.hasChanges) {
        // ✅ FUSION INTELLIGENTE : Maintenir les données existantes
        if (result.operation == ReportSyncOperation.fullSync) {
          // Full sync : remplacement complet
          _allReports = result.reports.cast<ReportModel>();
        } else {
          // Sync différentielle : fusion intelligente
          _mergeReportsIntelligently(result.reports.cast<ReportModel>(), result.changes);
        }
        _applyLocalFilters(); // Filtrage local
        _pagination = null; // Reset pagination après sync
      } else {
        // ✅ CORRECTION: Si pas de changements mais _allReports est vide, charger depuis le cache
        if (_allReports.isEmpty) {
          await _loadFromCacheIfNeeded();
        }
      }

      _setSyncMessage(result.message);
      _setSyncStatus(ReportSyncStatus.success);
      
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
      _setSyncStatus(ReportSyncStatus.error);
      
      // En cas d'erreur, effacer la notification de syncing
      if (showNotifications) {
        clearNotification();
      }
    }
  }

  /// Synchronise avec des filtres spécifiques
  Future<void> syncWithFilters(ReportSyncFilters filters) async {
    await syncReports(filters: filters);
  }

  /// Force une synchronisation complète
  Future<void> forceFullSync() async {
    await syncReports(forceFullSync: true);
  }

  /// Synchronise de manière intelligente (détection automatique)
  Future<void> smartSync() async {
    await syncReports();
  }

  /// Vérifie et synchronise si nécessaire
  Future<bool> checkAndSync({ReportSyncFilters? filters}) async {
    try {
      await syncReports(filters: filters);
      return _syncStatus == ReportSyncStatus.success;
    } catch (e) {
      return false;
    }
  }

  /// Méthode principale pour récupérer les signalements avec synchronisation intelligente
  Future<void> fetchReports({
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
    print('📲 [FETCH] fetchReports appelée - useSync: $useSync, status: $status, search: $search');
    
    if (useSync) {
      // 1. Charger d'abord les données du cache si disponibles (sauf si forceFreshData)
      if (!forceFreshData) {
        await _loadFromCacheIfNeeded();
      }
      
      // 2. Utiliser la synchronisation intelligente
      print('🔄 [FETCH] Utilisation de la synchronisation intelligente');
      final filters = ReportSyncFilters(
        status: status,
        priority: priority,
        reportType: reportType,
        search: search,
      );
      print('📋 [FETCH] Filtres: ${filters.toJson()}');
      
      try {
        await syncReports(
          filters: filters.isEmpty ? null : filters,
          showNotifications: showNotifications,
          forceFullSync: forceFreshData,
        );
      } catch (e) {
        // En cas d'erreur réseau, on garde les données du cache
        _setLoadingStatus(ReportLoadingStatus.success);
      }
    } else {
      // Utiliser l'ancienne méthode (fallback)
      print('🔙 [FETCH] Utilisation de la méthode legacy');
      await _fetchReportsLegacy(
        status: status,
        priority: priority,
        reportType: reportType,
        perPage: perPage,
        page: page,
        append: append,
      );
    }
    print('📱 [FETCH] fetchReports terminée - ${_reports.length} signalements en mémoire');
  }

  /// Charge les signalements depuis le cache si nécessaire (architecture WhatsApp)
  Future<void> _loadFromCacheIfNeeded() async {
    // Charger dans _allReports (cache complet)
    if (_allReports.isEmpty) {
      final cachedReports = await ReportLocalStorageService.getCachedReports();
      if (cachedReports.isNotEmpty) {
        _allReports = cachedReports;
        _applyLocalFilters(); // Appliquer les filtres localement
        _setLoadingStatus(ReportLoadingStatus.success);
      }
    }
  }
  
  /// Fusionne intelligemment les signalements avec les changements
  void _mergeReportsIntelligently(List<ReportModel> syncedReports, ReportSyncChanges? changes) {
    if (changes == null) {
      // Pas de changements spécifiques, utiliser la liste syncée
      _allReports = syncedReports;
      return;
    }
    
    // Fusionner intelligemment selon les types de changements
    final updatedReports = List<ReportModel>.from(_allReports);
    
    // Traiter les suppressions
    for (final deletedId in changes.deleted) {
      updatedReports.removeWhere((report) => report.id == deletedId);
    }
    
    // Traiter les ajouts et mises à jour
    for (final newReport in syncedReports) {
      final existingIndex = updatedReports.indexWhere((r) => r.id == newReport.id);
      if (existingIndex != -1) {
        // Mettre à jour le signalement existant
        updatedReports[existingIndex] = newReport;
      } else {
        // Ajouter le nouveau signalement
        updatedReports.add(newReport);
      }
    }
    
    _allReports = updatedReports;
  }
  
  /// Applique les filtres localement comme WhatsApp (SANS API)
  void _applyLocalFilters() {
    var filteredReports = List<ReportModel>.from(_allReports);
    
    // Filtrer par statut
    if (_currentStatusFilter != null) {
      filteredReports = filteredReports.where((report) {
        return report.status == _currentStatusFilter;
      }).toList();
    }
    
    // Filtrer par priorité
    if (_currentPriorityFilter != null) {
      filteredReports = filteredReports.where((report) {
        return report.priority == _currentPriorityFilter;
      }).toList();
    }
    
    // Filtrer par type
    if (_currentTypeFilter != null) {
      filteredReports = filteredReports.where((report) {
        return report.reportType == _currentTypeFilter;
      }).toList();
    }
    
    // Filtrer par recherche
    if (_currentSearch != null && _currentSearch!.length >= 2) {
      final searchLower = _currentSearch!.toLowerCase();
      filteredReports = filteredReports.where((report) {
        return report.title.toLowerCase().contains(searchLower) ||
               report.description.toLowerCase().contains(searchLower) ||
               (report.place?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    
    _reports = filteredReports;
    notifyListeners();
  }

  /// Ancienne méthode fetchReports (fallback)
  Future<void> _fetchReportsLegacy({
    String? status,
    String? priority,
    String? reportType,
    int perPage = 15,
    int page = 1,
    bool append = false,
  }) async {
    if (!append) {
      _setLoadingStatus(ReportLoadingStatus.loading);
      _clearLoadingError();
    }

    try {
      final response = await _reportDataSource.getReports(
        status: status,
        priority: priority,
        reportType: reportType,
        perPage: perPage,
        page: page,
      );

      if (response['success'] == true) {
        final reportsData = response['data'] as List<dynamic>;
        final newReports = reportsData.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
        
        if (append) {
          _allReports.addAll(newReports);
        } else {
          _allReports = newReports;
        }
        
        // Appliquer les filtres après mise à jour du cache
        _applyLocalFilters();
        
        _pagination = response['pagination'] as Map<String, dynamic>?;
        _setLoadingStatus(ReportLoadingStatus.success);
      } else {
        _setLoadingError(response['message'] ?? 'Erreur lors de la récupération des signalements');
        _setLoadingStatus(ReportLoadingStatus.error);
      }
    } catch (e) {
      _setLoadingError(e.toString());
      _setLoadingStatus(ReportLoadingStatus.error);
    }
  }

  /// Obtient les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    return await ReportSyncService.getSyncStats();
  }

  /// Valide la cohérence des données locales
  Future<ReportSyncValidation> validateLocalData() async {
    return await ReportSyncService.validateLocalData(_reports);
  }

  /// Nettoie les données de synchronisation
  Future<void> clearSyncData() async {
    await ReportSyncService.clearLocalData();
    _setSyncMessage('Données de synchronisation effacées');
  }

  // Méthodes utilitaires
  void _setLoadingStatus(ReportLoadingStatus status) {
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

  void _setSyncStatus(ReportSyncStatus status) {
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
    _syncStatus = ReportSyncStatus.idle;
    _clearSyncMessages();
    notifyListeners();
  }

  // Méthode pour rafraîchir les signalements
  Future<void> refreshReports() async {
    await fetchReports();
  }

  // Méthode pour filtrer les signalements (pour compatibilité)
  List<ReportModel> getFilteredReports({
    String? searchQuery,
  }) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      applySearchFilter(searchQuery);
    }
    return reports;
  }
}