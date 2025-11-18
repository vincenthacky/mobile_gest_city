import 'package:flutter/material.dart';
import 'dart:async';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';
import '../models/unpaid_months_model.dart';
import '../models/payment_proofs_model.dart';
import '../models/payment_list_model.dart';
import '../models/payment_periods_model.dart';
import '../services/contribution_local_storage_service.dart';
import '../services/payment_sync_listener_service.dart';
import '../../../core/services/connectivity_service.dart';

enum ContributionStatus { initial, loading, loaded, error }

class ContributionController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();

  ContributionStatus _status = ContributionStatus.initial;
  ContributionData? _contributionData;
  List<UnpaidMonth> _unpaidMonths = [];
  List<PaymentProof> _validatedPayments = [];
  List<PaymentProof> _pendingPayments = [];
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
  List<PaymentProof> get validatedPayments => _validatedPayments;
  List<PaymentProof> get pendingPayments => _pendingPayments;
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
    _setupSyncListener();
    ContributionLocalStorageService.initialize();
  }

  // Configure l'écoute des changements de Transaction sync
  void _setupSyncListener() {
    _syncSubscription = PaymentSyncListenerService.instance.paymentSyncTriggerStream.listen(
      (shouldSync) {
        if (shouldSync) {
          debugPrint('🔄 [CONTRIBUTION] Synchronisation déclenchée par Transaction sync');
          _syncContributionData();
        }
      },
    );
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

      notifyListeners();
      debugPrint('✅ [CONTRIBUTION] Synchronisation terminée');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION] Erreur synchronisation: $e');
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
      final cachedValidated = ContributionLocalStorageService.getPaymentProofs(userId, 'validated');
      final cachedPending = ContributionLocalStorageService.getPaymentProofs(userId, 'pending');
      final cachedAllPayments = ContributionLocalStorageService.getAllPayments(userId);
      
      _validatedPayments = cachedValidated ?? [];
      _pendingPayments = cachedPending ?? [];
      _allPayments = cachedAllPayments ?? [];
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
        _validatedPayments.addAll(response.data);
        _validatedPagination = response.pagination;
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
        _pendingPayments.addAll(response.data);
        _pendingPagination = response.pagination;
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
