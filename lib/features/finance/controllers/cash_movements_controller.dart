import 'package:flutter/material.dart';
import '../data_source/cash_movements_data_source.dart';
import '../data_source/cash_totals_data_source.dart';
import '../models/cash_movement_model.dart';
import '../models/cash_movements_response_model.dart';
import '../models/cash_totals_model.dart';

enum CashMovementsStatus { initial, loading, loaded, error }

class CashMovementsController extends ChangeNotifier {
  final CashMovementsDataSource _dataSource = CashMovementsDataSource();
  final CashTotalsDataSource _totalsDataSource = CashTotalsDataSource();
  
  CashMovementsStatus _status = CashMovementsStatus.initial;
  List<CashMovement> _cashMovements = [];
  CashTotals? _cashTotals;
  Pagination? _pagination;
  String? _errorMessage;

  CashMovementsStatus get status => _status;
  List<CashMovement> get cashMovements => _cashMovements;
  CashTotals? get cashTotals => _cashTotals;
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
    _cashTotals = null;
    _pagination = null;
    _errorMessage = null;
    _status = CashMovementsStatus.initial;
    notifyListeners();
  }

  Future<void> loadCashTotals() async {
    try {
      final response = await _totalsDataSource.getCashTotals();
      if (response.success) {
        _cashTotals = response.data.totals;
        debugPrint('Totaux chargés avec succès: Recettes=${_cashTotals!.totalReceipts}, Dépenses=${_cashTotals!.totalExpenses}, Solde=${_cashTotals!.balance}');
        notifyListeners();
      } else {
        debugPrint('Erreur lors du chargement des totaux: ${response.message}');
        _setError('Erreur lors du chargement des totaux: ${response.message}');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des totaux: $e');
      _setError('Erreur lors du chargement des totaux: $e');
    }
  }

  // Getters pour les totaux
  double get totalRecettes {
    final value = _cashTotals?.totalReceipts.toDouble() ?? 0.0;
    debugPrint('Getter totalRecettes: $_cashTotals -> $value');
    return value;
  }
  
  double get totalDepenses {
    final value = _cashTotals?.totalExpenses.toDouble() ?? 0.0;
    debugPrint('Getter totalDepenses: $_cashTotals -> $value');
    return value;
  }
  
  double get soldeActuel {
    final value = _cashTotals?.balance.toDouble() ?? 0.0;
    debugPrint('Getter soldeActuel: $_cashTotals -> $value');
    return value;
  }

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