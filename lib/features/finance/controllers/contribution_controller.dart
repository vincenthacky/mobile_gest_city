import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';
import '../models/unpaid_months_model.dart';
import '../models/payment_proofs_model.dart';
import '../models/payment_list_model.dart';
import '../models/payment_periods_model.dart';

enum ContributionStatus { initial, loading, loaded, error }

class ContributionController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  
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

  Future<void> loadContribution({int? userId}) async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      // Charger d'abord les données de contribution (prioritaire)
      final contributionResponse = await _dataSource.getContribution();
      
      if (contributionResponse.success) {
        _contributionData = contributionResponse.data;
        _setStatus(ContributionStatus.loaded);
      } else {
        _setError(contributionResponse.message);
        _setStatus(ContributionStatus.error);
        return;
      }
      
      // Charger les autres données en arrière-plan sans bloquer l'affichage
      _loadAdditionalData(userId);
      
      // Charger la nouvelle liste unifiée des paiements
      if (userId != null) {
        _loadAllPayments(userId);
      }
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
    }
  }

  Future<void> _loadAdditionalData(int? userId) async {
    try {
      // Charger les mois impayés
      try {
        final unpaidMonthsResponse = await _dataSource.getUnpaidMonths();
        if (unpaidMonthsResponse.success) {
          _unpaidMonths = unpaidMonthsResponse.data;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement des mois impayés: $e');
        _unpaidMonths = [];
      }
      
      // Charger les paiements si userId fourni
      if (userId != null) {
        try {
          final validatedResponse = await _dataSource.getValidatedPayments(userId: userId);
          if (validatedResponse.success) {
            _validatedPayments = validatedResponse.data;
            _validatedPagination = validatedResponse.pagination;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Erreur lors du chargement des paiements validés: $e');
          _validatedPayments = [];
        }
        
        try {
          final pendingResponse = await _dataSource.getPendingPayments(userId: userId);
          if (pendingResponse.success) {
            _pendingPayments = pendingResponse.data;
            _pendingPagination = pendingResponse.pagination;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Erreur lors du chargement des paiements en attente: $e');
          _pendingPayments = [];
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données additionnelles: $e');
    }
  }

  Future<void> refreshContribution() async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      // Rafraîchir les données de contribution et les mois impayés en parallèle
      final contributionFuture = _dataSource.getContribution();
      final unpaidMonthsFuture = _dataSource.getUnpaidMonths();
      
      final results = await Future.wait([contributionFuture, unpaidMonthsFuture]);
      
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
  Future<void> loadMorePendingPayments(int userId) async {
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

  // Charger tous les paiements (nouvelle approche)
  Future<void> _loadAllPayments(int userId) async {
    try {
      final response = await _dataSource.getAllPayments(userId: userId);
      if (response.success) {
        _allPayments = response.data;
        _allPaymentsPagination = response.pagination;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de tous les paiements: $e');
      debugPrint('Détail de l\'erreur: $e');
      _allPayments = [];
    }
  }

  // Charger plus de paiements (pagination unifiée)
  Future<void> loadMoreAllPayments(int userId) async {
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
  Future<PaymentSubmissionResponse> submitPaymentWithPeriods(PaymentSubmissionRequest request) async {
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