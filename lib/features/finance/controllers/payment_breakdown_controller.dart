import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/payment_overview_model.dart';
import '../models/payment_statistics_model.dart';
import '../services/payment_statistics_local_storage_service.dart';
import '../services/payment_overview_local_storage_service.dart';
import '../services/payment_sync_listener_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/sync_notification.dart';
import 'dart:async';

enum PaymentBreakdownStatus { initial, loading, loaded, error }

class PaymentBreakdownController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  PaymentBreakdownStatus _status = PaymentBreakdownStatus.initial;
  List<PaymentOverviewUser> _paymentOverview = [];
  PaymentStatisticsData? _paymentStatistics;
  Map<int, PaymentStatisticsData> _annualStatistics = {};
  String? _errorMessage;
  
  // État pour la sélection
  String _selectedSegment = '1-6';
  int? _selectedMonth;

  // Subscription pour écouter les changements de Transaction sync
  StreamSubscription<bool>? _syncSubscription;

  // Notifications de synchronisation
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;
  bool _isOffline = false;

  // Connectivité
  bool _wasConnected = true;
  bool _connectivityListenerSetup = false;

  // Getters
  PaymentBreakdownStatus get status => _status;
  List<PaymentOverviewUser> get paymentOverview => _paymentOverview;
  PaymentStatisticsData? get paymentStatistics => _paymentStatistics;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PaymentBreakdownStatus.loading;
  bool get hasData => _paymentOverview.isNotEmpty;
  String get selectedSegment => _selectedSegment;
  int? get selectedMonth => _selectedMonth;
  int get annualStatisticsCount => _annualStatistics.length;

  // Getters pour les notifications
  SyncNotificationType get notificationType => _notificationType;
  String? get notificationMessage => _notificationMessage;
  bool get isOffline => _isOffline || !_connectivityService.isConnected;

  // Getters pour les données calculées
  List<String> get monthNames => [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  List<int> get segmentMonths {
    final startMonth = (_selectedSegment == '1-6') ? 1 : 7;
    return List.generate(6, (index) => startMonth + index);
  }

  // Listes pour la compatibilité avec SummaryCard
  List<int> get montantVentileRef {
    if (_selectedMonth != null && _paymentStatistics != null) {
      // Mode mois sélectionné
      List<int> amounts = List.filled(12, 0);
      amounts[_selectedMonth! - 1] = _paymentStatistics!.montantRecuInt;
      return amounts;
    } else {
      // Mode annuel - utiliser toutes les statistiques
      return List.generate(12, (index) {
        final month = index + 1;
        return _annualStatistics[month]?.montantRecuInt ?? 0;
      });
    }
  }

  List<int> get montantRecuParMois {
    return List.generate(12, (index) {
      final month = index + 1;
      final amount = _annualStatistics[month]?.montantRecuInt ?? 0;
      return amount;
    });
  }

  List<int> get montantReelParMois {
    return List.generate(12, (index) {
      final month = index + 1;
      return _annualStatistics[month]?.montantReelInt ?? 0;
    });
  }

  List<int> get montantRemboursementParMois {
    return List.generate(12, (index) {
      final month = index + 1;
      return _annualStatistics[month]?.montantRemboursementInt ?? 0;
    });
  }

  List<int> get montantAvanceParMois {
    return List.generate(12, (index) {
      final month = index + 1;
      return _annualStatistics[month]?.montantAvanceInt ?? 0;
    });
  }

  // Méthodes pour gérer la sélection
  void updateSelectedSegment(String segment) {
    _selectedSegment = segment;
    _selectedMonth = null; // Reset month selection
    notifyListeners();
  }

  void updateSelectedMonth(int? month) {
    _selectedMonth = month;
    notifyListeners();
    
    // Charger les statistiques pour le mois sélectionné
    if (month != null) {
      _loadPaymentStatistics(DateTime.now().year, month);
    }
  }

  /// Affiche une notification hors ligne
  void showOfflineNotification() {
    _notificationType = SyncNotificationType.offline;
    _notificationMessage = 'Pas de connexion internet • Données locales affichées';
    notifyListeners();
  }

  /// Affiche une notification de synchronisation en cours
  void showSyncingNotification() {
    _notificationType = SyncNotificationType.syncing;
    _notificationMessage = 'Synchronisation en cours...';
    notifyListeners();
  }

  /// Affiche une notification de synchronisation terminée
  void showSyncCompleteNotification() {
    _notificationType = SyncNotificationType.syncComplete;
    _notificationMessage = 'Ventilation synchronisée';
    notifyListeners();
  }

  /// Efface la notification
  void clearNotification() {
    _notificationType = SyncNotificationType.none;
    _notificationMessage = null;
    notifyListeners();
  }

  /// Configure le listener de connectivité pour la synchronisation automatique
  void setupConnectivityListener() {
    if (_connectivityListenerSetup) return;

    _wasConnected = _connectivityService.isConnected;
    debugPrint('🔌 [PAYMENT BREAKDOWN] Setup connectivity listener - état initial: ${_wasConnected ? "connecté" : "hors ligne"}');

    _connectivityService.addListener(_onConnectivityChanged);
    _connectivityListenerSetup = true;
  }

  /// Gère les changements de connectivité
  Future<void> _onConnectivityChanged() async {
    final isConnected = _connectivityService.isConnected;
    debugPrint('🔌 [PAYMENT BREAKDOWN] Changement connectivité: ${isConnected ? "connecté" : "hors ligne"} (était: ${_wasConnected ? "connecté" : "hors ligne"})');

    if (isConnected && !_wasConnected) {
      // Connexion restaurée → Synchroniser automatiquement
      debugPrint('✅ [PAYMENT BREAKDOWN] Connexion restaurée - synchronisation automatique...');
      _isOffline = false;

      // Notification syncing
      showSyncingNotification();

      try {
        await _syncPaymentData();

        // Notification succès
        showSyncCompleteNotification();

        // Masquer après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          clearNotification();
        });
      } catch (e) {
        debugPrint('❌ [PAYMENT BREAKDOWN] Erreur sync après reconnexion: $e');
        clearNotification();
      }
    } else if (!isConnected && _wasConnected) {
      // Connexion perdue → Afficher notification hors ligne
      debugPrint('📱 [PAYMENT BREAKDOWN] Connexion perdue - mode hors ligne');
      _isOffline = true;
      showOfflineNotification();
    }

    _wasConnected = isConnected;
    notifyListeners();
  }

  /// Dispose le listener de connectivité
  void disposeConnectivityListener() {
    if (!_connectivityListenerSetup) return;

    debugPrint('🔌 [PAYMENT BREAKDOWN] Dispose connectivity listener');
    _connectivityService.removeListener(_onConnectivityChanged);
    _connectivityListenerSetup = false;
  }

  // Initialise le controller et configure l'écoute de sync
  void initialize() {
    debugPrint('🎯 [PAYMENT BREAKDOWN] Initialisation du controller - configuration écoute maître');
    _setupSyncListener();
    PaymentStatisticsLocalStorageService.initialize();
    PaymentOverviewLocalStorageService.initialize();
  }

  // Configure l'écoute des changements de Transaction sync
  void _setupSyncListener() {
    _syncSubscription = PaymentSyncListenerService.instance.paymentSyncTriggerStream.listen(
      (shouldSync) {
        if (shouldSync) {
          debugPrint('🔄 [PAYMENT BREAKDOWN] Synchronisation déclenchée par Transaction sync');
          _syncPaymentData();
        }
      },
    );
  }

  /// Charge les données de ventilation.
  /// 1. Charge le cache immédiatement pour affichage instantané.
  /// 2. Si connecté → appel API direct, mise à jour du cache, rafraîchissement UI.
  /// 3. Si hors ligne → cache uniquement + notification.
  Future<void> loadPaymentBreakdownData() async {
    _setStatus(PaymentBreakdownStatus.loading);
    _clearError();
    _isOffline = !_connectivityService.isConnected;

    try {
      // Étape 1 : cache pour affichage immédiat
      await _loadFromCache();

      if (_isOffline) {
        // Hors ligne : garder le cache, notifier l'utilisateur
        showOfflineNotification();
      } else {
        // Connecté : aller chercher les données fraîches depuis l'API
        await _syncPaymentData();
      }
    } catch (e) {
      debugPrint('❌ [PAYMENT BREAKDOWN] Erreur loadPaymentBreakdownData: $e');
      if (_paymentOverview.isNotEmpty) {
        // Données en cache disponibles → afficher sans erreur
        _setStatus(PaymentBreakdownStatus.loaded);
      } else {
        _setError(e.toString());
        _setStatus(PaymentBreakdownStatus.error);
      }
    }
  }


  // Chargement depuis le cache SEULEMENT
  Future<void> _loadFromCache() async {
    final cachedOverview = PaymentOverviewLocalStorageService.getPaymentOverview();
    final currentYear = DateTime.now().year;
    final cachedStats = PaymentStatisticsLocalStorageService.getYearStatistics(currentYear);
    
    if (cachedOverview != null || cachedStats.isNotEmpty) {
      _paymentOverview = cachedOverview ?? [];
      _annualStatistics = cachedStats;
      _setStatus(PaymentBreakdownStatus.loaded);
      debugPrint('✅ [PAYMENT BREAKDOWN] Données chargées depuis le cache');
      
      // Charger les statistiques pour le mois actuel si disponibles
      final now = DateTime.now();
      if (cachedStats.containsKey(now.month)) {
        _paymentStatistics = cachedStats[now.month];
      }
    } else {
      // Données par défaut si pas de cache
      _paymentOverview = [];
      _annualStatistics = {};
      _setStatus(PaymentBreakdownStatus.loaded);
      debugPrint('📱 [PAYMENT BREAKDOWN] Pas de cache, données vides affichées');
    }
  }

  /// Synchronise les données depuis l'API et met à jour le cache local.
  Future<void> _syncPaymentData() async {
    if (!_connectivityService.isConnected) {
      debugPrint('📱 [PAYMENT BREAKDOWN] Pas de connexion, sync annulée');
      _setStatus(PaymentBreakdownStatus.loaded);
      return;
    }

    try {
      debugPrint('🔄 [PAYMENT BREAKDOWN] Début synchronisation...');

      // Récupérer l'aperçu des paiements depuis l'API
      final overviewResponse = await _dataSource.getPaymentOverview();
      if (overviewResponse.success) {
        _paymentOverview = overviewResponse.data;
        await PaymentOverviewLocalStorageService.savePaymentOverview(_paymentOverview);
        debugPrint('✅ [PAYMENT BREAKDOWN] Aperçu synchronisé (${_paymentOverview.length} membres)');
      }

      // Récupérer les statistiques annuelles depuis l'API
      final currentYear = DateTime.now().year;
      await _loadAndCacheAnnualStatistics(currentYear);

      _setStatus(PaymentBreakdownStatus.loaded);
      debugPrint('✅ [PAYMENT BREAKDOWN] Synchronisation terminée');
    } catch (e) {
      debugPrint('❌ [PAYMENT BREAKDOWN] Erreur synchronisation: $e');
      // En cas d'erreur, afficher quand même ce qu'on a en mémoire
      _setStatus(PaymentBreakdownStatus.loaded);
    }
  }

  Future<void> _loadPaymentStatistics(int year, int month) async {
    try {
      final statsResponse = await _dataSource.getPaymentStatistics(
        year: year,
        month: month,
      );
      
      if (statsResponse.success) {
        _paymentStatistics = statsResponse.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
      // Ne pas faire échouer toute l'opération si les stats échouent
    }
  }

  /// Actualise les données (pull-to-refresh).
  /// Si connecté → appel API + mise à jour du cache.
  /// Si hors ligne → conserve le cache existant.
  Future<void> refreshData() async {
    _clearError();
    _isOffline = !_connectivityService.isConnected;

    if (_isOffline) {
      debugPrint('📱 [PAYMENT BREAKDOWN] Refresh hors ligne — cache conservé');
      notifyListeners();
      return;
    }

    _setStatus(PaymentBreakdownStatus.loading);
    await _syncPaymentData();
  }


  void _setStatus(PaymentBreakdownStatus status) {
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

  void clearData() {
    _paymentOverview = [];
    _paymentStatistics = null;
    _annualStatistics = {};
    _errorMessage = null;
    _status = PaymentBreakdownStatus.initial;
    _selectedSegment = '1-6';
    _selectedMonth = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    disposeConnectivityListener();
    super.dispose();
  }
  
  Future<void> _loadAnnualStatistics(int year) async {
    // Vérifier d'abord le cache local
    final cachedStats = PaymentStatisticsLocalStorageService.getYearStatistics(year);
    
    if (cachedStats.isNotEmpty && cachedStats.length == 12) {
      _annualStatistics = cachedStats;
      debugPrint('✅ [PAYMENT BREAKDOWN] Statistiques $year chargées depuis cache (${cachedStats.length}/12)');
      notifyListeners();
      return;
    }
    
    // Si cache incomplet, charger depuis API
    await _loadAndCacheAnnualStatistics(year);
  }

  Future<void> _loadAndCacheAnnualStatistics(int year) async {
    try {
      debugPrint('🔄 [PAYMENT BREAKDOWN] Chargement des statistiques $year depuis API');
      final newStats = <int, PaymentStatisticsData>{};
      
      // Charger les statistiques pour tous les mois de l'année
      for (int month = 1; month <= 12; month++) {
        final statsResponse = await _dataSource.getPaymentStatistics(
          year: year,
          month: month,
        );
        
        if (statsResponse.success) {
          newStats[month] = statsResponse.data;
          // Sauvegarder chaque mois individuellement en cache
          await PaymentStatisticsLocalStorageService.saveMonthStatistics(
            year, month, statsResponse.data
          );
        }
      }
      
      _annualStatistics = newStats;
      debugPrint('✅ [PAYMENT BREAKDOWN] Statistiques $year: ${newStats.length}/12 mois chargés et mis en cache');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [PAYMENT BREAKDOWN] Erreur chargement statistiques $year: $e');
    }
  }
  
  // Méthode publique pour s'assurer que toutes les statistiques annuelles sont chargées
  Future<void> ensureAnnualStatisticsLoaded() async {
    final currentYear = DateTime.now().year;
    
    // Si moins de 12 mois chargés, recharger toutes les statistiques
    if (_annualStatistics.length < 12) {
      debugPrint('DEBUG: Rechargement des statistiques annuelles (${_annualStatistics.length}/12 actuellement)');
      await _loadAnnualStatistics(currentYear);
      
      // Attendre maximum 30 secondes
      int attempts = 0;
      while (_annualStatistics.length < 12 && attempts < 300) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      debugPrint('DEBUG: Statistiques finales chargées: ${_annualStatistics.length}/12');
    }
  }

  // Méthode utilitaire pour obtenir les membres au format compatible
  List<Map<String, dynamic>> get membersForTable {
    return _paymentOverview.map((user) {
      final payments = List.generate(12, (index) {
        final monthNumber = index + 1;
        final status = user.getDisplayStatusForMonth(monthNumber);
        return status;
      });

      return {
        'name': user.fullName,
        'villaNumber': user.villaNumber,
        'payments': payments,
      };
    }).toList();
  }
}