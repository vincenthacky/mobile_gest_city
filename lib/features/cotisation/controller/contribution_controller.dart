import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';
import '../models/unpaid_months_model.dart';
import '../models/payment_proofs_model.dart';

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
  String? _errorMessage;

  ContributionStatus get status => _status;
  ContributionData? get contributionData => _contributionData;
  List<UnpaidMonth> get unpaidMonths => _unpaidMonths;
  List<PaymentProof> get validatedPayments => _validatedPayments;
  List<PaymentProof> get pendingPayments => _pendingPayments;
  PaginationInfo? get validatedPagination => _validatedPagination;
  PaginationInfo? get pendingPagination => _pendingPagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ContributionStatus.loading;
  bool get hasData => _contributionData != null;

  Future<void> loadContribution({int? userId}) async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      // Charger les données de contribution et les mois impayés en parallèle
      final contributionFuture = _dataSource.getContribution();
      final unpaidMonthsFuture = _dataSource.getUnpaidMonths();
      
      List<Future> futures = [contributionFuture, unpaidMonthsFuture];
      
      // Si userId est fourni, charger aussi les paiements validés et en attente
      if (userId != null) {
        futures.add(_dataSource.getValidatedPayments(userId: userId));
        futures.add(_dataSource.getPendingPayments(userId: userId));
      }
      
      final results = await Future.wait(futures);
      
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
        // Ne pas faire échouer le chargement si les mois impayés échouent
        _unpaidMonths = [];
      }
      
      // Charger les paiements si userId fourni
      if (userId != null && results.length > 2) {
        final validatedResponse = results[2] as PaymentProofsResponse;
        final pendingResponse = results[3] as PaymentProofsResponse;
        
        if (validatedResponse.success) {
          _validatedPayments = validatedResponse.data;
          _validatedPagination = validatedResponse.pagination;
        }
        
        if (pendingResponse.success) {
          _pendingPayments = pendingResponse.data;
          _pendingPagination = pendingResponse.pagination;
        }
      }
      
      _setStatus(ContributionStatus.loaded);
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
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
  Future<void> loadMoreValidatedPayments(int userId) async {
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

  void clearData() {
    _contributionData = null;
    _unpaidMonths = [];
    _validatedPayments = [];
    _pendingPayments = [];
    _validatedPagination = null;
    _pendingPagination = null;
    _errorMessage = null;
    _status = ContributionStatus.initial;
    notifyListeners();
  }
}