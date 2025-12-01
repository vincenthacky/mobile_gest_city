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
import '../services/payment_sync_listener_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/storage/secure_storage.dart';
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

  // Subscription pour écouter les changements de Transaction sync
  StreamSubscription<bool>? _syncSubscription;

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

  // Initialise le controller et configure l'écoute de sync
  void initialize() {
    try {
      debugPrint('🎯 [CONTRIBUTION] Initialisation du controller - configuration écoute maître');
      debugPrint('🔧 [CONTRIBUTION] Configuration du listener...');
      _setupSyncListener();
      debugPrint('✅ [CONTRIBUTION] Listener configuré avec succès');
      
      debugPrint('🔧 [CONTRIBUTION] Initialisation du service local storage...');
      ContributionLocalStorageService.initialize();
      debugPrint('✅ [CONTRIBUTION] Service local storage initialisé');
      
      debugPrint('✅ [CONTRIBUTION] Initialisation complète terminée');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  // Configure l'écoute des changements de Transaction sync
  void _setupSyncListener() {
    try {
      debugPrint('🔗 [CONTRIBUTION] Création du listener PaymentSyncListenerService...');
      _syncSubscription = PaymentSyncListenerService.instance.paymentSyncTriggerStream.listen(
        (shouldSync) {
          debugPrint('📡 [CONTRIBUTION] Signal reçu du maître: shouldSync=$shouldSync');
          if (shouldSync) {
            debugPrint('🔄 [CONTRIBUTION] Synchronisation déclenchée par Transaction sync');
            _syncContributionData();
          }
        },
        onError: (error) {
          debugPrint('❌ [CONTRIBUTION] Erreur dans le listener: $error');
        },
      );
      debugPrint('✅ [CONTRIBUTION] Listener PaymentSyncListenerService créé avec succès');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur création listener: $e');
      rethrow;
    }
  }

  // Synchronisation des données de cotisation (déclenchée par Transaction sync)
  Future<void> _syncContributionData() async {
    if (!_connectivityService.isConnected) {
      debugPrint('📱 [CONTRIBUTION] Pas de connexion, pas de sync');
      return;
    }

    try {
      debugPrint('🔄 [CONTRIBUTION] Début synchronisation...');
      
      // Synchroniser les données de contribution
      final contributionResponse = await _dataSource.getContribution();
      if (contributionResponse.success) {
        _contributionData = contributionResponse.data;
        await ContributionLocalStorageService.saveContributionData(_contributionData!);
        debugPrint('✅ [CONTRIBUTION] Données contribution synchronisées');
      }

      // Synchroniser les mois impayés
      final unpaidMonthsResponse = await _dataSource.getUnpaidMonths();
      if (unpaidMonthsResponse.success) {
        _unpaidMonths = unpaidMonthsResponse.data;
        await ContributionLocalStorageService.saveUnpaidMonths(_unpaidMonths);
        debugPrint('✅ [CONTRIBUTION] Mois impayés synchronisés');
      }

      // 🎯 SYNCHRONISATION INTELLIGENTE DES PAIEMENTS (comme les autres modules fils)
      debugPrint('🚀 [CONTRIBUTION] Appel de _syncPaymentsData()...');
      await _syncPaymentsData();
      debugPrint('✅ [CONTRIBUTION] _syncPaymentsData() terminée');

      notifyListeners();
      debugPrint('✅ [CONTRIBUTION] Synchronisation terminée');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur synchronisation: $e');
    }
  }

  // 🎯 SYNCHRONISATION INTELLIGENTE DES PAIEMENTS (pattern fils dépendant du maître)
  Future<void> _syncPaymentsData() async {
    try {
      // Obtenir l'utilisateur connecté
      final userId = await _getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [CONTRIBUTION] Pas d\'utilisateur connecté pour sync paiements');
        return;
      }

      debugPrint('🔄 [CONTRIBUTION] Synchronisation paiements utilisateur $userId...');
      
      // 🎯 UNE SEULE API CALL - getAllPayments (synchronisation intelligente)
      final allPaymentsResponse = await _dataSource.getAllPayments(userId: userId, page: 1);
      
      if (allPaymentsResponse.success) {
        // Sauvegarder TOUS les paiements en cache local
        _allPayments = allPaymentsResponse.data;
        _allPaymentsPagination = allPaymentsResponse.pagination;
        await ContributionLocalStorageService.saveAllPayments(userId, _allPayments);
        
        // 🎯 FILTRAGE LOCAL (comme WhatsApp) - pas d'API séparées
        _applyPaymentsLocalFilters();
        
        debugPrint('✅ [CONTRIBUTION] ${_allPayments.length} paiements synchronisés et filtrés localement');
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

  Future<void> loadContribution({String? userId}) async {
    _setStatus(ContributionStatus.loading);
    _clearError();

    try {
      // TOUJOURS charger depuis le cache (affichage uniquement)
      await _loadFromCache(userId);
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
    }
  }


  // Chargement depuis le cache SEULEMENT
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
    
    _setStatus(ContributionStatus.loaded);
    
    if (cachedContribution != null) {
      debugPrint('✅ [CONTRIBUTION] Données chargées depuis le cache');
    } else {
      debugPrint('📱 [CONTRIBUTION] Pas de cache, données vides affichées');
    }
  }


  Future<void> refreshContribution() async {
    _setStatus(ContributionStatus.loading);
    _clearError();

    try {
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
      } else {
        _setError(contributionResponse.message);
        _setStatus(ContributionStatus.error);
        return;
      }

      if (unpaidMonthsResponse.success) {
        _unpaidMonths = unpaidMonthsResponse.data;
      } else {
        // Ne pas faire échouer le refresh si les mois impayés échouent
        _unpaidMonths = [];
      }

      _setStatus(ContributionStatus.loaded);
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
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

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}
