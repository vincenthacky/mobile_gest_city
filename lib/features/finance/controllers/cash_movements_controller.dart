import 'package:flutter/material.dart';
import '../data_source/cash_movements_data_source.dart';
import '../models/cash_movement_model.dart';
import '../models/cash_movements_response_model.dart';

enum CashMovementsStatus { initial, loading, loaded, error }

class CashMovementsController extends ChangeNotifier {
  final CashMovementsDataSource _dataSource = CashMovementsDataSource();
  
  CashMovementsStatus _status = CashMovementsStatus.initial;
  List<CashMovement> _cashMovements = [];
  Totals? _totals;
  Pagination? _pagination;
  String? _errorMessage;

  CashMovementsStatus get status => _status;
  List<CashMovement> get cashMovements => _cashMovements;
  Totals? get totals => _totals;
  Pagination? get pagination => _pagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CashMovementsStatus.loading;
  bool get hasData => _cashMovements.isNotEmpty;

  Future<void> loadCashMovements({
    String? filter,
    int page = 1,
    int perPage = 15,
  }) async {
    _setStatus(CashMovementsStatus.loading);
    _clearError();
    
    try {
      final response = await _dataSource.getCashMovements(
        filter: filter,
        page: page,
        perPage: perPage,
      );
      
      if (response.success) {
        _cashMovements = response.data.cashMovements;
        _totals = response.data.totals;
        _pagination = response.pagination;
        _setStatus(CashMovementsStatus.loaded);
      } else {
        _setError(response.message);
        _setStatus(CashMovementsStatus.error);
      }
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(CashMovementsStatus.error);
    }
  }

  Future<void> refreshCashMovements({String? filter}) async {
    await loadCashMovements(filter: filter);
  }

  Future<void> loadMoreCashMovements({String? filter}) async {
    if (_pagination?.currentPage != null && 
        _pagination!.currentPage < _pagination!.lastPage) {
      
      try {
        final nextPage = _pagination!.currentPage + 1;
        final response = await _dataSource.getCashMovements(
          filter: filter,
          page: nextPage,
        );
        
        if (response.success) {
          _cashMovements.addAll(response.data.cashMovements);
          _pagination = response.pagination;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement de plus de mouvements: $e');
      }
    }
  }

  void _setStatus(CashMovementsStatus status) {
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
    _cashMovements = [];
    _totals = null;
    _pagination = null;
    _errorMessage = null;
    _status = CashMovementsStatus.initial;
    notifyListeners();
  }

  // Getters pour les totaux
  double get totalRecettes => _totals?.totalReceipts.toDouble() ?? 0.0;
  double get totalDepenses => _totals?.totalExpenses.toDouble() ?? 0.0;
  double get soldeActuel => _totals?.balance.toDouble() ?? 0.0;

  // Filtres
  List<CashMovement> getFilteredMovements({
    String? typeFilter,
    DateTimeRange? dateRange,
  }) {
    List<CashMovement> filtered = List.from(_cashMovements);

    // Filtre par type
    if (typeFilter == 'Recettes') {
      filtered = filtered.where((t) => t.isCredit).toList();
    } else if (typeFilter == 'Dépenses') {
      filtered = filtered.where((t) => t.isDebit).toList();
    }

    // Filtre par date
    if (dateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }
}