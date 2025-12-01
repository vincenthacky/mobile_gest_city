import 'package:flutter/material.dart';
import '../data_sources/member_overview_data_source.dart';
import '../models/member_overview_model.dart';
import '../services/member_overview_local_storage_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/sync_notification.dart';

enum MemberOverviewStatus { initial, loading, success, error }

class MemberOverviewController extends ChangeNotifier {
  final MemberOverviewDataSource _dataSource = MemberOverviewDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  MemberOverviewStatus _status = MemberOverviewStatus.initial;
  MemberOverviewModel? _overview;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  
  // Pour les notifications de synchronisation
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;

  // Getters
  MemberOverviewStatus get status => _status;
  MemberOverviewModel? get overview => _overview;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == MemberOverviewStatus.loading;
  bool get hasData => _overview != null;
  DateTime? get lastFetchTime => _lastFetchTime;
  
  // Getters pour les notifications
  SyncNotificationType get notificationType => _notificationType;
  String? get notificationMessage => _notificationMessage;

  /// Getters pour les données spécifiques (avec valeurs par défaut)
  int get villaInscrit => _overview?.villaInscrit ?? 0;
  int get projetEnCours => _overview?.projetEnCours ?? 0;
  int get vigilance => _overview?.vigilance ?? 0;
  int get solde => _overview?.solde ?? 0;
  String get soldeFormatted => _overview?.soldeFormatted ?? '0 FCFA';
  int get pendingPaymentsCount => _overview?.pendingPaymentsCount ?? 0;
  WalletDetails get walletDetails => _overview?.walletDetails ?? const WalletDetails(totalReceipts: 0, totalExpenses: 0);

  /// Charge les données overview avec cache intelligent
  Future<void> loadOverview({bool forceRefresh = false, bool showNotifications = false}) async {
    debugPrint('📊 [OVERVIEW] Début chargement overview - forceRefresh: $forceRefresh');
    
    try {
      _setStatus(MemberOverviewStatus.loading);
      _clearError();
      
      // Afficher notification de synchronisation si demandé
      if (showNotifications) {
        showSyncingNotification();
      }

      // 1. Charger d'abord depuis le cache si disponible et pas de force refresh
      if (!forceRefresh) {
        await _loadFromCache();
        if (_overview != null) {
          debugPrint('📂 [OVERVIEW] Données chargées depuis le cache');
          _setStatus(MemberOverviewStatus.success);
          
          // Si les données en cache sont récentes, ne pas faire d'appel API
          if (_overview!.isRecent) {
            debugPrint('✅ [OVERVIEW] Cache récent, pas d\'appel API nécessaire');
            return;
          }
        }
      }

      // 2. Essayer de récupérer depuis l'API si connecté
      if (_connectivityService.isConnected) {
        try {
          debugPrint('🌐 [OVERVIEW] Récupération depuis l\'API...');
          final freshOverview = await _dataSource.getMemberOverview();
          
          // Sauvegarder en cache
          await MemberOverviewLocalStorageService.saveMemberOverview(freshOverview);
          
          _overview = freshOverview;
          _lastFetchTime = DateTime.now();
          _setStatus(MemberOverviewStatus.success);
          
          // Afficher notification de succès si demandé
          if (showNotifications) {
            showSyncCompleteNotification('Données actualisées avec succès');
          }
          
          debugPrint('✅ [OVERVIEW] Données récupérées depuis l\'API et mises en cache');
          return;
          
        } catch (e) {
          debugPrint('⚠️ [OVERVIEW] Erreur API: $e');
          
          // Si on a des données en cache, les utiliser malgré l'erreur API
          if (_overview != null) {
            debugPrint('📂 [OVERVIEW] Utilisation du cache suite à l\'erreur API');
            _setStatus(MemberOverviewStatus.success);
            return;
          }
          
          // Sinon, propager l'erreur
          rethrow;
        }
      } else {
        debugPrint('📱 [OVERVIEW] Mode hors ligne');
        
        // Mode hors ligne : utiliser uniquement le cache
        if (_overview != null) {
          debugPrint('📂 [OVERVIEW] Utilisation des données cache en mode hors ligne');
          _setStatus(MemberOverviewStatus.success);
          // Afficher notification hors ligne
          showOfflineNotification();
          return;
        } else {
          throw Exception('Aucune donnée disponible hors ligne');
        }
      }

    } catch (e) {
      debugPrint('❌ [OVERVIEW] Erreur lors du chargement: $e');
      _setError(e.toString());
      _setStatus(MemberOverviewStatus.error);
      
      // En cas d'erreur, effacer la notification de syncing
      if (showNotifications) {
        clearNotification();
      }
    }
  }

  /// Charge les données depuis le cache
  Future<void> _loadFromCache() async {
    try {
      final cachedOverview = await MemberOverviewLocalStorageService.getMemberOverview();
      if (cachedOverview != null) {
        _overview = cachedOverview;
        _lastFetchTime = cachedOverview.lastUpdated;
      }
    } catch (e) {
      debugPrint('⚠️ [OVERVIEW] Erreur lors du chargement du cache: $e');
    }
  }

  /// Force un rafraîchissement des données
  Future<void> refresh({bool showNotifications = true}) async {
    await loadOverview(forceRefresh: true, showNotifications: showNotifications);
  }

  /// Initialise le contrôleur (charge automatiquement les données)
  Future<void> initialize() async {
    await loadOverview();
  }

  /// Vérifie si un rafraîchissement est nécessaire
  bool get needsRefresh {
    if (_overview == null) return true;
    return !_overview!.isRecent;
  }

  /// Rafraîchit automatiquement si nécessaire
  Future<void> autoRefreshIfNeeded() async {
    if (needsRefresh) {
      debugPrint('🔄 [OVERVIEW] Auto-refresh nécessaire');
      await loadOverview();
    }
  }

  /// Obtient les statistiques de cache
  Future<Map<String, dynamic>> getCacheStats() async {
    return await MemberOverviewLocalStorageService.getStorageStats();
  }

  /// Nettoie le cache
  Future<void> clearCache() async {
    try {
      await MemberOverviewLocalStorageService.clearCache();
      _overview = null;
      _lastFetchTime = null;
      _setStatus(MemberOverviewStatus.initial);
      debugPrint('🗑️ [OVERVIEW] Cache nettoyé');
    } catch (e) {
      debugPrint('❌ [OVERVIEW] Erreur lors du nettoyage du cache: $e');
    }
  }

  // Méthodes utilitaires
  void _setStatus(MemberOverviewStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  /// Méthode pour déboguer l'état du contrôleur
  Map<String, dynamic> debugInfo() {
    return {
      'status': _status.toString(),
      'has_overview': _overview != null,
      'last_fetch_time': _lastFetchTime?.toIso8601String(),
      'is_cache_recent': _overview?.isRecent ?? false,
      'error_message': _errorMessage,
      'villa_inscrit': villaInscrit,
      'projet_en_cours': projetEnCours,
      'vigilance': vigilance,
      'solde': solde,
    };
  }

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
      message ?? 'Données synchronisées avec succès'
    );
  }
  
  /// Affiche la notification de données déjà à jour
  void showUpToDateNotification([String? message]) {
    _setNotificationType(
      SyncNotificationType.upToDate, 
      message ?? 'Données à jour • Aucune synchronisation nécessaire'
    );
  }
}