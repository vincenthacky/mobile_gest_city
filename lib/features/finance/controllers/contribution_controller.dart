import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';
import '../models/unpaid_months_model.dart';
import '../models/payment_proofs_model.dart';
import '../models/payment_list_model.dart';
import '../models/payment_periods_model.dart';
import '../services/contribution_local_storage_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/widgets/sync_notification.dart';
import '../../authentification/model/user_model.dart';

enum ContributionStatus { initial, loading, loaded, error }

class ContributionController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();

  ContributionStatus _status = ContributionStatus.initial;
  ContributionData? _contributionData;
  List<UnpaidMonth> _unpaidMonths = [];
  List<PaymentItem> _validatedPayments = [];
  List<PaymentItem> _pendingPayments = [];
  PaginationInfo? _validatedPagination;
  PaginationInfo? _pendingPagination;

  // Nouvelle liste unifiée des paiements
  List<PaymentItem> _allPayments = [];
  PaymentPagination? _allPaymentsPagination;
  String? _errorMessage;
  bool _isOffline = false;

  // Notifications de synchronisation
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;

  // Connectivité
  bool _wasConnected = true;
  bool _connectivityListenerSetup = false;

  ContributionStatus get status => _status;
  ContributionData? get contributionData => _contributionData;
  List<UnpaidMonth> get unpaidMonths => _unpaidMonths;
  List<PaymentItem> get validatedPayments => _validatedPayments;
  List<PaymentItem> get pendingPayments => _pendingPayments;
  PaginationInfo? get validatedPagination => _validatedPagination;
  PaginationInfo? get pendingPagination => _pendingPagination;

  // Nouveaux getters pour la liste unifiée
  List<PaymentItem> get allPayments => _allPayments;
  PaymentPagination? get allPaymentsPagination => _allPaymentsPagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ContributionStatus.loading;
  bool get hasData => _contributionData != null;

  /// Indique si on est hors connexion
  bool get isOffline => _isOffline || !_connectivityService.isConnected;

  /// Getters pour les notifications
  SyncNotificationType get notificationType => _notificationType;
  String? get notificationMessage => _notificationMessage;

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
    _notificationMessage = 'Cotisations synchronisées';
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
    debugPrint('🔌 [CONTRIBUTION] Setup connectivity listener - état initial: ${_wasConnected ? "connecté" : "hors ligne"}');

    _connectivityService.addListener(_onConnectivityChanged);
    _connectivityListenerSetup = true;
  }

  /// Gère les changements de connectivité
  Future<void> _onConnectivityChanged() async {
    final isConnected = _connectivityService.isConnected;
    debugPrint('🔌 [CONTRIBUTION] Changement connectivité: ${isConnected ? "connecté" : "hors ligne"} (était: ${_wasConnected ? "connecté" : "hors ligne"})');

    if (isConnected && !_wasConnected) {
      // Connexion restaurée → Synchroniser automatiquement
      debugPrint('✅ [CONTRIBUTION] Connexion restaurée - synchronisation automatique...');
      _isOffline = false;

      // Notification syncing
      showSyncingNotification();

      try {
        // Récupérer userId et synchroniser
        final userId = await _getCurrentUserId();
        await _syncWithChecksum(userId: userId);

        // Notification succès
        showSyncCompleteNotification();

        // Masquer après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          clearNotification();
        });
      } catch (e) {
        debugPrint('❌ [CONTRIBUTION] Erreur sync après reconnexion: $e');
        clearNotification();
      }
    } else if (!isConnected && _wasConnected) {
      // Connexion perdue → Afficher notification hors ligne
      debugPrint('📱 [CONTRIBUTION] Connexion perdue - mode hors ligne');
      _isOffline = true;
      showOfflineNotification();
    }

    _wasConnected = isConnected;
    notifyListeners();
  }

  /// Dispose le listener de connectivité
  void disposeConnectivityListener() {
    if (!_connectivityListenerSetup) return;

    debugPrint('🔌 [CONTRIBUTION] Dispose connectivity listener');
    _connectivityService.removeListener(_onConnectivityChanged);
    _connectivityListenerSetup = false;
  }

  // Initialise le controller (indépendant - pas de listener)
  void initialize() {
    try {
      debugPrint('🎯 [CONTRIBUTION] Initialisation du controller INDÉPENDANT');
      debugPrint('🔧 [CONTRIBUTION] Initialisation du service local storage...');
      ContributionLocalStorageService.initialize();
      debugPrint('✅ [CONTRIBUTION] Service local storage initialisé');
      debugPrint('✅ [CONTRIBUTION] Initialisation complète terminée');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// 🎯 SYNCHRONISATION INTELLIGENTE BASÉE SUR LE CHECKSUM
  /// Appelée directement quand on arrive sur la page des cotisations
  Future<void> _syncWithChecksum({String? userId}) async {
    if (!_connectivityService.isConnected) {
      debugPrint('📱 [CONTRIBUTION] Pas de connexion, chargement depuis cache uniquement');
      return;
    }

    try {
      debugPrint('🔄 [CONTRIBUTION] Début synchronisation avec checksum...');

      // ÉTAPE 1: Appeler l'API /contributions pour obtenir le checksum
      final contributionResponse = await _dataSource.getContribution();

      if (!contributionResponse.success) {
        debugPrint('❌ [CONTRIBUTION] Échec récupération contribution');
        return;
      }

      final remoteChecksum = contributionResponse.checksum;
      debugPrint('📡 [CONTRIBUTION] Checksum distant: ${remoteChecksum?.substring(0, 16) ?? 'null'}...');

      // ÉTAPE 2: Comparer avec le checksum local
      final checksumChanged = ContributionLocalStorageService.hasChecksumChanged(remoteChecksum);
      debugPrint('🔍 [CONTRIBUTION] Checksum changé: $checksumChanged');

      if (checksumChanged) {
        // ÉTAPE 3A: Checksum différent → Charger TOUTES les données
        debugPrint('🔄 [CONTRIBUTION] Checksum différent, rechargement complet...');
        await _loadAllDataFromApi(contributionResponse.data, userId);
      } else {
        // ÉTAPE 3B: Checksum identique → Utiliser le cache
        debugPrint('✅ [CONTRIBUTION] Checksum identique, utilisation du cache');
        _contributionData = contributionResponse.data;
      }

      notifyListeners();
      debugPrint('✅ [CONTRIBUTION] Synchronisation avec checksum terminée');

    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur synchronisation avec checksum: $e');
    }
  }

  /// Charge toutes les données depuis l'API et les sauvegarde en cache
  Future<void> _loadAllDataFromApi(ContributionData contributionData, String? userId) async {
    try {
      // Sauvegarder les données de contribution
      _contributionData = contributionData;
      await ContributionLocalStorageService.saveContributionData(_contributionData!);
      debugPrint('✅ [CONTRIBUTION] Données contribution sauvegardées');

      // Charger et sauvegarder les mois impayés
      final unpaidMonthsResponse = await _dataSource.getUnpaidMonths();
      if (unpaidMonthsResponse.success) {
        _unpaidMonths = unpaidMonthsResponse.data;
        await ContributionLocalStorageService.saveUnpaidMonths(_unpaidMonths);
        debugPrint('✅ [CONTRIBUTION] ${_unpaidMonths.length} mois impayés sauvegardés');
      }

      // Charger et sauvegarder les paiements si userId fourni
      if (userId != null) {
        await _syncPaymentsData(userId);
      }

    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur chargement données API: $e');
    }
  }

  /// Synchronise les données de paiements
  Future<void> _syncPaymentsData(String userId) async {
    try {
      debugPrint('🔄 [CONTRIBUTION] Synchronisation paiements utilisateur $userId...');

      final allPaymentsResponse = await _dataSource.getAllPayments(userId: userId, page: 1);

      if (allPaymentsResponse.success) {
        _allPayments = allPaymentsResponse.data;
        _allPaymentsPagination = allPaymentsResponse.pagination;
        await ContributionLocalStorageService.saveAllPayments(userId, _allPayments);

        // Filtrage local
        _applyPaymentsLocalFilters();

        debugPrint('✅ [CONTRIBUTION] ${_allPayments.length} paiements synchronisés');
        debugPrint('   📊 Validés: ${_validatedPayments.length}, En attente: ${_pendingPayments.length}');
      }
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur synchronisation paiements: $e');
    }
  }

  // 🎯 FILTRAGE LOCAL DES PAIEMENTS (pattern intelligent)
  void _applyPaymentsLocalFilters() {
    // Filtrer les paiements validés
    _validatedPayments = _allPayments
        .where((payment) => payment.status.toUpperCase() == 'VALIDATED')
        .toList();

    // Filtrer les paiements en attente
    _pendingPayments = _allPayments
        .where((payment) => payment.status.toUpperCase() == 'PENDING')
        .toList();

    debugPrint('🔍 [CONTRIBUTION] Filtrage local: ${_validatedPayments.length} validés, ${_pendingPayments.length} en attente');
  }

  // Obtenir l'ID de l'utilisateur connecté depuis SecureStorage
  Future<String?> _getCurrentUserId() async {
    try {
      final userData = await SecureStorage.getUserData();
      if (userData != null) {
        final userJson = jsonDecode(userData);
        final user = UserModel.fromJson(userJson);
        return user.id;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur récupération userId: $e');
      return null;
    }
  }

  /// 🎯 MÉTHODE PRINCIPALE - Appelée quand on arrive sur la page
  /// 1. Charge d'abord depuis le cache pour affichage immédiat
  /// 2. Puis synchronise avec l'API via le checksum
  Future<void> loadContribution({String? userId}) async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    _isOffline = !_connectivityService.isConnected;

    try {
      // ÉTAPE 1: Charger depuis le cache pour affichage immédiat
      await _loadFromCache(userId);

      // ÉTAPE 2: Synchroniser avec l'API via le checksum (si connecté)
      if (!_isOffline) {
        await _syncWithChecksum(userId: userId);
      } else {
        debugPrint('📱 [CONTRIBUTION] Mode hors ligne - utilisation du cache uniquement');
        // Afficher notification hors ligne
        showOfflineNotification();
      }

      _setStatus(ContributionStatus.loaded);
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur loadContribution: $e');
      // Si on a des données locales, ne pas afficher d'erreur
      if (_contributionData != null) {
        _setStatus(ContributionStatus.loaded);
      } else {
        _setError(e.toString());
        _setStatus(ContributionStatus.error);
      }
    }
  }

  // Chargement depuis le cache pour affichage immédiat
  Future<void> _loadFromCache(String? userId) async {
    final cachedContribution = ContributionLocalStorageService.getContributionData();
    final cachedUnpaidMonths = ContributionLocalStorageService.getUnpaidMonths();

    // Charger les données de base du cache ou utiliser des données par défaut
    _contributionData = cachedContribution;
    _unpaidMonths = cachedUnpaidMonths ?? [];

    // Charger les paiements depuis le cache si userId fourni
    if (userId != null) {
      final cachedAllPayments = ContributionLocalStorageService.getAllPayments(userId);
      _allPayments = cachedAllPayments ?? [];

      // 🎯 FILTRAGE LOCAL depuis le cache (pattern intelligent)
      _applyPaymentsLocalFilters();
    }

    if (cachedContribution != null) {
      debugPrint('✅ [CONTRIBUTION] Données chargées depuis le cache (checksum: ${cachedContribution.checksum?.substring(0, 16) ?? 'null'}...)');
    } else {
      debugPrint('📱 [CONTRIBUTION] Pas de cache, données vides affichées');
    }

    // Notifier pour afficher les données du cache immédiatement
    notifyListeners();
  }


  /// 🎯 REFRESH - Force le rechargement complet depuis l'API
  Future<void> refreshContribution() async {
    _clearError();
    _isOffline = false;

    // Vérifier la connexion AVANT de commencer
    if (!_connectivityService.isConnected) {
      debugPrint('📱 [CONTRIBUTION] Refresh hors ligne - données locales conservées');
      _isOffline = true;
      // Ne pas changer le status, garder les données locales affichées
      notifyListeners();
      return;
    }

    _setStatus(ContributionStatus.loading);

    try {
      final userId = await _getCurrentUserId();

      // Rafraîchir les données de contribution et les mois impayés en parallèle
      final contributionFuture = _dataSource.getContribution();
      final unpaidMonthsFuture = _dataSource.getUnpaidMonths();

      final results = await Future.wait([
        contributionFuture,
        unpaidMonthsFuture,
      ]);

      final contributionResponse = results[0] as ContributionResponse;
      final unpaidMonthsResponse = results[1] as UnpaidMonthsResponse;

      if (contributionResponse.success) {
        _contributionData = contributionResponse.data;
        // Sauvegarder en cache avec le nouveau checksum
        await ContributionLocalStorageService.saveContributionData(_contributionData!);
        debugPrint('✅ [CONTRIBUTION] Refresh - Checksum: ${_contributionData!.checksum?.substring(0, 16) ?? 'null'}...');
      } else {
        _setError(contributionResponse.message);
        _setStatus(ContributionStatus.error);
        return;
      }

      if (unpaidMonthsResponse.success) {
        _unpaidMonths = unpaidMonthsResponse.data;
        await ContributionLocalStorageService.saveUnpaidMonths(_unpaidMonths);
      } else {
        // Ne pas faire échouer le refresh si les mois impayés échouent
        _unpaidMonths = [];
      }

      // Rafraîchir les paiements si userId disponible
      if (userId != null) {
        await _syncPaymentsData(userId);
      }

      _setStatus(ContributionStatus.loaded);
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur refresh: $e');
      // Si on a des données locales, ne pas afficher d'erreur
      if (_contributionData != null) {
        debugPrint('📱 [CONTRIBUTION] Données locales conservées malgré l\'erreur');
        _setStatus(ContributionStatus.loaded);
      } else {
        _setError(e.toString());
        _setStatus(ContributionStatus.error);
      }
    }
  }

  void _setStatus(ContributionStatus status) {
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

  // Charger plus de paiements validés (pagination)
  Future<void> loadMoreValidatedPayments(String userId) async {
    if (_validatedPagination?.hasNextPage != true) return;

    try {
      final nextPage = (_validatedPagination?.currentPage ?? 0) + 1;
      final response = await _dataSource.getValidatedPayments(
        userId: userId,
        page: nextPage,
      );

      if (response.success) {
        // TODO: Adapter pour PaymentItem
        // _validatedPayments.addAll(response.data);
        // _validatedPagination = response.pagination;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des paiements validés: $e');
    }
  }

  // Charger plus de paiements en attente (pagination)
  Future<void> loadMorePendingPayments(String userId) async {
    if (_pendingPagination?.hasNextPage != true) return;

    try {
      final nextPage = (_pendingPagination?.currentPage ?? 0) + 1;
      final response = await _dataSource.getPendingPayments(
        userId: userId,
        page: nextPage,
      );

      if (response.success) {
        // TODO: Adapter pour PaymentItem
        // _pendingPayments.addAll(response.data);
        // _pendingPagination = response.pagination;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des paiements en attente: $e');
    }
  }


  // Charger plus de paiements (pagination unifiée)
  Future<void> loadMoreAllPayments(String userId) async {
    if (_allPaymentsPagination?.hasNextPage != true) return;

    try {
      final nextPage = (_allPaymentsPagination?.currentPage ?? 0) + 1;
      final response = await _dataSource.getAllPayments(
        userId: userId,
        page: nextPage,
      );

      if (response.success) {
        _allPayments.addAll(response.data);
        _allPaymentsPagination = response.pagination;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de plus de paiements: $e');
    }
  }

  // Nouvelle méthode pour récupérer les périodes de paiement
  Future<PaymentPeriodsResponse> getPaymentPeriods() async {
    try {
      return await _dataSource.getPaymentPeriods();
    } catch (e) {
      debugPrint('Erreur lors du chargement des périodes: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour soumettre un paiement avec périodes
  Future<PaymentSubmissionResponse> submitPaymentWithPeriods(
    PaymentSubmissionRequest request,
  ) async {
    try {
      return await _dataSource.submitPaymentWithPeriods(request);
    } catch (e) {
      debugPrint('Erreur lors de la soumission du paiement: $e');
      rethrow;
    }
  }

  void clearData() {
    _contributionData = null;
    _unpaidMonths = [];
    _validatedPayments = [];
    _pendingPayments = [];
    _validatedPagination = null;
    _pendingPagination = null;
    _allPayments = [];
    _allPaymentsPagination = null;
    _errorMessage = null;
    _status = ContributionStatus.initial;
    notifyListeners();
  }

}
